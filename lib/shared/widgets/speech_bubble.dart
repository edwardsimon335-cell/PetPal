import 'package:flutter/material.dart';

import '../../core/theme/petpal_theme.dart';

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFAF0),
            border: Border.all(color: PetPalColors.line, width: 2),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: PetPalColors.softShadow.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5B4734),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: 0,
            ),
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
