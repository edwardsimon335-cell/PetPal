import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../../core/constants/app_assets.dart';
import '../../../shared/models/petpal_v12_models.dart';

class RoomItemGlyph extends StatelessWidget {
  const RoomItemGlyph({
    required this.itemId,
    this.size = 48,
    this.dimmed = false,
    super.key,
  });

  final String itemId;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final asset = AppAssets.roomItemAssetFor(itemId);
    if (asset != null) {
      return Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
        ),
      );
    }

    final color = colorForStableId(itemId);
    final iconColor =
        Color.alphaBlend(Colors.black.withValues(alpha: 0.34), color);
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor, width: 2),
          ),
          child: CustomPaint(
            painter: _PixelItemPainter(itemId: itemId, color: color),
            child:
                Icon(_iconFor(itemId), size: size * 0.42, color: Colors.white),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String id) {
    if (id.contains('food')) return Pixel.coffee;
    if (id.contains('blanket')) return Pixel.heart;
    if (id.contains('ball')) return Pixel.moodhappy;
    if (id.contains('window')) return Pixel.sliders2;
    return Pixel.edit;
  }
}

class _PixelItemPainter extends CustomPainter {
  const _PixelItemPainter({required this.itemId, required this.color});

  final String itemId;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final shade = Color.alphaBlend(Colors.black.withValues(alpha: 0.20), color);
    paint.color = shade.withValues(alpha: 0.6);
    canvas.drawRect(
      Rect.fromLTWH(
          size.width * 0.12, size.height * 0.72, size.width * 0.76, 4),
      paint,
    );
    paint.color = Colors.white.withValues(alpha: 0.20);
    canvas.drawRect(
      Rect.fromLTWH(
          size.width * 0.18, size.height * 0.16, size.width * 0.22, 4),
      paint,
    );
    if (itemId.contains('window')) {
      canvas.drawRect(
        Rect.fromLTWH(
            size.width * 0.62, size.height * 0.16, 4, size.height * 0.38),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PixelItemPainter oldDelegate) {
    return oldDelegate.itemId != itemId || oldDelegate.color != color;
  }
}
