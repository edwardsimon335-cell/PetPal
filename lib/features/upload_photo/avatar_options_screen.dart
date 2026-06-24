import 'package:flutter/material.dart';

import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/widgets/pixel_button.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import '../../shared/widgets/pixel_pet_sprite.dart';
import '../pet_creation/pet_setup_screen.dart';
import 'models/uploaded_pet_photo.dart';
import 'services/avatar_generation_service.dart';
import 'upload_photo_screen.dart';

class AvatarOptionsScreen extends StatefulWidget {
  const AvatarOptionsScreen({
    required this.controller,
    required this.photo,
    this.generationService = const MockAvatarGenerationService(),
    super.key,
  });

  final PetPalController controller;
  final UploadedPetPhoto photo;
  final AvatarGenerationService generationService;

  @override
  State<AvatarOptionsScreen> createState() => _AvatarOptionsScreenState();
}

class _AvatarOptionsScreenState extends State<AvatarOptionsScreen> {
  int regenerateLeft = 2;
  int generationRound = 0;
  bool loading = true;
  String? generationError;
  List<AvatarCandidate> candidates = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.setUploadPhotoPath(widget.photo.file.path);
    widget.controller.clearGeneratedAvatarSelection();
    _generateOptions();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return PixelPageScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: PixelCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          child: Column(
            children: [
              FlowTopBar(
                title: 'Choose Your Favorite',
                activeSteps: 3,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
              const Text(
                'AI created 4 pixel pet options. Pick one you like.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9A7544),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _buildCandidateArea(controller),
              ),
              const SizedBox(height: 12),
              PixelButton(
                label: 'Regenerate All ($regenerateLeft left)',
                secondary: true,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                enabled: regenerateLeft > 0 && !loading,
                onPressed: regenerateLeft > 0
                    ? () {
                        setState(() {
                          regenerateLeft -= 1;
                          generationRound += 1;
                        });
                        controller.clearGeneratedAvatarSelection();
                        _generateOptions();
                      }
                    : null,
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return PixelButton(
                    label: 'Confirm Selection',
                    enabled: controller.selectedAvatarVariant != null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    onPressed: controller.selectedAvatarVariant == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PetSetupScreen.upload(
                                    controller: controller),
                              ),
                            );
                          },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateArea(PetPalController controller) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: PetPalColors.honey),
            SizedBox(height: 14),
            Text(
              'Creating pixel options...',
              style: TextStyle(
                color: Color(0xFF9A7544),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      );
    }

    if (generationError != null) {
      return Center(
        child: Text(
          generationError!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFB85032),
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.94,
          ),
          itemCount: candidates.length,
          itemBuilder: (context, index) {
            final candidate = candidates[index];
            final selected =
                controller.selectedAvatarVariant == candidate.variant;
            return PixelCard(
              dark: true,
              selected: selected,
              onTap: () => controller.selectGeneratedAvatar(
                candidate.variant,
                remoteImageUrl: candidate.remoteImageUrl,
              ),
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  Center(
                    child: candidate.remoteImageUrl == null
                        ? PixelPetSprite(
                            role: controller
                                .uploadedPlaceholder(candidate.variant),
                            variant: candidate.variant,
                            size: 112,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              candidate.remoteImageUrl!,
                              width: 116,
                              height: 116,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return PixelPetSprite(
                                  role: controller
                                      .uploadedPlaceholder(candidate.variant),
                                  variant: candidate.variant,
                                  size: 112,
                                );
                              },
                            ),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _IndexBadge(number: index + 1),
                  ),
                  if (selected)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: PetPalColors.honey,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateOptions() async {
    setState(() {
      loading = true;
      generationError = null;
    });

    try {
      final generated = await widget.generationService.generateOptions(
        photo: widget.photo,
        generationRound: generationRound,
      );
      if (!mounted) return;
      setState(() {
        candidates = generated;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        generationError = 'Could not create options. Please try again.';
      });
    }
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFBECCF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: PetPalColors.bark,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
