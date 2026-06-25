import 'package:flutter/material.dart';

import '../../../core/theme/petpal_theme.dart';
import '../../../shared/models/preset_role.dart';
import '../../../shared/widgets/pet_avatar_view.dart';
import 'thinking_dots.dart';

/// The pet "思考态" bubble (spec 3.3): an animated "…" shown while the pet is
/// composing a reply, so the user never faces an unresponsive blank wait. Used
/// in the chat history list (left-aligned, with the pet avatar).
class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({
    required this.role,
    this.avatarUrl,
    this.avatarVariant = 0,
    super.key,
  });

  final PresetRole role;
  final String? avatarUrl;
  final int avatarVariant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF0),
              shape: BoxShape.circle,
              border: Border.all(color: PetPalColors.line, width: 1.5),
            ),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 34,
                height: 34,
                child: PetAvatarView(
                  role: role,
                  imageUrl: avatarUrl,
                  variant: avatarVariant,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF0).withValues(alpha: 0.86),
              border: Border.all(color: PetPalColors.line, width: 2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const ThinkingDots(),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
