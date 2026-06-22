import 'package:image_picker/image_picker.dart';

enum PetPhotoSource { album, camera }

class UploadedPetPhoto {
  const UploadedPetPhoto({
    required this.file,
    required this.source,
  });

  final XFile file;
  final PetPhotoSource source;

  String get sourceLabel {
    return switch (source) {
      PetPhotoSource.album => 'Album photo',
      PetPhotoSource.camera => 'Camera photo',
    };
  }
}
