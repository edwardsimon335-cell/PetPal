import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/page_transitions.dart';
import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/widgets/pixel_button.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import 'models/uploaded_pet_photo.dart';
import 'photo_preview_screen.dart';

class UploadPhotoScreen extends StatefulWidget {
  const UploadPhotoScreen({required this.controller, super.key});

  final PetPalController controller;

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  final ImagePicker picker = ImagePicker();

  bool picking = false;
  String? pickerError;

  @override
  Widget build(BuildContext context) {
    return PixelPageScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: PixelCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          child: Column(
            children: [
              _FlowTopBar(
                title: 'Upload Pet Photo',
                activeSteps: 1,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4D9A6),
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: const Color(0xFFE0B878), width: 2),
                  ),
                  child: const Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Pixel.camera,
                                size: 66, color: Color(0xFFB07F3F)),
                            SizedBox(height: 12),
                            Text(
                              'Place your pet inside the frame',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFA9824C),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _FocusCorner(top: 18, left: 18),
                      _FocusCorner(top: 18, right: 18, flipX: true),
                      _FocusCorner(bottom: 18, left: 18, flipY: true),
                      _FocusCorner(
                          bottom: 18, right: 18, flipX: true, flipY: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Front-facing, clear photo is recommended. Single pet works best.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9A7544),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              if (pickerError != null) ...[
                Text(
                  pickerError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB85032),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Column(
                children: [
                  PixelButton(
                    label: 'Choose from Album',
                    secondary: true,
                    icon: const Icon(Pixel.imagegallery, size: 19),
                    enabled: !picking,
                    onPressed: () => _pickPhoto(PetPhotoSource.album),
                  ),
                  const SizedBox(height: 10),
                  PixelButton(
                    label: 'Take Photo',
                    icon: const Icon(Pixel.cameraalt, size: 22),
                    enabled: !picking,
                    onPressed: () => _pickPhoto(PetPhotoSource.camera),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(PetPhotoSource source) async {
    setState(() {
      picking = true;
      pickerError = null;
    });

    try {
      final pickedFile = await picker.pickImage(
        source: source == PetPhotoSource.album
            ? ImageSource.gallery
            : ImageSource.camera,
        maxWidth: 1800,
        imageQuality: 92,
      );
      if (!mounted) return;
      if (pickedFile == null) {
        setState(() => picking = false);
        return;
      }
      _goPreview(
        context,
        UploadedPetPhoto(file: pickedFile, source: source),
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        picking = false;
        pickerError = error.message ?? 'Could not open photo picker.';
      });
    }
  }

  void _goPreview(BuildContext context, UploadedPetPhoto photo) {
    setState(() => picking = false);
    Navigator.of(context).push(
      petPalRoute(
        builder: (_) => PhotoPreviewScreen(
          controller: widget.controller,
          photo: photo,
        ),
      ),
    );
  }
}

class _FlowTopBar extends StatelessWidget {
  const _FlowTopBar({
    required this.title,
    required this.activeSteps,
    required this.onBack,
  });

  final String title;
  final int activeSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Pixel.chevronleft),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF7E8C2),
            foregroundColor: PetPalColors.bark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        Row(
          children: List.generate(3, (index) {
            return Container(
              width: 18,
              height: 6,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                color: index < activeSteps
                    ? PetPalColors.honey
                    : const Color(0xFFDCC59A),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FocusCorner extends StatelessWidget {
  const _FocusCorner({
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.flipX = false,
    this.flipY = false,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final bool flipX;
  final bool flipY;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(flipX ? -1 : 1, flipY ? -1 : 1, 1),
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: PetPalColors.honey, width: 4),
              left: BorderSide(color: PetPalColors.honey, width: 4),
            ),
          ),
        ),
      ),
    );
  }
}

class FlowTopBar extends StatelessWidget {
  const FlowTopBar({
    required this.title,
    required this.activeSteps,
    required this.onBack,
    super.key,
  });

  final String title;
  final int activeSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _FlowTopBar(title: title, activeSteps: activeSteps, onBack: onBack);
  }
}
