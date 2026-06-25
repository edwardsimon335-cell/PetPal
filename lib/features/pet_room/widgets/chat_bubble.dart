import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../../core/theme/petpal_theme.dart';
import '../../../shared/models/chat_message.dart';
import '../../../shared/models/preset_role.dart';
import '../../../shared/widgets/pet_avatar_view.dart';

/// A standard IM-style chat bubble used in the chat history window: pet lines
/// hug the left (with a small pixel avatar), user lines hug the right.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    required this.role,
    this.avatarUrl,
    this.avatarVariant = 0,
    this.showAvatar = true,
    this.onRetry,
    this.onLongPressRemember,
    super.key,
  });

  final ChatMessage message;
  final PresetRole role;
  final String? avatarUrl;
  final int avatarVariant;
  final bool showAvatar;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPressRemember;

  static const _textStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.28,
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    // IM convention: a bubble takes at most ~72% of the width, leaving a margin
    // on the *opposite* side only — never a gap on its own side.
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;
    return message.isUser
        ? _buildUser(maxBubbleWidth)
        : _buildPet(maxBubbleWidth);
  }

  Widget _buildPet(double maxBubbleWidth) {
    final bubble = GestureDetector(
      onLongPress: onLongPressRemember,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAF0),
          border: Border.all(color: PetPalColors.line, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: PetPalColors.softShadow.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: _textStyle.copyWith(color: const Color(0xFF5B4734)),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showAvatar) ...[
              _PetAvatarBadge(
                role: role,
                avatarUrl: avatarUrl,
                avatarVariant: avatarVariant,
              ),
              const SizedBox(width: 7),
            ],
            Flexible(child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: bubble,
            )),
            if (message.remembered) ...[
              const SizedBox(width: 6),
              const Icon(Pixel.bookmark, size: 14, color: PetPalColors.honey),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUser(double maxBubbleWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [PetPalColors.amber, PetPalColors.honey]),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(6),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: _textStyle.copyWith(color: Colors.white),
                ),
              ),
              UserMessageStatus(message: message, onRetry: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small "Sending… / Failed · tap to retry" row under a user message.
/// Shared by the history bubble and the main-screen latest-message bubble.
class UserMessageStatus extends StatelessWidget {
  const UserMessageStatus({required this.message, this.onRetry, super.key});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (message.status) {
      case ChatStatus.sending:
        return const Padding(
          padding: EdgeInsets.only(top: 3, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 9,
                height: 9,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA8895E)),
                ),
              ),
              SizedBox(width: 5),
              Text(
                'Sending…',
                style: TextStyle(
                  color: Color(0xFFA8895E),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        );
      case ChatStatus.failed:
        return Padding(
          padding: const EdgeInsets.only(top: 3, right: 2),
          child: GestureDetector(
            onTap: onRetry,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Pixel.reload, size: 13, color: PetPalColors.heart),
                SizedBox(width: 4),
                Text(
                  'Failed · tap to retry',
                  style: TextStyle(
                    color: PetPalColors.heart,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      case ChatStatus.sent:
        return const SizedBox.shrink();
    }
  }
}

class _PetAvatarBadge extends StatelessWidget {
  const _PetAvatarBadge({
    required this.role,
    required this.avatarUrl,
    required this.avatarVariant,
  });

  final PresetRole role;
  final String? avatarUrl;
  final int avatarVariant;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
