import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_event_engine.dart';
import '../core/services/petpal_backend.dart';
import '../core/services/petpal_remote_api.dart';
import '../shared/models/chat_message.dart';
import '../shared/models/pet_activity.dart';
import '../shared/models/pet_profile.dart';
import '../shared/models/petpal_v12_models.dart';
import '../shared/models/preset_role.dart';
import '../shared/repositories/mock_pet_repository.dart';
import '../shared/repositories/petpal_v12_seed_repository.dart';

class PetPalController extends ChangeNotifier {
  PetPalController({
    MockPetRepository repository = const MockPetRepository(),
    PetPalV12SeedRepository seedRepository = const PetPalV12SeedRepository(),
    OfflineEventEngine? offlineEventEngine,
    PetPalRemoteApi? remoteApi,
  })  : _repository = repository,
        _seedRepository = seedRepository,
        _offlineEventEngine = offlineEventEngine ?? OfflineEventEngine(),
        _remoteApi = remoteApi {
    roles = _repository.presetRoles();
  }

  static const _petStorageKey = 'petpal.current_pet.v1';
  static const _messagesStorageKey = 'petpal.messages.v1';
  static const _momentsStorageKey = 'petpal.moments.v1';
  static const _momentAssetsStorageKey = 'petpal.moment_assets.v1';
  static const _pendingMomentEventsStorageKey =
      'petpal.pending_moment_events.v1';
  static const _offlineEventHistoryStorageKey =
      'petpal.offline_event_history.v1';
  static const _maxStoredMessages = 200;
  static const _maxOfflineEventHistory = 200;
  static const _replyTimeout = Duration(seconds: 20);

  final MockPetRepository _repository;
  final PetPalV12SeedRepository _seedRepository;
  final OfflineEventEngine _offlineEventEngine;
  final PetPalRemoteApi? _remoteApi;

  late final List<PresetRole> roles;
  int? selectedAvatarVariant;
  String? selectedAvatarUrl;
  PresetRole? selectedRole;
  PetProfile? currentPet;
  String? selectedUploadPhotoPath;
  String latestBubble = 'I missed you. Want to play?';
  bool chatMode = false;
  bool chatBusy = false;
  bool isReady = false;
  String? roomNotice;
  OfflineEventOccurrence? pendingAwayEvent;
  bool awayEventSaving = false;

  /// Full conversation history, shared by the main-screen dialogue overlay and
  /// the chat history window (spec 3.3 / 3.4). Oldest first.
  final List<ChatMessage> messages = [];
  final List<UserMomentRecord> userMoments = [];
  final List<MomentAsset> momentAssets = [];
  final List<PendingMomentEvent> pendingMomentEvents = [];
  final List<OfflineEventHistory> offlineEventHistory = [];

  /// True while the pet is composing a reply — drives the "thinking" bubble.
  bool petThinking = false;

  /// The most recent pet message that should animate in with a typewriter
  /// effect (spec 3.3 "逐字 / 流式显示"). Cleared once the reveal completes.
  String? streamingMessageId;

  /// Transient one-line hint shown when a memory is written (spec 3.3 / 3.4).
  String? memoryHint;

  /// Pending user messages awaiting a reply, processed one at a time so rapid
  /// consecutive sends queue in order instead of interleaving (spec 3.3).
  final List<ChatMessage> _pending = [];
  bool _processingQueue = false;
  Timer? _noticeTimer;
  String? _lastValidChatText;
  DateTime? _lastValidChatAt;
  bool _processingMomentImages = false;

  List<RoomItemConfig> get roomItems {
    final pet = currentPet;
    final items = _seedRepository.roomItems()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    if (pet == null) return items.where((item) => item.enabled).toList();
    return items
        .where(
            (item) => item.enabled && !item.archived && item.supportsPet(pet))
        .toList();
  }

  List<RoomItemConfig> get placedRoomItems {
    final pet = currentPet;
    if (pet == null) return const [];
    final byId = {for (final item in roomItems) item.itemId: item};
    return pet.placedItemIds
        .map((id) => byId[id])
        .whereType<RoomItemConfig>()
        .toList();
  }

  List<UserMomentRecord> visibleMoments(
      {MomentFilter filter = MomentFilter.all}) {
    final moments = userMoments.where((record) => !record.isDeleted).where(
      (record) {
        switch (filter) {
          case MomentFilter.home:
            return record.momentTypeSnapshot == 'home' ||
                record.momentTypeSnapshot == 'dream';
          case MomentFilter.special:
            return record.momentTypeSnapshot == 'special';
          case MomentFilter.all:
            return true;
        }
      },
    ).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return moments;
  }

  String get feedCooldownLabel {
    final pet = currentPet;
    if (pet == null) return '';
    final remaining = pet.feedRemainingCooldown(DateTime.now());
    if (remaining == Duration.zero) return '';
    return _formatCooldown(remaining);
  }

  String get caressCooldownLabel {
    final pet = currentPet;
    if (pet == null) return '';
    final remaining = pet.caressRemainingCooldown(DateTime.now());
    if (remaining == Duration.zero) return '';
    return _formatCooldown(remaining);
  }

