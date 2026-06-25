import 'dart:async';

import '../../../core/services/petpal_remote_api.dart';
import '../models/uploaded_pet_photo.dart';

class AvatarCandidate {
  const AvatarCandidate({
    required this.variant,
    required this.sourcePhotoPath,
    this.remoteImageUrl,
  });

  final int variant;
  final String sourcePhotoPath;
  final String? remoteImageUrl;
}

abstract class AvatarGenerationService {
  Future<List<AvatarCandidate>> generateOptions({
    required UploadedPetPhoto photo,
    required int generationRound,
  });
}

class MockAvatarGenerationService implements AvatarGenerationService {
  const MockAvatarGenerationService();

  @override
  Future<List<AvatarCandidate>> generateOptions({
    required UploadedPetPhoto photo,
    required int generationRound,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final offset = generationRound * 4;
    return List.generate(
      4,
      (index) => AvatarCandidate(
        variant: offset + index,
        sourcePhotoPath: photo.file.path,
      ),
    );
  }
}

class SupabaseAvatarGenerationService implements AvatarGenerationService {
  SupabaseAvatarGenerationService({PetPalRemoteApi? api})
      : _api = api ?? PetPalRemoteApi();

  final PetPalRemoteApi _api;

  @override
  Future<List<AvatarCandidate>> generateOptions({
    required UploadedPetPhoto photo,
    required int generationRound,
  }) async {
    final uploadedPath = await _api.uploadPetPhoto(photo.file);
    final taskPayload = await _api.createGenerationTask(
      inputPhotoPath: uploadedPath,
      retryCount: generationRound,
    );
    final task = Map<String, dynamic>.from(taskPayload['task'] as Map);
    final generatedPayload = await _api.generatePetAvatar(
      taskId: task['id'] as String,
    );
    final generatedTask =
        Map<String, dynamic>.from(generatedPayload['task'] as Map);
    final urls = (generatedTask['result_urls'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();

    if (urls.isEmpty) {
      throw StateError('The backend did not return avatar options.');
    }

    final offset = generationRound * 4;
    return [
      for (final entry in urls.asMap().entries)
        AvatarCandidate(
          variant: offset + entry.key,
          sourcePhotoPath: uploadedPath,
          remoteImageUrl: entry.value,
        ),
    ];
  }
}
