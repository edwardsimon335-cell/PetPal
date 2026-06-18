import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/petpal_theme.dart';

class PixelPageScaffold extends StatelessWidget {
  const PixelPageScaffold({
    required this.child,
    this.useRoomBackground = true,
    this.overlay,
    super.key,
  });

  final Widget child;
  final bool useRoomBackground;
  final Gradient? overlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (useRoomBackground)
            Image.asset(AppAssets.roomScene, fit: BoxFit.cover)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF4E5C0), Color(0xFFE8C995)],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: overlay ??
                  LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.18),
                      PetPalColors.ink.withOpacity(0.16),
                    ],
                  ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