  /// The most recent pet line, used by the speech bubble above the pet.
  ChatMessage? get lastPetMessage {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isPet) return messages[i];
    }
    return null;
  }

  /// The most recent user line, shown as a translucent bubble above the input.
  ChatMessage? get lastUserMessage {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isUser) return messages[i];
    }
    return null;
  }

  /// When the user last did anything with the pet. The stage uses this to
  /// decide when the pet may nap (autonomous, 旅行青蛙-style).
  DateTime lastInteractionAt = DateTime.now();

  /// A one-shot activity the stage should play in response to a button action
  /// (Feed/Clean/Pet). Observed via [actionRequestSeq]; the stage compares the
  /// sequence number so it only fires once per request.
  PetActivity requestedActivity = PetActivity.idle;
  int actionRequestSeq = 0;

  void markInteraction() {
    lastInteractionAt = DateTime.now();
  }

  void _requestActivity(PetActivity activity) {
    requestedActivity = activity;
    actionRequestSeq++;
  }

  static const allTraits = [
    'Lazy',
    'Affectionate',
    'Sassy',
    'Chatty',
    'Playful',
    'Foodie',
    'Cool',
    'Gentle',
    'Curious',
    'Shy',
    'Quiet',
    'Sweet',
  ];

  PresetRole uploadedPlaceholder(int variant) {
    return _repository.uploadedPlaceholder(variant);
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _restoreMessages(prefs);
    _restoreMoments(prefs);
    _restoreMomentAssets(prefs);
    _restorePendingMomentEvents(prefs);
    _restoreOfflineEventHistory(prefs);
    final rawPet = prefs.getString(_petStorageKey);
    if (rawPet != null) {
      final json = jsonDecode(rawPet) as Map<String, dynamic>;
      final variant = json['avatarVariant'] as int? ?? 0;
      final role = _roleForStoredPet(json, variant);
      currentPet = PetProfile.fromJson(json, role: role);
      if (currentPet?.sourceType == PetSourceType.presetRole) {
        selectedRole = role;
      } else {
        selectedAvatarVariant = variant;
        selectedUploadPhotoPath = currentPet?.sourcePhotoPath;
      }
      handleRoomEntry();
      await _saveCurrentPet();
      if (currentPet != null) {
        unawaited(_syncPetStatus(currentPet!));
      }
    }
    isReady = true;
    notifyListeners();
  }

  void handleRoomEntry({DateTime? now}) {
    final pet = currentPet;
    if (pet == null) return;
    final currentTime = now ?? DateTime.now();
    _dailyResetIfNeeded(pet, currentTime);
    final offlineDuration = _settleOfflineState(pet, currentTime);
    final leveledUp = _awardDailyReturnAffinity(pet);
    _refreshStatusText(pet);
    pendingAwayEvent =
        _readyPendingMomentOccurrenceIfNeeded(pet, currentTime) ??
            _createOfflineEventIfNeeded(pet, offlineDuration, currentTime);
    latestBubble =
        pendingAwayEvent?.body ?? _welcomeBackBubble(offlineDuration);
    _touch(pet, now: currentTime);
    unawaited(_saveCurrentPet());
    if (pendingAwayEvent == null) unawaited(_processPendingMomentImages());
    if (leveledUp) _showAffinityLevelNotice(pet);
    notifyListeners();
  }

  void onAppResumed() {
    handleRoomEntry();
    final pet = currentPet;
    if (pet != null) unawaited(_syncPetStatus(pet));
  }

  void selectGeneratedAvatar(
    int variant, {
    String? remoteImageUrl,
    String? sourcePhotoPath,
  }) {
    selectedAvatarVariant = variant;
    selectedAvatarUrl = remoteImageUrl;
    if (sourcePhotoPath != null) {
      selectedUploadPhotoPath = sourcePhotoPath;
    }
    notifyListeners();
  }

  void clearGeneratedAvatarSelection() {
    selectedAvatarVariant = null;
    selectedAvatarUrl = null;
    notifyListeners();
  }

  void setUploadPhotoPath(String path) {
    selectedUploadPhotoPath = path;
    notifyListeners();
  }

  void selectRole(PresetRole role) {
    selectedRole = role;
    notifyListeners();
  }

  void createUploadedPet({
    required String name,
    required List<String> traits,
    String specialPersonalityDetail = '',
  }) {
    final variant = selectedAvatarVariant ?? 0;
    currentPet = PetProfile(
      name: name.trim().isEmpty ? 'Mochi' : name.trim(),
      sourceType: PetSourceType.uploadedPhoto,
      traits: traits,
      role: uploadedPlaceholder(variant),
      specialPersonalityDetail: specialPersonalityDetail.trim(),
      sourcePhotoPath: selectedUploadPhotoPath,
      avatarUrl: selectedAvatarUrl,
      avatarVariant: variant,
      generationStatus: 'generating',
      statusText: 'Generating final avatar',
    );
    _dailyResetIfNeeded(currentPet!, DateTime.now());
    latestBubble = 'What should we do first?';
    _saveCurrentPet();
    unawaited(_syncCurrentPet());
    notifyListeners();
  }

  void createPresetPet({
    required String name,
    required List<String> traits,
    String specialPersonalityDetail = '',
  }) {
    final role = selectedRole ?? roles.first;
    currentPet = PetProfile(
      name: name.trim().isEmpty ? role.name : name.trim(),
      sourceType: PetSourceType.presetRole,
      traits: traits.isEmpty ? role.defaultTraits : traits,
      role: role,
      specialPersonalityDetail: specialPersonalityDetail.trim(),
      generationStatus: 'none',
    );
    _refreshStatusText(currentPet!);
    _dailyResetIfNeeded(currentPet!, DateTime.now());
    latestBubble = 'I am home!';
    _saveCurrentPet();
    unawaited(_syncCurrentPet());
    notifyListeners();
  }

  void updateName(String name) {
    final pet = currentPet;
    if (pet == null) return;
    pet.name = name.trim().isEmpty ? pet.name : name.trim();
    _touch(pet);
    _refreshStatusText(pet);
    _saveCurrentPet();
    unawaited(_syncCurrentPet());
    notifyListeners();
  }

  void feed() {
    final pet = currentPet;
    if (pet == null) return;
    final now = DateTime.now();
    _dailyResetIfNeeded(pet, now);
    markInteraction();
    _requestActivity(PetActivity.eating);

    String line;
    if (pet.feedEffectiveCountToday >= 5) {
      line = '${pet.name} has eaten plenty today.';
    } else if (pet.isFeedInCooldown(now)) {
      line = '${pet.name} is still full right now.';
    } else {
      final previousHunger = pet.hunger;
      final previousLevel = pet.affinityLevel;
      pet.hunger = (pet.hunger + 35).clamp(0, 100).toInt();
      pet.mood = (pet.mood + 3).clamp(0, 100).toInt();
      pet.feedLastAt = now;
      pet.feedEffectiveCountToday += 1;
      final leveledUp = _awardFeedAffinity(pet, previousLevel);
      line = _feedLine(pet, previousHunger: previousHunger);
      if (leveledUp) _showAffinityLevelNotice(pet);
    }

    _touch(pet, now: now);
    _refreshStatusText(pet);
    _addActionLine(line);
    unawaited(_syncPetStatus(pet));
  }

  void clean() {
    final pet = currentPet;
    if (pet == null) return;
    final now = DateTime.now();
    _dailyResetIfNeeded(pet, now);
    pet.cleanliness = (pet.cleanliness + 10).clamp(0, 100).toInt();
    pet.statusText = 'Fresh and shiny';
    _touch(pet, now: now);
    markInteraction();
    _requestActivity(PetActivity.happy);
    _addActionLine(_cleanLine(pet));
    unawaited(_syncPetStatus(pet));
  }

  void caress() {
    final pet = currentPet;
    if (pet == null) return;
    final now = DateTime.now();
    _dailyResetIfNeeded(pet, now);
    markInteraction();
    _requestActivity(PetActivity.happy);

    String line;
    if (pet.caressEffectiveCountToday >= 8) {
      line = '${pet.name} has felt lots of love today.';
    } else if (pet.isCaressInCooldown(now)) {
      line = '${pet.name} already feels loved.';
    } else {
      final previousMood = pet.mood;
      final previousLevel = pet.affinityLevel;
      pet.mood = (pet.mood + 12).clamp(0, 100).toInt();
      pet.caressLastAt = now;
      pet.caressEffectiveCountToday += 1;
      final leveledUp = _awardCaressAffinity(pet, previousLevel);
      line = _caressLine(pet, previousMood: previousMood);
      if (leveledUp) _showAffinityLevelNotice(pet);
    }

    _touch(pet, now: now);
    _refreshStatusText(pet);
    _addActionLine(line);
    unawaited(_syncPetStatus(pet));
  }

  /// Tapping the pet body: a free idle reaction that costs no stats and is not
  /// recorded in history — it exists purely to make the pet feel alive
  /// (spec 3.5 "点击宠物本体").
  void pokePet() {
    caress();
  }

  bool toggleRoomItem(RoomItemConfig item) {
    final pet = currentPet;
    if (pet == null) return false;
    if (!item.isUnlocked(pet)) {
      _showRoomNotice(
        'Reach Affinity Lv.${item.unlockAffinityLevel} to unlock ${item.itemName}.',
      );
      return false;
    }
    final placed = pet.placedItemIds;
    if (placed.contains(item.itemId)) {
      placed.remove(item.itemId);
    } else {
      if (placed.length >= 3) {
        _showRoomNotice('You can place up to 3 items for now.');
        return false;
      }
      placed.add(item.itemId);
    }
    pet.lastRoomItemUpdateAt = DateTime.now();
    _touch(pet, now: pet.lastRoomItemUpdateAt);
    _saveCurrentPet();
    unawaited(_syncPetStatus(pet));
    notifyListeners();
    return true;
  }

  void dismissAwayEvent() {
    if (pendingAwayEvent == null) return;
    pendingAwayEvent = null;
    awayEventSaving = false;
    notifyListeners();
  }

  Future<UserMomentRecord?> savePendingMoment() async {
    final occurrence = pendingAwayEvent;
    final pet = currentPet;
    final moment = occurrence?.moment;
    if (occurrence == null || pet == null || moment == null) return null;
    if (!occurrence.canSaveMoment || _hasActiveMoment(moment.momentId)) {
      dismissAwayEvent();
      return null;
    }

    awayEventSaving = true;
    notifyListeners();
    final now = DateTime.now();
    final record = UserMomentRecord(
      momentRecordId: _localId('moment'),
      momentId: moment.momentId,
      petId: _petRecordId(pet),
      sourceEventId: occurrence.config.eventId,
      titleSnapshot: _fillTemplate(moment.title, pet, occurrence.config),
      diaryTextSnapshot:
          _fillTemplate(moment.diaryTemplate, pet, occurrence.config),
      imageUrlSnapshot: occurrence.imageUrl ??
          moment.imageUrl ??
          moment.defaultImageUrl ??
          '',
      momentTypeSnapshot: moment.momentType,
      createdAt: now,
    );

    userMoments.add(record);
    occurrence.history
      ..momentSaved = true
      ..momentRecordId = record.momentRecordId;
    await _saveMoments();
    await _saveOfflineEventHistory();
    if (PetPalBackend.isEnabled) {
      unawaited(_syncMomentRecord(record, occurrence.history));
    }
    pendingAwayEvent = null;
    awayEventSaving = false;
    notifyListeners();
    return record;
  }

  Future<void> deleteMoment(UserMomentRecord record) async {
    if (record.isDeleted) return;
    record.deletedAt = DateTime.now();
    await _saveMoments();
    if (PetPalBackend.isEnabled) {
      unawaited(_deleteRemoteMoment(record));
    }
    notifyListeners();
  }

  /// Adds a pet line triggered by an interaction button so it shows in the
  /// dialogue overlay and enters the chat record (spec 3.5).
  void _addActionLine(String line) {
    final petMsg = ChatMessage.pet(line);
    messages.add(petMsg);
    streamingMessageId = petMsg.id;
    latestBubble = line;
    _trimAndSaveMessages();
    _saveCurrentPet();
    notifyListeners();
  }

  String _feedLine(PetProfile pet, {required int previousHunger}) {
    if (previousHunger < 50) {
      return '${pet.name} looks much better after eating.';
    }
    if (pet.hunger >= 80) {
      return '${pet.name} is full and cozy now.';
    }
    if (previousHunger >= 0) {
      return '${pet.name} happily finished the food.';
    }
    if (pet.traits.contains('Sassy')) return 'Hmph. Acceptable. More?';
    if (pet.traits.contains('Foodie')) return 'YUM!! Best meal ever, encore!';
    if (pet.traits.contains('Affectionate')) {
      return 'Thank you, I love eating with you 💛';
    }
    return 'That was delicious. Thank you!';
  }

  String _cleanLine(PetProfile pet) {
    if (pet.traits.contains('Sassy')) return 'Fine, I do look better now.';
    if (pet.traits.contains('Playful')) return 'Splish splash! So shiny now!';
    return 'I feel sparkly now.';
  }

  String _caressLine(PetProfile pet, {required int previousMood}) {
    if (previousMood < 60) {
      return '${pet.name} seems to feel a little better.';
    }
    if (pet.mood >= 80) {
      return '${pet.name} looks really happy.';
    }
    if (previousMood >= 0) {
      return '${pet.name} leaned closer to your hand.';
    }
    if (pet.traits.contains('Sassy')) return 'Hmph… just this once, okay?';
    if (pet.traits.contains('Shy')) return '*leans in a little* …that\'s nice.';
    if (pet.traits.contains('Affectionate')) {
      return 'That made my whole day 💛';
    }
    return 'That made my whole day.';
  }

  void toggleChatMode() {
    chatMode = !chatMode;
    notifyListeners();
  }

  /// Queues a user message for delivery. The message appears on screen
  /// immediately (right-aligned, "sending"); the reply is produced by the
  /// queue worker so rapid sends are answered in order (spec 3.3).
  Future<void> sendMessage(String message) async {
    final text = message.trim();
    if (text.isEmpty) return;
    final pet = currentPet;
    if (pet != null) _dailyResetIfNeeded(pet, DateTime.now());
    markInteraction();
    final userMsg = ChatMessage.user(text);
    messages.add(userMsg);
    _pending.add(userMsg);
    _trimAndSaveMessages();
    notifyListeners();
    await _drainQueue();
  }

  /// Re-sends a message that previously failed to deliver (spec 3.3 — a failed
  /// message is kept on screen with "tap to retry"; it is never dropped).
  Future<void> retryMessage(ChatMessage message) async {
    if (message.role != ChatRole.user) return;
    if (message.status != ChatStatus.failed) return;
    if (_pending.contains(message)) return;
    message.status = ChatStatus.sending;
    _pending.add(message);
    _trimAndSaveMessages();
    notifyListeners();
    await _drainQueue();
  }

  /// Marks the pet's streaming reply as fully revealed (called by the UI once
  /// the typewriter animation finishes).
  void markStreamed(String messageId) {
    if (streamingMessageId == messageId) {
      streamingMessageId = null;
      notifyListeners();
    }
  }

  /// Manually writes a line into the pet's cross-session memory (spec 3.4
  /// "让宠物记住这件事"). Backed locally; flagged on the message itself.
  void rememberMessage(ChatMessage message) {
    if (message.remembered) return;
    message.remembered = true;
    final petName = currentPet?.name ?? 'Your pet';
    memoryHint = '$petName will remember that 💭';
    _trimAndSaveMessages();
    notifyListeners();
  }

  void clearMemoryHint() {
    if (memoryHint == null) return;
    memoryHint = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  Future<void> _drainQueue() async {
    if (_processingQueue) return;
    _processingQueue = true;
    chatBusy = true;
    notifyListeners();
    try {
      while (_pending.isNotEmpty) {
        final userMsg = _pending.removeAt(0);
        await _deliver(userMsg);
      }
    } finally {
      _processingQueue = false;
      chatBusy = false;
      petThinking = false;
      notifyListeners();
    }
  }

  Future<void> _deliver(ChatMessage userMsg) async {
    petThinking = true;
    notifyListeners();

    String reply;
    try {
      await _syncCurrentPet();
      final remotePetId = currentPet?.remotePetId;
      if (PetPalBackend.isEnabled && remotePetId != null) {
        reply = await (_remoteApi ?? PetPalRemoteApi())
            .chatWithPet(
              petId: remotePetId,
              message: userMsg.text,
              pet: currentPet,
            )
            .timeout(_replyTimeout);
      } else {
        // Local demo: a short pause stands in for the pet "thinking".
        await Future<void>.delayed(const Duration(milliseconds: 700));
        reply = _mockReplyFor(userMsg.text);
      }
      userMsg.status = ChatStatus.sent;
    } on TimeoutException {
      // The message did reach the pet; it just "走神" — give a gentle fallback
      // line instead of leaving the user staring at an empty wait (spec 3.3).
      userMsg.status = ChatStatus.sent;
      reply = _timeoutReply();
    } catch (error) {
      debugPrint('PetPalController: remote chat failed: $error');
      if (PetPalBackend.isEnabled) {
        // A real backend failure: keep the message and let the user retry.
        userMsg.status = ChatStatus.failed;
        petThinking = false;
        _trimAndSaveMessages();
        notifyListeners();
        return;
      }
      // Demo mode has no network, so fall back to a local reply.
      userMsg.status = ChatStatus.sent;
      reply = _mockReplyFor(userMsg.text);
    }

    petThinking = false;
    _onPetReply(reply, sourceUserMessage: userMsg.text);
  }

  /// Appends a pet line, applies the reply-complete mood bump, and surfaces a
  /// memory hint when the user shared something worth remembering (spec 3.3).
  void _onPetReply(String reply, {String? sourceUserMessage}) {
    final pet = currentPet;
    if (pet != null) {
      final now = DateTime.now();
      _dailyResetIfNeeded(pet, now);
      final validChat = sourceUserMessage != null &&
          _isValidChatForStatus(sourceUserMessage, now);
      final previousLevel = pet.affinityLevel;
      if (validChat) {
        if (pet.chatMoodGainToday < 30) {
          final gain = (30 - pet.chatMoodGainToday).clamp(0, 4).toInt();
          pet.mood = (pet.mood + gain).clamp(0, 100).toInt();
          pet.chatMoodGainToday += gain;
        }
        pet.validChatCountToday += 1;
        if (pet.validChatCountToday >= 3 &&
            !pet.dailyChatAffinityDone &&
            pet.affinityGainToday < 3) {
          pet.affinity += 1;
          pet.affinityGainToday += 1;
          pet.dailyChatAffinityDone = true;
        }
      }
      _refreshStatusText(pet);
      _touch(pet, now: now);
      if (pet.affinityLevel > previousLevel) _showAffinityLevelNotice(pet);
    }
    final petMsg = ChatMessage.pet(reply);
    messages.add(petMsg);
    streamingMessageId = petMsg.id;
    latestBubble = reply;
    if (sourceUserMessage != null && _looksMemorable(sourceUserMessage)) {
      memoryHint = '${pet?.name ?? 'Your pet'} tucked that away 💭';
    }
    _trimAndSaveMessages();
    _saveCurrentPet();
    if (pet != null) unawaited(_syncPetStatus(pet));
    notifyListeners();
  }

  /// Lightweight heuristic for "did the user just share a personal fact" — used
  /// only to decide whether to flash the subtle memory hint.
  bool _looksMemorable(String message) {
    final lower = message.toLowerCase();
    const cues = [
      'my ',
      "i'm ",
      'i am ',
      'i love',
      'i like',
      'i hate',
      'remember',
      'favorite',
      'favourite',
      '我喜欢',
      '我是',
      '记住',
      '我的',
    ];
    return cues.any(lower.contains);
  }

  String _timeoutReply() {
    final pet = currentPet;
    final name = pet?.name ?? 'I';
    if (pet?.traits.contains('Sassy') ?? false) {
      return 'Ugh, I spaced out for a sec. Say that again?';
    }
    return '$name drifted off for a moment… could you tell me once more?';
  }

  Future<void> _syncCurrentPet() async {
    final pet = currentPet;
    if (pet == null || !PetPalBackend.isEnabled) return;

    try {
      final payload = await (_remoteApi ?? PetPalRemoteApi()).syncPet(pet);
      final remotePet = Map<String, dynamic>.from(payload['pet'] as Map);
      pet.remotePetId = remotePet['id'] as String?;
      await _saveCurrentPet();
    } catch (error) {
      debugPrint('PetPalController: pet sync failed: $error');
    }
  }

  Future<void> _syncPetStatus(PetProfile pet) async {
    if (!PetPalBackend.isEnabled) return;

    try {
      if (pet.remotePetId == null) {
        await _syncCurrentPet();
        return;
      }
      await (_remoteApi ?? PetPalRemoteApi()).updatePetStatus(
        petId: pet.remotePetId!,
        mood: pet.mood,
        hunger: pet.hunger,
        cleanliness: pet.cleanliness,
        statusText: pet.statusText,
        affinity: pet.affinity,
        affinityLevel: pet.affinityLevel,
        lastSettlementAt: pet.lastSettlementAt,
        lastDailyResetDate: pet.lastDailyResetDate,
        feedLastAt: pet.feedLastAt,
        caressLastAt: pet.caressLastAt,
        feedEffectiveCountToday: pet.feedEffectiveCountToday,
        caressEffectiveCountToday: pet.caressEffectiveCountToday,
        chatMoodGainToday: pet.chatMoodGainToday,
        validChatCountToday: pet.validChatCountToday,
        affinityGainToday: pet.affinityGainToday,
        returnTipShowCountToday: pet.returnTipShowCountToday,
        offlineEventShowCountToday: pet.offlineEventShowCountToday,
        shownEventIdsToday: pet.shownEventIdsToday,
        placedItemIds: pet.placedItemIds,
        dailyFirstFeedDone: pet.dailyFirstFeedDone,
        dailyFirstCaressDone: pet.dailyFirstCaressDone,
        dailyChatAffinityDone: pet.dailyChatAffinityDone,
        dailyFirstReturnDone: pet.dailyFirstReturnDone,
        lastOfflineEventAt: pet.lastOfflineEventAt,
        lastRoomItemUpdateAt: pet.lastRoomItemUpdateAt,
      );
    } catch (error) {
      debugPrint('PetPalController: status sync failed: $error');
    }
  }

  PresetRole _roleForStoredPet(Map<String, dynamic> json, int variant) {
    final roleId = json['roleId'] as String? ?? '';
    if (roleId.startsWith('upload-') ||
        json['sourceType'] == PetSourceType.uploadedPhoto.name) {
      return uploadedPlaceholder(variant);
    }
    return _repository.roleById(roleId) ?? roles.first;
  }

  void _dailyResetIfNeeded(PetProfile pet, DateTime now) {
    final today = petLocalDateKey(now);
    if (pet.lastDailyResetDate == today) return;
    pet.feedEffectiveCountToday = 0;
    pet.caressEffectiveCountToday = 0;
    pet.chatMoodGainToday = 0;
    pet.validChatCountToday = 0;
    pet.affinityGainToday = 0;
    pet.returnTipShowCountToday = 0;
    pet.offlineEventShowCountToday = 0;
    pet.shownEventIdsToday.clear();
    pet.dailyFirstFeedDone = false;
    pet.dailyFirstCaressDone = false;
    pet.dailyChatAffinityDone = false;
    pet.dailyFirstReturnDone = false;
    pet.lastDailyResetDate = today;
  }

  Duration? _settleOfflineState(PetProfile pet, DateTime now) {
    if (now.isBefore(pet.lastSettlementAt)) {
      pet.lastSettlementAt = now;
      return null;
    }

    final offlineDuration = now.difference(pet.lastSettlementAt);
    pet.lastSettlementAt = now;
    if (offlineDuration < const Duration(minutes: 10)) {
      return null;
    }

    final effective = offlineDuration > const Duration(hours: 24)
        ? const Duration(hours: 24)
        : offlineDuration;
    final hours = effective.inMinutes / 60;
    final hungerDecay = (hours * 3).floor();
    final moodRate = pet.hunger < 50 ? 3 : 2;
    final moodDecay = (hours * moodRate).floor();

    pet.hunger = (pet.hunger - hungerDecay).clamp(30, 100).toInt();
    pet.mood = (pet.mood - moodDecay).clamp(30, 100).toInt();
    return offlineDuration;
  }

  OfflineEventOccurrence? _createOfflineEventIfNeeded(
    PetProfile pet,
    Duration? offlineDuration,
    DateTime now,
  ) {
    if (offlineDuration == null) return null;
    if (offlineDuration < const Duration(hours: 2)) return null;
    if (now.difference(pet.createdAt) < const Duration(hours: 2)) return null;
    if (pet.offlineEventShowCountToday >= 3) return null;
    if (pendingAwayEvent != null || awayEventSaving) return null;

    final events = _seedRepository.offlineEvents();
    final moments = _seedRepository.moments();
    final event = _offlineEventEngine.selectEvent(
      pet: pet,
      offlineDuration: offlineDuration,
      now: now,
      events: events,
      moments: moments,
      savedMoments: userMoments,
      history: offlineEventHistory,
    );
    if (event == null) return null;

    MomentConfig? availableMoment;
    String? imageUrl;
    if (event.canUnlockMoment && event.momentId != null) {
      final moment = _momentById(event.momentId!);
      if (moment != null &&
          moment.enabled &&
          !moment.archived &&
          !_hasActiveMoment(moment.momentId)) {
        availableMoment = moment;
        imageUrl = _readyMomentImageUrlFor(pet, moment);
        if (imageUrl == null) {
          _queuePendingMomentEvent(
            pet: pet,
            event: event,
            moment: moment,
            offlineDuration: offlineDuration,
            now: now,
          );
          unawaited(_processPendingMomentImages());
          return null;
        }
      }
    }

    return _createVisibleOfflineOccurrence(
      pet: pet,
      event: event,
      now: now,
      offlineDurationMinutes: offlineDuration.inMinutes,
      moodBefore: pet.mood,
      hungerBefore: pet.hunger,
      affinityBefore: pet.affinity,
      placedItemIdsSnapshot: List.of(pet.placedItemIds),
      moment: availableMoment,
      imageUrl: imageUrl,
    );
  }

  OfflineEventOccurrence? _readyPendingMomentOccurrenceIfNeeded(
    PetProfile pet,
    DateTime now,
  ) {
    if (pet.offlineEventShowCountToday >= 3) return null;
    if (pendingAwayEvent != null || awayEventSaving) return null;
    final petIds = _petRecordIds(pet);
    for (final pending in List<PendingMomentEvent>.of(pendingMomentEvents)) {
      if (!petIds.contains(pending.petId)) continue;
      final event = _eventById(pending.eventId);
      final moment = _momentById(pending.momentId);
      if (event == null ||
          moment == null ||
          _hasActiveMoment(moment.momentId)) {
        pendingMomentEvents.remove(pending);
        unawaited(_savePendingMomentEvents());
        continue;
      }
      if (!pending.isReady) {
        final imageUrl = _readyMomentImageUrlFor(pet, moment);
        if (imageUrl == null) continue;
        pending
          ..imageUrl = imageUrl
          ..generationStatus = 'ready';
        unawaited(_savePendingMomentEvents());
      }
      if (pet.shownEventIdsToday.contains(pending.eventId)) continue;
      return _createVisibleOfflineOccurrence(
        pet: pet,
        event: event,
        now: now,
        offlineDurationMinutes: pending.offlineDurationMinutes,
        moodBefore: pending.moodBefore,
        hungerBefore: pending.hungerBefore,
        affinityBefore: pending.affinityBefore,
        placedItemIdsSnapshot: pending.placedItemIdsSnapshot,
        moment: moment,
        imageUrl: pending.imageUrl,
        pending: pending,
      );
    }
    return null;
  }

  OfflineEventOccurrence _createVisibleOfflineOccurrence({
    required PetProfile pet,
    required OfflineEventConfig event,
    required DateTime now,
    required int offlineDurationMinutes,
    required int moodBefore,
    required int hungerBefore,
    required int affinityBefore,
    required List<String> placedItemIdsSnapshot,
    MomentConfig? moment,
    String? imageUrl,
    PendingMomentEvent? pending,
  }) {
    pet.mood = (pet.mood + event.rewardMood).clamp(0, 100).toInt();
    pet.hunger = (pet.hunger + event.rewardHunger).clamp(0, 100).toInt();
    pet.affinity += event.rewardAffinity;
    pet.offlineEventShowCountToday += 1;
    pet.shownEventIdsToday.add(event.eventId);
    pet.lastOfflineEventAt = now;
    _refreshStatusText(pet);

    final history = OfflineEventHistory(
      historyId: _localId('away'),
      petId: _petRecordId(pet),
      eventId: event.eventId,
      eventType: event.eventType,
      triggeredAt: pending?.triggeredAt ?? now,
      offlineDurationMinutes: offlineDurationMinutes,
      moodBefore: moodBefore,
      hungerBefore: hungerBefore,
      affinityBefore: affinityBefore,
      moodAfter: pet.mood,
      hungerAfter: pet.hunger,
      affinityAfter: pet.affinity,
      placedItemIdsSnapshot: placedItemIdsSnapshot,
    );
    offlineEventHistory.add(history);
    _trimAndSaveOfflineEventHistory();

    final rewardLabels = <String>[
      if (event.rewardMood > 0) 'Mood +${event.rewardMood}',
      if (event.rewardHunger > 0) 'Hunger +${event.rewardHunger}',
      if (event.rewardAffinity > 0) 'Affinity +${event.rewardAffinity}',
      if (moment != null) 'New Moment',
    ];

    if (pending != null) {
      pendingMomentEvents.remove(pending);
      unawaited(_savePendingMomentEvents());
    }
    if (PetPalBackend.isEnabled) {
      unawaited(_syncOfflineEventHistory(history));
    }

    return OfflineEventOccurrence(
      config: event,
      history: history,
      moment: moment,
      title: _fillTemplate(event.titleTemplate, pet, event),
      body: _fillTemplate(event.bodyTemplate, pet, event),
      rewardLabels: rewardLabels,
      imageKey: event.imageKey,
      imageUrl: imageUrl,
    );
  }

  MomentConfig? _momentById(String momentId) {
    for (final moment in _seedRepository.moments()) {
      if (moment.momentId == momentId) return moment;
    }
    return null;
  }

  bool _hasActiveMoment(String momentId) {
    return userMoments.any(
      (record) => record.momentId == momentId && !record.isDeleted,
    );
  }

  OfflineEventConfig? _eventById(String eventId) {
    for (final event in _seedRepository.offlineEvents()) {
      if (event.eventId == eventId) return event;
    }
    return null;
  }

  String? _readyMomentImageUrlFor(PetProfile pet, MomentConfig moment) {
    final petIds = _petRecordIds(pet);
    for (final asset in momentAssets) {
      if (asset.momentId == moment.momentId &&
          asset.petId != null &&
          petIds.contains(asset.petId) &&
          asset.isReady) {
        return asset.imageUrl;
      }
    }
    for (final asset in momentAssets) {
      if (asset.momentId == moment.momentId &&
          asset.roleId == pet.role.id &&
          asset.isReady) {
        return asset.imageUrl;
      }
    }
    return moment.imageUrl ?? moment.defaultImageUrl;
  }

  void _queuePendingMomentEvent({
    required PetProfile pet,
    required OfflineEventConfig event,
    required MomentConfig moment,
    required Duration offlineDuration,
    required DateTime now,
  }) {
    final petId = _petRecordId(pet);
    final exists = pendingMomentEvents.any(
      (pending) =>
          _petRecordIds(pet).contains(pending.petId) &&
          pending.eventId == event.eventId &&
          pending.momentId == moment.momentId,
    );
    if (exists) return;
    pendingMomentEvents.add(
      PendingMomentEvent(
        pendingId: _localId('pending-moment'),
        petId: petId,
        eventId: event.eventId,
        momentId: moment.momentId,
        triggeredAt: now,
        offlineDurationMinutes: offlineDuration.inMinutes,
        moodBefore: pet.mood,
        hungerBefore: pet.hunger,
        affinityBefore: pet.affinity,
        placedItemIdsSnapshot: List.of(pet.placedItemIds),
      ),
    );
    unawaited(_savePendingMomentEvents());
  }

  Future<void> _processPendingMomentImages() async {
    if (_processingMomentImages || !PetPalBackend.isEnabled) return;
    final pet = currentPet;
    if (pet == null || pendingMomentEvents.isEmpty) return;
    _processingMomentImages = true;
    try {
      if (pet.remotePetId == null) await _syncCurrentPet();
      if (pet.remotePetId == null) return;
      final petIds = _petRecordIds(pet);
      for (final pending in List<PendingMomentEvent>.of(pendingMomentEvents)) {
        if (!petIds.contains(pending.petId) || pending.isReady) continue;
        final lastAttempt = pending.lastAttemptAt;
        final now = DateTime.now();
        if (lastAttempt != null &&
            now.difference(lastAttempt) < const Duration(seconds: 30)) {
          continue;
        }
        final event = _eventById(pending.eventId);
        final moment = _momentById(pending.momentId);
        if (event == null || moment == null) {
          pendingMomentEvents.remove(pending);
          continue;
        }
        final staticUrl = _readyMomentImageUrlFor(pet, moment);
        if (staticUrl != null) {
          pending
            ..imageUrl = staticUrl
            ..generationStatus = 'ready';
          continue;
        }

        pending
          ..generationStatus = 'generating'
          ..lastAttemptAt = now;
        await _savePendingMomentEvents();
        try {
          final title = _fillTemplate(event.titleTemplate, pet, event);
          final body = _fillTemplate(event.bodyTemplate, pet, event);
          final diary = _fillTemplate(moment.diaryTemplate, pet, event);
          final payload =
              await (_remoteApi ?? PetPalRemoteApi()).generateMomentImage(
            petId: pet.remotePetId!,
            pet: pet,
            event: event,
            moment: moment,
            title: title,
            body: body,
            diaryText: diary,
            pendingId: pending.pendingId,
          );
          final asset = _momentAssetFromPayload(
            payload['asset'],
            fallbackMomentId: moment.momentId,
            fallbackPetId: pet.remotePetId!,
          );
          if (asset == null || !asset.isReady) {
            pending.generationStatus = 'failed';
            continue;
          }
          _upsertMomentAsset(asset);
          pending
            ..imageUrl = asset.imageUrl
            ..generationStatus = 'ready'
            ..generationTaskId = payload['taskId'] as String?;
          if (pendingAwayEvent == null) {
            pendingAwayEvent =
                _readyPendingMomentOccurrenceIfNeeded(pet, DateTime.now());
            if (pendingAwayEvent != null) {
              latestBubble = pendingAwayEvent!.body;
              notifyListeners();
              break;
            }
          }
        } catch (error) {
          debugPrint(
              'PetPalController: moment image generation failed: $error');
          pending.generationStatus = 'pending';
        }
      }
    } finally {
      _processingMomentImages = false;
      await _saveMomentAssets();
      await _savePendingMomentEvents();
    }
  }

  MomentAsset? _momentAssetFromPayload(
    Object? raw, {
    required String fallbackMomentId,
    required String fallbackPetId,
  }) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final imageUrl = (map['imageUrl'] ?? map['image_url']) as String?;
    if (imageUrl == null || imageUrl.isEmpty) return null;
    return MomentAsset(
      assetId:
          (map['assetId'] ?? map['asset_id']) as String? ?? _localId('asset'),
      momentId:
          (map['momentId'] ?? map['moment_id']) as String? ?? fallbackMomentId,
      imageUrl: imageUrl,
      sourceType: (map['sourceType'] ?? map['source_type']) as String? ?? 'ai',
      petId: (map['petId'] ?? map['pet_id']) as String? ?? fallbackPetId,
      roleId: (map['roleId'] ?? map['role_id']) as String?,
      thumbnailUrl: (map['thumbnailUrl'] ?? map['thumbnail_url']) as String?,
      status: map['status'] as String? ?? 'ready',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  void _upsertMomentAsset(MomentAsset asset) {
    final index = momentAssets.indexWhere((item) =>
        item.assetId == asset.assetId ||
        (item.petId == asset.petId && item.momentId == asset.momentId));
    if (index >= 0) {
      momentAssets[index] = asset;
    } else {
      momentAssets.add(asset);
    }
  }

  String _fillTemplate(
    String template,
    PetProfile pet,
    OfflineEventConfig event,
  ) {
    return template
        .replaceAll('{pet_name}', pet.name)
        .replaceAll('{item_name}', _itemNameFor(event))
        .replaceAll(
            '{time_period}', OfflineEventEngine.timeWindowFor(DateTime.now()))
        .replaceAll('{pronoun}', 'they');
  }

  String _itemNameFor(OfflineEventConfig event) {
    var itemId = event.requiredItem;
    final placed = currentPet?.placedItemIds ?? const <String>[];
    if (itemId == null) {
      for (final relatedId in event.relatedItems) {
        if (placed.contains(relatedId)) {
          itemId = relatedId;
          break;
        }
      }
    }
    if (itemId == null) return 'their favorite spot';
    for (final item in _seedRepository.roomItems()) {
      if (item.itemId == itemId) return item.itemName;
    }
    return 'their favorite spot';
  }

  bool _awardDailyReturnAffinity(PetProfile pet) {
    if (pet.dailyFirstReturnDone || pet.affinityGainToday >= 3) return false;
    final previousLevel = pet.affinityLevel;
    pet.affinity += 1;
    pet.affinityGainToday += 1;
    pet.dailyFirstReturnDone = true;
    return pet.affinityLevel > previousLevel;
  }

  bool _awardFeedAffinity(PetProfile pet, int previousLevel) {
    if (pet.dailyFirstFeedDone || pet.affinityGainToday >= 3) return false;
    pet.affinity += 1;
    pet.affinityGainToday += 1;
    pet.dailyFirstFeedDone = true;
    return pet.affinityLevel > previousLevel;
  }

  bool _awardCaressAffinity(PetProfile pet, int previousLevel) {
    if (pet.dailyFirstCaressDone || pet.affinityGainToday >= 3) return false;
    pet.affinity += 1;
    pet.affinityGainToday += 1;
    pet.dailyFirstCaressDone = true;
    return pet.affinityLevel > previousLevel;
  }

  void _refreshStatusText(PetProfile pet) {
    pet.statusText = _statusTextFor(pet);
  }

  String _statusTextFor(PetProfile pet) {
    if (pet.generationStatus == 'generating') return 'Generating final avatar';
    return pet.mainStateText;
  }

  String _welcomeBackBubble(Duration? offlineDuration) {
    final pet = currentPet;
    if (pet == null) return 'I missed you. Want to play?';
    if (offlineDuration == null) return pet.mainStateText;
    return _returnTipText(pet, offlineDuration, DateTime.now());
  }

  String _returnTipText(
      PetProfile pet, Duration offlineDuration, DateTime now) {
    if (now.hour >= 22 || now.hour < 6) {
      return '${pet.name} was almost asleep, but noticed you came back.';
    }
    if (pet.hunger < 50) {
      return '${pet.name} keeps looking at the bowl.';
    }
    if (pet.mood >= 80) {
      return '${pet.name} looks excited that you are back.';
    }
    if (offlineDuration >= const Duration(hours: 12)) {
      return '${pet.name} missed you a little.';
    }
    if (offlineDuration >= const Duration(hours: 6)) {
      return '${pet.name} waited quietly for you.';
    }
    return '${pet.name} is happy to see you again.';
  }

  void _showAffinityLevelNotice(PetProfile pet) {
    _showRoomNotice(
      '${pet.name} feels closer to you. Affinity Lv.${pet.affinityLevel} unlocked.',
    );
  }

  void _showRoomNotice(String message) {
    roomNotice = message;
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 4), () {
      roomNotice = null;
      notifyListeners();
    });
  }

  bool _isValidChatForStatus(String message, DateTime now) {
    final text = message.trim();
    if (text.length < 2) return false;
    if (!_containsTextContent(text)) return false;
    final previousText = _lastValidChatText;
    final previousAt = _lastValidChatAt;
    if (previousText != null &&
        previousAt != null &&
        previousText == text.toLowerCase() &&
        now.difference(previousAt) < const Duration(seconds: 30)) {
      return false;
    }
    _lastValidChatText = text.toLowerCase();
    _lastValidChatAt = now;
    return true;
  }

  bool _containsTextContent(String text) {
    return RegExp(r'[A-Za-z0-9\u4e00-\u9fff]').hasMatch(text);
  }

  String _formatCooldown(Duration duration) {
    final minutes = (duration.inSeconds / 60).ceil();
    if (minutes <= 1) return '1m';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  String _mockReplyFor(String message) {
    final pet = currentPet;
    final traits = pet?.traits.join(', ') ?? 'sweet';
    if (message.endsWith('?')) {
      return 'I think yes. My $traits heart says we should try.';
    }
    if (message.toLowerCase().contains('sad') ||
        message.toLowerCase().contains('tired')) {
      return 'Come closer. We can make today smaller and softer.';
    }
    if (pet?.specialPersonalityDetail.isNotEmpty ?? false) {
      return '${pet!.specialPersonalityDetail} Also, I heard every word.';
    }
    return 'I heard you. Tell me one more tiny thing.';
  }

  void _touch(PetProfile pet, {DateTime? now}) {
    pet.lastActiveAt = now ?? DateTime.now();
  }

  String _petRecordId(PetProfile pet) {
    return pet.remotePetId ?? 'local-${pet.createdAt.millisecondsSinceEpoch}';
  }

  List<String> _petRecordIds(PetProfile pet) {
    return [
      if (pet.remotePetId != null) pet.remotePetId!,
      'local-${pet.createdAt.millisecondsSinceEpoch}',
    ];
  }

  String _localId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  void _restoreMoments(SharedPreferences prefs) {
    final raw = prefs.getString(_momentsStorageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      userMoments
        ..clear()
        ..addAll(
          list.map((item) => UserMomentRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              )),
        );
    } catch (error) {
      debugPrint('PetPalController: moments restore failed: $error');
    }
  }

  void _restoreMomentAssets(SharedPreferences prefs) {
    final raw = prefs.getString(_momentAssetsStorageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      momentAssets
        ..clear()
        ..addAll(
          list.map((item) => MomentAsset.fromJson(
                Map<String, dynamic>.from(item as Map),
              )),
        );
    } catch (error) {
      debugPrint('PetPalController: moment assets restore failed: $error');
    }
  }

  void _restorePendingMomentEvents(SharedPreferences prefs) {
    final raw = prefs.getString(_pendingMomentEventsStorageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      pendingMomentEvents
        ..clear()
        ..addAll(
          list.map((item) => PendingMomentEvent.fromJson(
                Map<String, dynamic>.from(item as Map),
              )),
        );
    } catch (error) {
      debugPrint('PetPalController: pending moments restore failed: $error');
    }
  }

  void _restoreOfflineEventHistory(SharedPreferences prefs) {
    final raw = prefs.getString(_offlineEventHistoryStorageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      offlineEventHistory
        ..clear()
        ..addAll(
          list.map((item) => OfflineEventHistory.fromJson(
                Map<String, dynamic>.from(item as Map),
              )),
        );
    } catch (error) {
      debugPrint('PetPalController: offline history restore failed: $error');
    }
  }

  Future<void> _saveCurrentPet() async {
    final pet = currentPet;
    if (pet == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_petStorageKey, jsonEncode(pet.toJson()));
  }

  Future<void> _saveMoments() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(userMoments.map((record) => record.toJson()).toList());
    await prefs.setString(_momentsStorageKey, encoded);
  }

  Future<void> _saveMomentAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(momentAssets.map((asset) => asset.toJson()).toList());
    await prefs.setString(_momentAssetsStorageKey, encoded);
  }

  Future<void> _savePendingMomentEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
        pendingMomentEvents.map((pending) => pending.toJson()).toList());
    await prefs.setString(_pendingMomentEventsStorageKey, encoded);
  }

  void _trimAndSaveOfflineEventHistory() {
    if (offlineEventHistory.length > _maxOfflineEventHistory) {
      offlineEventHistory.removeRange(
        0,
        offlineEventHistory.length - _maxOfflineEventHistory,
      );
    }
    unawaited(_saveOfflineEventHistory());
  }

  Future<void> _saveOfflineEventHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(offlineEventHistory.map((item) => item.toJson()).toList());
    await prefs.setString(_offlineEventHistoryStorageKey, encoded);
  }

  Future<void> _syncMomentRecord(
    UserMomentRecord record,
    OfflineEventHistory history,
  ) async {
    try {
      final pet = currentPet;
      if (pet == null) return;
      if (pet.remotePetId == null) await _syncCurrentPet();
      if (pet.remotePetId == null) return;
      await (_remoteApi ?? PetPalRemoteApi()).saveMomentRecord(
        petId: pet.remotePetId!,
        record: record,
        history: history,
      );
    } catch (error) {
      debugPrint('PetPalController: moment sync failed: $error');
    }
  }

  Future<void> _syncOfflineEventHistory(OfflineEventHistory history) async {
    try {
      final pet = currentPet;
      if (pet == null) return;
      if (pet.remotePetId == null) await _syncCurrentPet();
      if (pet.remotePetId == null) return;
      await (_remoteApi ?? PetPalRemoteApi()).saveOfflineEventHistory(
        petId: pet.remotePetId!,
        history: history,
      );
    } catch (error) {
      debugPrint('PetPalController: offline event sync failed: $error');
    }
  }

  Future<void> _deleteRemoteMoment(UserMomentRecord record) async {
    try {
      final pet = currentPet;
      if (pet?.remotePetId == null) return;
      await (_remoteApi ?? PetPalRemoteApi()).deleteMomentRecord(
        petId: pet!.remotePetId!,
        momentRecordId: record.momentRecordId,
        deletedAt: record.deletedAt ?? DateTime.now(),
      );
    } catch (error) {
      debugPrint('PetPalController: moment delete sync failed: $error');
    }
  }

  void _restoreMessages(SharedPreferences prefs) {
    final raw = prefs.getString(_messagesStorageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      messages
        ..clear()
        ..addAll(
          list.map((item) =>
              ChatMessage.fromJson(Map<String, dynamic>.from(item as Map))),
        );
      for (var i = messages.length - 1; i >= 0; i--) {
        if (messages[i].isPet) {
          latestBubble = messages[i].text;
          break;
        }
      }
    } catch (error) {
      debugPrint('PetPalController: message restore failed: $error');
    }
  }

  void _trimAndSaveMessages() {
    if (messages.length > _maxStoredMessages) {
      messages.removeRange(0, messages.length - _maxStoredMessages);
    }
    unawaited(_saveMessages());
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(messages.map((message) => message.toJson()).toList());
    await prefs.setString(_messagesStorageKey, encoded);
  }
}
