import 'package:flutter/material.dart';

import '../../core/theme/petpal_theme.dart';

class PixelButton extends StatelessWidget {
  const PixelButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.enabled = true,
    this.height = 56,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool secondary;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    final background = secondary
        ? const LinearGradient(colors: [Color(0xFFF8ECCA), Color(0xFFEFDBB4)])
        : LinearGradient(
            colors: active
                ? const [PetPalColors.amber, PetPalColors.honey]
                : const [Color(0xFFD8CDB8), Color(0xFFCFC1A7)],
          );
    final foreground = secondary ? PetPalColors.cocoa : Colors.white;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: background,
          borderRadius: BorderRadius.circular(16),
          border:
              secondary ? Border.all(color: PetPalColors.line, width: 2) : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: PetPalColors.softShadow.withValues(alpha: 0.34),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          onPressed: active ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: foreground,
            disabledForegroundColor: const Color(0xFF9D8F79),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: label.isEmpty
              ? icon ?? const SizedBox.shrink()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Flexible(child: Text(label, overflow: TextOverflow.fade)),
                  ],
                ),
        ),
      ),
    );
  }
}
