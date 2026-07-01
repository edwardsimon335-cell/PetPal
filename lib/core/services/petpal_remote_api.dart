import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/pet_profile.dart';
import '../../shared/models/petpal_v12_models.dart';
import 'petpal_backend.dart';

class PetPalRemoteApi {
  PetPalRemoteApi({SupabaseClient? client})
      : _client = client ?? PetPalBackend.client;

  final SupabaseClient _client;

  Future<String> uploadPetPhoto(XFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('A Supabase user session is required.');
    }

    final bytes = await file.readAsBytes();
    final nameParts = file.name.split('.');
    final extension = nameParts.length > 1 ? nameParts.last : 'jpg';
    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage.from('pet-uploads').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: file.mimeType ?? 'image/jpeg',
            upsert: true,
          ),
        );

    return path;
  }

  Future<Map<String, dynamic>> createGenerationTask({
    required String inputPhotoPath,
    required int retryCount,
  }) async {
    final response = await _client.functions.invoke(
      'create-generation-task',
      body: {
        'inputPhotoPath': inputPhotoPath,
        'retryCount': retryCount,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> generatePetAvatar({
    required String taskId,
  }) async {
    final response = await _client.functions.invoke(
      'generate-pet-avatar',
      body: {'taskId': taskId},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<String> chatWithPet({
    required String petId,
    required String message,
    PetProfile? pet,
  }) async {
    final response = await _client.functions.invoke(
      'chat-with-pet',
      body: {
        'petId': petId,
        'message': message,
        if (pet != null) ..._statusPayload(pet),
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return data['reply'] as String? ?? 'I am here with you.';
  }

  Future<Map<String, dynamic>> syncPet(PetProfile pet) async {
    final response = await _client.functions.invoke(
      'sync-pet',
      body: {
        if (pet.remotePetId != null) 'petId': pet.remotePetId,
        'sourceType': pet.sourceType == PetSourceType.presetRole
            ? 'preset_role'
            : 'uploaded_photo',
        if (pet.sourceType == PetSourceType.presetRole)
          'presetRoleId': pet.role.id,
        'name': pet.name,
        'species': pet.role.species,
        'avatarUrl': pet.avatarUrl,
        'sourcePhotoPath': pet.sourcePhotoPath,
        'personalityTags': pet.traits,
        'specialPersonalityDetail': pet.specialPersonalityDetail,
        ..._statusPayload(pet),
        'generationStatus': pet.generationStatus,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> updatePetStatus({
    required String petId,
    int? mood,
    int? hunger,
    int? cleanliness,
    String? statusText,
    int? affinity,
    int? affinityLevel,
    DateTime? lastSettlementAt,
    String? lastDailyResetDate,
    DateTime? feedLastAt,
    DateTime? caressLastAt,
    int? feedEffectiveCountToday,
    int? caressEffectiveCountToday,
    int? chatMoodGainToday,
    int? validChatCountToday,
    int? affinityGainToday,
    int? returnTipShowCountToday,
    int? offlineEventShowCountToday,
    List<String>? shownEventIdsToday,
    List<String>? placedItemIds,
    bool? dailyFirstFeedDone,
    bool? dailyFirstCaressDone,
    bool? dailyChatAffinityDone,
    bool? dailyFirstReturnDone,
    DateTime? lastOfflineEventAt,
    DateTime? lastRoomItemUpdateAt,
  }) async {
    await _client.functions.invoke(
      'update-pet-status',
      body: {
        'petId': petId,
        if (mood != null) 'mood': mood,
        if (hunger != null) 'hunger': hunger,
        if (cleanliness != null) 'cleanliness': cleanliness,
        if (statusText != null) 'statusText': statusText,
        if (affinity != null) 'affinity': affinity,
        if (affinityLevel != null) 'affinityLevel': affinityLevel,
        if (lastSettlementAt != null)
          'lastSettlementAt': lastSettlementAt.toIso8601String(),
        if (lastDailyResetDate != null)
          'lastDailyResetDate': lastDailyResetDate,
        if (feedLastAt != null) 'feedLastAt': feedLastAt.toIso8601String(),
        if (caressLastAt != null)
          'caressLastAt': caressLastAt.toIso8601String(),
        if (feedEffectiveCountToday != null)
          'feedEffectiveCountToday': feedEffectiveCountToday,
        if (caressEffectiveCountToday != null)
          'caressEffectiveCountToday': caressEffectiveCountToday,
        if (chatMoodGainToday != null) 'chatMoodGainToday': chatMoodGainToday,
        if (validChatCountToday != null)
          'validChatCountToday': validChatCountToday,
        if (affinityGainToday != null) 'affinityGainToday': affinityGainToday,
        if (returnTipShowCountToday != null)
          'returnTipShowCountToday': returnTipShowCountToday,
        if (offlineEventShowCountToday != null)
          'offlineEventShowCountToday': offlineEventShowCountToday,
        if (shownEventIdsToday != null)
          'shownEventIdsToday': shownEventIdsToday,
        if (placedItemIds != null) 'placedItemIds': placedItemIds,
        if (dailyFirstFeedDone != null)
          'dailyFirstFeedDone': dailyFirstFeedDone,
        if (dailyFirstCaressDone != null)
          'dailyFirstCaressDone': dailyFirstCaressDone,
        if (dailyChatAffinityDone != null)
          'dailyChatAffinityDone': dailyChatAffinityDone,
        if (dailyFirstReturnDone != null)
          'dailyFirstReturnDone': dailyFirstReturnDone,
        if (lastOfflineEventAt != null)
          'lastOfflineEventAt': lastOfflineEventAt.toIso8601String(),
        if (lastRoomItemUpdateAt != null)
          'lastRoomItemUpdateAt': lastRoomItemUpdateAt.toIso8601String(),
      },
    );
  }

  Future<void> saveOfflineEventHistory({
    required String petId,
    required OfflineEventHistory history,
  }) async {
    await _client.functions.invoke(
      'record-offline-event',
      body: {
        'petId': petId,
        'history': history.toJson(),
      },
    );
  }

  Future<void> saveMomentRecord({
    required String petId,
    required UserMomentRecord record,
    required OfflineEventHistory history,
  }) async {
    await _client.functions.invoke(
      'save-moment',
      body: {
        'petId': petId,
        'record': record.toJson(),
        'historyId': history.historyId,
      },
    );
  }

  Future<void> deleteMomentRecord({
    required String petId,
    required String momentRecordId,
    required DateTime deletedAt,
  }) async {
    await _client.functions.invoke(
      'delete-moment',
      body: {
        'petId': petId,
        'momentRecordId': momentRecordId,
        'deletedAt': deletedAt.toIso8601String(),
      },
    );
  }

  Future<Map<String, dynamic>> generateMomentImage({
    required String petId,
    required PetProfile pet,
    required OfflineEventConfig event,
    required MomentConfig moment,
    required String title,
    required String body,
    required String diaryText,
    String? pendingId,
  }) async {
    final response = await _client.functions.invoke(
      'generate-moment-image',
      body: {
        'petId': petId,
        'pendingId': pendingId,
        'eventId': event.eventId,
        'eventType': event.eventType,
        'momentId': moment.momentId,
        'momentType': moment.momentType,
        'imageKey': event.imageKey,
        'title': title,
        'body': body,
        'diaryText': diaryText,
        'petName': pet.name,
        'roleId': pet.role.id,
        'species': pet.role.species,
        'sourceType': pet.sourceType == PetSourceType.presetRole
            ? 'preset_role'
            : 'uploaded_photo',
        'personalityTags': pet.traits,
        'specialPersonalityDetail': pet.specialPersonalityDetail,
        'avatarUrl': pet.avatarUrl,
        'sourcePhotoPath': pet.sourcePhotoPath,
        'placedItemIds': pet.placedItemIds,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Map<String, dynamic> _statusPayload(PetProfile pet) {
    return {
      'mood': pet.mood,
      'hunger': pet.hunger,
      'cleanliness': pet.cleanliness,
      'statusText': pet.statusText,
      'moodLevel': pet.moodLevel.name,
      'hungerLevel': pet.hungerLevel.name,
      'mainState': pet.mainState.name,
      'affinity': pet.affinity,
      'affinityLevel': pet.affinityLevel,
      'lastSettlementAt': pet.lastSettlementAt.toIso8601String(),
      'lastDailyResetDate': pet.lastDailyResetDate,
      'feedLastAt': pet.feedLastAt?.toIso8601String(),
      'caressLastAt': pet.caressLastAt?.toIso8601String(),
      'feedEffectiveCountToday': pet.feedEffectiveCountToday,
      'caressEffectiveCountToday': pet.caressEffectiveCountToday,
      'chatMoodGainToday': pet.chatMoodGainToday,
      'validChatCountToday': pet.validChatCountToday,
      'affinityGainToday': pet.affinityGainToday,
      'returnTipShowCountToday': pet.returnTipShowCountToday,
      'offlineEventShowCountToday': pet.offlineEventShowCountToday,
      'shownEventIdsToday': pet.shownEventIdsToday,
      'placedItemIds': pet.placedItemIds,
      'dailyFirstFeedDone': pet.dailyFirstFeedDone,
      'dailyFirstCaressDone': pet.dailyFirstCaressDone,
      'dailyChatAffinityDone': pet.dailyChatAffinityDone,
      'dailyFirstReturnDone': pet.dailyFirstReturnDone,
      'lastOfflineEventAt': pet.lastOfflineEventAt?.toIso8601String(),
      'lastRoomItemUpdateAt': pet.lastRoomItemUpdateAt?.toIso8601String(),
      'localDate': petLocalDateKey(DateTime.now()),
    };
  }
}
