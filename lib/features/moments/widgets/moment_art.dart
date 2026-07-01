import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../../shared/models/petpal_v12_models.dart';

class MomentArt extends StatelessWidget {
  const MomentArt({
    required this.id,
    required this.title,
    this.imageUrl,
    this.compact = false,
    super.key,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && _looksLikeImageReference(url)) {
      return AspectRatio(
        aspectRatio: compact ? 1.25 : 1.55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url.startsWith('assets/'))
                Image.asset(url, fit: BoxFit.cover)
              else
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (context, error, stackTrace) {
                    return _MomentPlaceholder(
                      id: id,
                      title: title,
                      compact: compact,
                    );
                  },
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.52),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 14 : 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _MomentPlaceholder(id: id, title: title, compact: compact);
  }

  bool _looksLikeImageReference(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('assets/');
  }
}

class _MomentPlaceholder extends StatelessWidget {
  const _MomentPlaceholder({
    required this.id,
    required this.title,
    required this.compact,
  });

  final String id;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = colorForStableId(id);
    final foreground =
        Color.alphaBlend(Colors.black.withValues(alpha: 0.42), color);
    return AspectRatio(
      aspectRatio: compact ? 1.25 : 1.55,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: foreground, width: 3),
          boxShadow: [
            BoxShadow(
              color: foreground.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _MomentArtPainter(color: color),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: compact ? 24 : 32,
                    height: compact ? 24 : 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconForId(id),
                      size: compact ? 15 : 20,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 14 : 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        shadows: const [
                          Shadow(
                            color: Color(0xAA000000),
                            offset: Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForId(String id) {
    if (id.contains('food') || id.contains('meal')) return Pixel.coffee;
    if (id.contains('dream') || id.contains('nap')) return Pixel.heart;
    if (id.contains('window') || id.contains('sun')) return Pixel.moodhappy;
    if (id.contains('toy') || id.contains('ball')) return Pixel.drop;
    return Pixel.heart;
  }
}

class _MomentArtPainter extends CustomPainter {
  const _MomentArtPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Color.alphaBlend(Colors.black.withValues(alpha: 0.24), color);
    final light = Color.alphaBlend(Colors.white.withValues(alpha: 0.34), color);
    final paint = Paint()..isAntiAlias = false;

    paint.color = light.withValues(alpha: 0.8);
    canvas.drawRect(
      Rect.fromLTWH(
          size.width * 0.08, size.height * 0.18, size.width * 0.26, 8),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
          size.width * 0.12, size.height * 0.28, size.width * 0.18, 8),
      paint,
    );

    paint.color = dark.withValues(alpha: 0.42);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.62, size.height * 0.24, size.width * 0.18,
          size.height * 0.35),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.57, size.height * 0.18, size.width * 0.28,
          size.height * 0.08),
      paint,
    );

    paint.color = Colors.white.withValues(alpha: 0.26);
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.18 + i * 0.13);
      final y = size.height * (0.48 + (i.isEven ? 0.0 : 0.08));
      canvas.drawRect(Rect.fromLTWH(x, y, 7, 7), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MomentArtPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
