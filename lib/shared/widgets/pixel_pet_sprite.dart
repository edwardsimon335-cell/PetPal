import 'package:flutter/material.dart';

import '../models/preset_role.dart';

class PixelPetSprite extends StatelessWidget {
  const PixelPetSprite({
    required this.role,
    this.variant = 0,
    this.size = 148,
    super.key,
  });

  final PresetRole role;
  final int variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.16),
      painter: _PixelPetPainter(role: role, variant: variant),
    );
  }
}

class _PixelPetPainter extends CustomPainter {
  _PixelPetPainter({required this.role, required this.variant});

  final PresetRole role;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 128;
    final sy = size.height / 148;
    canvas.save();
    canvas.scale(sx, sy);
    final body = Paint()..color = role.body;
    final shade = Paint()..color = role.shade;
    final eye = Paint()..color = const Color(0xFF241A12);
    final gleam = Paint()..color = Colors.white;
    final accent = Paint()..color = role.accent;
    final chest = Paint()..color = role.chest ?? const Color(0xFFF3E6C8);

    RRect rr(double x, double y, double w, double h, double r) {
      return RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
    }

    canvas.drawRRect(rr(36, 128, 24, 16, 8), shade);
    canvas.drawRRect(rr(68, 128, 24, 16, 8), shade);
    canvas.drawRRect(rr(28, 80, 72, 58, 26), body);

    if (role.species.toLowerCase().contains('rabbit')) {
      canvas.drawRRect(rr(36, 0, 18, 50, 9), body);
      canvas.drawRRect(rr(74, 0, 18, 50, 9), body);
      canvas.drawRRect(rr(41, 6, 8, 38, 4), accent);
      canvas.drawRRect(rr(79, 6, 8, 38, 4), accent);
    } else if (role.species.toLowerCase().contains('dog')) {
      canvas.drawRRect(rr(12, 30, 26, 54, 13), shade);
      canvas.drawRRect(rr(90, 30, 26, 54, 13), shade);
      canvas.drawRRect(rr(18, 38, 13, 34, 6), accent);
      canvas.drawRRect(rr(97, 38, 13, 34, 6), accent);
    } else {
      final leftEar = Path()
        ..moveTo(30, 46)
        ..lineTo(40, 6)
        ..lineTo(62, 42)
        ..close();
      final rightEar = Path()
        ..moveTo(98, 46)
        ..lineTo(88, 6)
        ..lineTo(66, 42)
        ..close();
      canvas.drawPath(leftEar, shade);
      canvas.drawPath(rightEar, shade);
      canvas.drawPath(
        Path()
          ..moveTo(38, 42)
          ..lineTo(44, 18)
          ..lineTo(56, 40)
          ..close(),
        accent,
      );
      canvas.drawPath(
        Path()
          ..moveTo(90, 42)
          ..lineTo(84, 18)
          ..lineTo(72, 40)
          ..close(),
        accent,
      );
    }

    canvas.drawRRect(rr(22, 30, 84, 66, 30), body);
    canvas.drawRRect(rr(50, 92, 28, 46, 13), chest);

    if (role.tabby || variant.isOdd) {
      canvas.drawRRect(rr(60, 32, 8, 20, 3), shade);
      canvas.drawRRect(rr(48, 34, 6, 15, 3), shade);
      canvas.drawRRect(rr(74, 34, 6, 15, 3), shade);
      canvas.drawRRect(rr(34, 94, 20, 6, 3), shade);
      canvas.drawRRect(rr(34, 106, 15, 6, 3), shade);
    }

    canvas.drawRRect(rr(35, 70, 11, 6, 3), Paint()..color = const Color(0x66F0A0A0));
    canvas.drawRRect(rr(82, 70, 11, 6, 3), Paint()..color = const Color(0x66F0A0A0));
    canvas.drawRRect(rr(42, 52, 18, 23, 9), eye);
    canvas.drawRRect(rr(68, 52, 18, 23, 9), eye);
    canvas.drawRRect(rr(46, 57, 9, 11, 4), Paint()..color = role.eye);
    canvas.drawRRect(rr(72, 57, 9, 11, 4), Paint()..color = role.eye);
    canvas.drawRRect(rr(48, 55, 6, 6, 3), gleam);
    canvas.drawRRect(rr(74, 55, 6, 6, 3), gleam);
    canvas.drawPath(
      Path()
        ..moveTo(58, 75)
        ..lineTo(70, 75)
        ..lineTo(64, 82)
        ..close(),
      Paint()..color = role.accent,
    );

    final mouth = Paint()
      ..color = const Color(0xFF5B4326)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(52, 80, 12, 8), 0.1, 1.8, false, mouth);
    canvas.drawArc(Rect.fromLTWH(64, 80, 12, 8), 1.2, 1.8, false, mouth);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PixelPetPainter oldDelegate) {
    return oldDelegate.role != role || oldDelegate.variant != variant;
  }
}
