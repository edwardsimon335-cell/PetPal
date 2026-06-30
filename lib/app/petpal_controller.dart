import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/petpal_backend.dart';
import '../core/services/petpal_remote_api.dart';
import '../shared/models/chat_message.dart';
import '../shared/models/pet_activity.dart';
import '../shared/models/pet_profile.dart';
import '../shared/models/preset_role.dart';
import '../shared/repositories/mock_pet_repository.dart';

class PetPalController extends ChangeNotifier {
  PetPalController({
    MockPetRepository repository = const MockPetRepository(),
    PetPalRemoteApi? remoteApi,
  })  : _repository = repository,
        _remoteApi = remoteApi {
    roles = _repository.presetRoles();
  }

  static const _petStorageKey = 'petpal.current_pet.v1';
  static const _messagesStorageKey = 'petpal.messages.v1';
  static const _maxStoredMessages = 200;
  static const _replyTimeout = Duration(seconds: 20);

  final MockPetRepository _repository;
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

  /// Full conversation history, shared by the main-screen dialogue overlay and
  /// the chat history window (spec 3.3 / 3.4). Oldest first.
  final List<ChatMessage> messages = [];

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
    latestBubble = _welcomeBackBubble(offlineDuration);
    _touch(pet, now: currentTime);
    unawaited(_saveCurrentPet());
    if (leveledUp) _showAffinityLevelNotice(pet);
    if (offlineDuration != null) {
      _showReturnTipIfNeeded(pet, offlineDuration, currentTime);
    }
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
        dailyFirstFeedDone: pet.dailyFirstFeedDone,
        dailyFirstCaressDone: pet.dailyFirstCaressDone,
        dailyChatAffinityDone: pet.dailyChatAffinityDone,
        dailyFirstReturnDone: pet.dailyFirstReturnDone,
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

  void _showReturnTipIfNeeded(
    PetProfile pet,
    Duration offlineDuration,
    DateTime now,
  ) {
    if (offlineDuration < const Duration(hours: 2)) return;
    if (pet.returnTipShowCountToday >= 2) return;
    pet.returnTipShowCountToday += 1;
    _showRoomNotice(_returnTipText(pet, offlineDuration, now));
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

  Future<void> _saveCurrentPet() async {
    final pet = currentPet;
    if (pet == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_petStorageKey, jsonEncode(pet.toJson()));
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
