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
  }) async {
    final response = await _client.functions.invoke(
      'chat-with-pet',
      body: {
        'petId': petId,
        'message': message,
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
        'mood': pet.mood,
        'hunger': pet.hunger,
        'cleanliness': pet.cleanliness,
        'statusText': pet.statusText,
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
  }) async {
    await _client.functions.invoke(
      'update-pet-status',
      body: {
        'petId': petId,
        if (mood != null) 'mood': mood,
        if (hunger != null) 'hunger': hunger,
        if (cleanliness != null) 'cleanliness': cleanliness,
        if (statusText != null) 'statusText': statusText,
      },
    );
  }
}
