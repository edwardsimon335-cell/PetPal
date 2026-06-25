import 'package:flutter/material.dart';

import '../../../app/petpal_controller.dart';
import '../../../core/theme/petpal_theme.dart';
import '../../../shared/widgets/typewriter_text.dart';
import 'thinking_dots.dart';

/// The pet's speech bubble, anchored just above the pet so its words appear to
/// come from it (spec 3.2 / 3.3 "气泡框跟随宠物的位置显示在其上方"). Shows the
/// thinking dots while composing, then reveals the reply with a typewriter
/// effect when [animated] (chat mode).
class PetSpeechBubble extends StatelessWidget {
  const PetSpeechBubble({
    required this.controller,
    this.animated = false,
    super.key,
  });

  final PetPalController controller;

  /// Animate thinking dots + typewriter (chat mode). In interaction mode the
  /// latest line is shown statically.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final showThinking = animated && controller.petThinking;
    final lastPet = controller.lastPetMessage;
    final text = lastPet?.text ?? controller.latestBubble;

    final Widget content;
    if (showThinking) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: ThinkingDots(),
      );
    } else {
      final isStreaming =
          animated && lastPet != null && lastPet.id == controller.streamingMessageId;
      content = TypewriterText(
        text: text,
        textAlign: TextAlign.center,
        animate: isStreaming,
        onCompleted:
            lastPet != null ? () => controller.markStreamed(lastPet.id) : null,
        style: const TextStyle(
          color: Color(0xFF5B4734),
          fontSize: 16,
          fontWeight: FontWeight.w800,
          height: 1.25,
          letterSpacing: 0,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFAF0),
            border: Border.all(color: PetPalColors.line, width: 2),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: PetPalColors.softShadow.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              content,
              // A faint paw print tucked into the corner for a little charm.
              if (!showThinking && text.isNotEmpty)
                const Positioned(
                  right: -8,
                  bottom: -8,
                  child: Opacity(
                    opacity: 0.32,
                    child: Text('🐾', style: TextStyle(fontSize: 15)),
                  ),
                ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(24, 12),
          painter: _BubbleTailPainter(),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()..color = PetPalColors.line;
    final fill = Paint()..color = const Color(0xFFFFFAF0);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, border);
    final inner = Path()
      ..moveTo(3, 0)
      ..lineTo(size.width - 3, 0)
      ..lineTo(size.width / 2, size.height - 3)
      ..close();
    canvas.drawPath(inner, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
