import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/page_transitions.dart';
import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/models/preset_role.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import '../../shared/widgets/pixel_pet_sprite.dart';
import '../pet_creation/pet_setup_screen.dart';

class CharacterLibraryScreen extends StatelessWidget {
  const CharacterLibraryScreen({required this.controller, super.key});

  final PetPalController controller;

  @override
  Widget build(BuildContext context) {
    return PixelPageScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: PixelCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          child: Column(
            children: [
              Row(
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
                      'Character Library',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a ready-made companion with preset personality.',
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
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: controller.roles.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, index) {
                        final role = controller.roles[index];
                        return _RoleCard(
                          role: role,
                          selected: controller.selectedRole?.id == role.id,
                          onTap: () {
                            controller.selectRole(role);
                            Navigator.of(context).push(
                              petPalRoute(
                                builder: (_) => PetSetupScreen.library(
                                  controller: controller,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final PresetRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: PixelPetSprite(role: role, size: 92),
            ),
          ),
          Text(
            role.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PetPalColors.bark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            role.defaultTraits.take(2).join(' / '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9A7544),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
