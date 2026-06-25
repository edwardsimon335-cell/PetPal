import 'package:flutter/material.dart';

import '../models/preset_role.dart';
import 'pixel_pet_sprite.dart';

class PetAvatarView extends StatelessWidget {
  const PetAvatarView({
    required this.role,
    this.imageUrl,
    this.variant = 0,
    this.size = 148,
    super.key,
  });

  final PresetRole role;
  final String? imageUrl;
  final int variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return PixelPetSprite(role: role, variant: variant, size: size);
    }

    return SizedBox(
      width: size,
      height: size * 1.16,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (context, error, stackTrace) {
              return PixelPetSprite(role: role, variant: variant, size: size);
            },
          ),
        ),
      ),
    );
  }
}
