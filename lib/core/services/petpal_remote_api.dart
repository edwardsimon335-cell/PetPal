import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/pet_profile.dart';
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
    bool? dailyFirstFeedDone,
    bool? dailyFirstCaressDone,
    bool? dailyChatAffinityDone,
    bool? dailyFirstReturnDone,
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
        if (dailyFirstFeedDone != null)
          'dailyFirstFeedDone': dailyFirstFeedDone,
        if (dailyFirstCaressDone != null)
          'dailyFirstCaressDone': dailyFirstCaressDone,
        if (dailyChatAffinityDone != null)
          'dailyChatAffinityDone': dailyChatAffinityDone,
        if (dailyFirstReturnDone != null)
          'dailyFirstReturnDone': dailyFirstReturnDone,
      },
    );
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
      'dailyFirstFeedDone': pet.dailyFirstFeedDone,
      'dailyFirstCaressDone': pet.dailyFirstCaressDone,
      'dailyChatAffinityDone': pet.dailyChatAffinityDone,
      'dailyFirstReturnDone': pet.dailyFirstReturnDone,
      'localDate': petLocalDateKey(DateTime.now()),
    };
  }
}
