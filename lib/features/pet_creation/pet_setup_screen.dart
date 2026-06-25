import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/page_transitions.dart';
import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/models/preset_role.dart';
import '../../shared/widgets/pixel_button.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import '../../shared/widgets/pet_avatar_view.dart';
import '../../shared/widgets/speech_bubble.dart';
import '../../shared/widgets/trait_chip.dart';
import '../pet_room/pet_room_screen.dart';

enum PetSetupSource { upload, library }

class PetSetupScreen extends StatefulWidget {
  const PetSetupScreen._({
    required this.controller,
    required this.source,
  });

  factory PetSetupScreen.upload({required PetPalController controller}) {
    return PetSetupScreen._(
        controller: controller, source: PetSetupSource.upload);
  }

  factory PetSetupScreen.library({required PetPalController controller}) {
    return PetSetupScreen._(
        controller: controller, source: PetSetupSource.library);
  }

  final PetPalController controller;
  final PetSetupSource source;

  @override
  State<PetSetupScreen> createState() => _PetSetupScreenState();
}

class _PetSetupScreenState extends State<PetSetupScreen> {
  late final TextEditingController nameController;
  late final TextEditingController customTraitController;
  late final Set<String> traits;

  bool get isUpload => widget.source == PetSetupSource.upload;

  @override
  void initState() {
    super.initState();
    final role = widget.controller.selectedRole;
    nameController =
        TextEditingController(text: isUpload ? 'Mochi' : role?.name ?? 'Mochi');
    customTraitController = TextEditingController();
    traits = {
      ...(isUpload ? const <String>[] : role?.defaultTraits ?? const <String>[])
    };
  }

  @override
  void dispose() {
    nameController.dispose();
    customTraitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PresetRole role = isUpload
        ? widget.controller
            .uploadedPlaceholder(widget.controller.selectedAvatarVariant ?? 0)
        : widget.controller.selectedRole ?? widget.controller.roles.first;

    return PixelPageScaffold(
      child: Stack(
        children: [
          Positioned(
            top: 18,
            left: 14,
            right: 14,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Pixel.chevronleft),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF7E8C2),
                    foregroundColor: PetPalColors.bark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Name Your Pet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (isUpload)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: PetPalColors.ink.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Generating...',
                      style: TextStyle(
                        color: Color(0xFFF3D9A8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 104,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const SpeechBubble(text: 'What should my name be?'),
                const SizedBox(height: 4),
                PetAvatarView(
                  role: role,
                  imageUrl:
                      isUpload ? widget.controller.selectedAvatarUrl : null,
                  variant: widget.controller.selectedAvatarVariant ?? 0,
                  size: 154,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              child: PixelCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.58,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          maxLength: 12,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFBECCF),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Give me a name',
                            filled: true,
                            fillColor: PetPalColors.ink,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Color(0xFF6B4A28), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Color(0xFF6B4A28), width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: PetPalColors.honey, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Choose traits (2-3)',
                          style: TextStyle(
                            color: Color(0xFF9A7544),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.35,
                          children: [
                            for (final trait in PetPalController.allTraits)
                              TraitChip(
                                label: trait,
                                selected: traits.contains(trait),
                                onTap: () => _toggleTrait(trait),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: customTraitController,
                          minLines: 2,
                          maxLines: 3,
                          maxLength: 300,
                          decoration: InputDecoration(
                            hintText:
                                'Optional: describe a special personality detail.',
                            counterStyle:
                                const TextStyle(color: Color(0xFFB09367)),
                            filled: true,
                            fillColor: const Color(0xFFFFFAF0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD8B87F)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD8B87F)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: PetPalColors.honey, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PixelButton(
                          label: 'Enter My Room',
                          icon: const Icon(Pixel.chevronright, size: 22),
                          enabled: traits.length >= 2,
                          onPressed: traits.length < 2 ? null : _enterRoom,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTrait(String trait) {
    setState(() {
      if (traits.contains(trait)) {
        traits.remove(trait);
      } else if (traits.length < 3) {
        traits.add(trait);
      }
    });
  }

  void _enterRoom() {
    final selectedTraits = traits.toList();
    if (isUpload) {
      widget.controller.createUploadedPet(
        name: nameController.text,
        traits: selectedTraits,
        specialPersonalityDetail: customTraitController.text,
      );
    } else {
      widget.controller.createPresetPet(
        name: nameController.text,
        traits: selectedTraits,
        specialPersonalityDetail: customTraitController.text,
      );
    }
    Navigator.of(context).pushAndRemoveUntil(
      petPalRoute(
        builder: (_) => PetRoomScreen(controller: widget.controller),
      ),
      (route) => false,
    );
  }
}
