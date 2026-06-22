import 'dart:async';

import '../models/uploaded_pet_photo.dart';

class AvatarCandidate {
  const AvatarCandidate({
    required this.variant,
    required this.sourcePhotoPath,
  });

  final int variant;
  final String sourcePhotoPath;
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
