import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../../app/petpal_controller.dart';
import '../../../core/theme/petpal_theme.dart';
import '../../../shared/models/chat_message.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../chat_history_sheet.dart';
import 'chat_bubble.dart';

/// Shown only in chat mode, just above the input row. Left: the chat-history
/// entry (sitting directly above the mode-switch button). Right: the user's
/// most recent message as a translucent bubble that fills the remaining width.
/// A transient "memory written" hint floats above and auto-dismisses.
class ChatDialogueArea extends StatefulWidget {
  const ChatDialogueArea({required this.controller, super.key});

  final PetPalController controller;

  @override
  State<ChatDialogueArea> createState() => _ChatDialogueAreaState();
}

class _ChatDialogueAreaState extends State<ChatDialogueArea> {
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (widget.controller.memoryHint != null && _hintTimer == null) {
      _hintTimer = Timer(const Duration(seconds: 3), () {
        _hintTimer = null;
        widget.controller.clearMemoryHint();
      });
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.currentPet == null) return const SizedBox.shrink();
    final lastUser = controller.lastUserMessage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.memoryHint != null)
          _MemoryHintPill(text: controller.memoryHint!),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Chat-history entry, stacked directly above the mode-switch button
            // in the input row below.
            SizedBox(
              width: 50,
              child: PixelButton(
                label: '',
                secondary: true,
                icon: const Icon(Pixel.bookmark, size: 20),
                onPressed: () => showChatHistorySheet(context, controller),
                height: 50,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: lastUser == null
                  ? const SizedBox(height: 50)
                  : _UserLatestBubble(
                      message: lastUser,
                      onRetry: () => controller.retryMessage(lastUser),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The user's latest message, filling the width to the right of the history
/// button (spec 2.2). Semi-transparent so the pet scene shows through.
class _UserLatestBubble extends StatelessWidget {
  const _UserLatestBubble({required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [PetPalColors.amber, PetPalColors.honey],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: PetPalColors.softShadow.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.28,
              letterSpacing: 0,
            ),
          ),
        ),
        UserMessageStatus(message: message, onRetry: onRetry),
      ],
    );
  }
}

class _MemoryHintPill extends StatelessWidget {
  const _MemoryHintPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: PetPalColors.ink.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFFBECCF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
