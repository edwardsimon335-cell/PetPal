import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/petpal_controller.dart';
import '../../core/services/petpal_backend.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/widgets/pixel_button.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import 'avatar_options_screen.dart';
import 'models/uploaded_pet_photo.dart';
import 'services/avatar_generation_service.dart';
import 'upload_photo_screen.dart';

class PhotoPreviewScreen extends StatelessWidget {
  const PhotoPreviewScreen({
    required this.controller,
    required this.photo,
    super.key,
  });

  final PetPalController controller;
  final UploadedPetPhoto photo;

  @override
  Widget build(BuildContext context) {
    return PixelPageScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: PixelCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          child: Column(
            children: [
              FlowTopBar(
                title: 'Confirm Photo',
                activeSteps: 2,
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
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(photo.file.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.pets_rounded,
                                  color: Color(0xFFC08A48),
                                  size: 82,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFAF0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: PetPalColors.line),
                          ),
                          child: const Text(
                            'Photo Selected',
                            style: TextStyle(
                              color: PetPalColors.cocoa,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _QualityHint(text: photo.sourceLabel),
              const _QualityHint(text: 'Pet is clearly visible'),
              const _QualityHint(text: 'Single pet'),
              const _QualityHint(text: 'Background may affect the result'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'Choose Again',
                      secondary: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PixelButton(
                      label: 'Start Generation',
                      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AvatarOptionsScreen(
                              controller: controller,
                              photo: photo,
                              generationService: PetPalBackend.isEnabled
                                  ? SupabaseAvatarGenerationService()
                                  : const MockAvatarGenerationService(),
                            ),
                          ),
                        );
                      },
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
}

class _QualityHint extends StatelessWidget {
  const _QualityHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: PetPalColors.honey, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF8A6634),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
