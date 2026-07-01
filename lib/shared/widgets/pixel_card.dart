import 'package:flutter/material.dart';

import '../../core/theme/petpal_theme.dart';

class PixelCard extends StatelessWidget {
  const PixelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.selected = false,
    this.dark = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool selected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final fillDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const [Color(0xFF4A3324), Color(0xFF2C1D12)]
            : const [Color(0xFFFDF6E2), Color(0xFFF2E3BC)],
      ),
      border: Border.all(
        color: selected ? PetPalColors.honey : PetPalColors.line,
        width: selected ? 3 : 2,
      ),
      borderRadius: radius,
    );
    final shadowDecoration = BoxDecoration(
      borderRadius: radius,
      boxShadow: [
        BoxShadow(
          color:
              PetPalColors.softShadow.withValues(alpha: selected ? 0.42 : 0.22),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return Container(
      margin: margin,
      decoration: shadowDecoration,
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: fillDecoration,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
