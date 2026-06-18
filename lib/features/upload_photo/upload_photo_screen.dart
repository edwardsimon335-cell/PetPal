import 'package:flutter/material.dart';

import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/widgets/pixel_button.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import 'photo_preview_screen.dart';

class UploadPhotoScreen extends StatelessWidget {
  const UploadPhotoScreen({required this.controller, super.key});

  final PetPalController controller;

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
                    border: Border.all(color: const Color(0xFFE0B878), width: 2),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_outlined, size: 66, color: Color(0xFFB07F3F)),
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
                      const _FocusCorner(top: 18, left: 18),
                      const _FocusCorner(top: 18, right: 18, flipX: true),
                      const _FocusCorner(bottom: 18, left: 18, flipY: true),
                      const _FocusCorner(bottom: 18, right: 18, flipX: true, flipY: true),
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
              Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: PixelButton(
                      label: 'Album',
                      secondary: true,
                      icon: const Icon(Icons.photo_library_outlined, size: 19),
                      onPressed: () => _goPreview(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PixelButton(
                      label: 'Take Photo',
                      icon: const Icon(Icons.camera_alt_outlined, size: 22),
                      onPressed: () => _goPreview(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoPreviewScreen(controller: controller),
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
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF7E8C2),
            foregroundColor: PetPalColors.bark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        Row(
          children: List.generate(3, (index) {
            return Container(
              width: 18,
              height: 6,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                color: index < activeSteps ? PetPalColors.honey : const Color(0xFFDCC59A),
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
