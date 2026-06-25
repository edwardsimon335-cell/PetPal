import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/page_transitions.dart';
import '../../app/petpal_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/widgets/pixel_card.dart';
import '../../shared/widgets/pixel_page_scaffold.dart';
import '../character_library/character_library_screen.dart';
import '../upload_photo/upload_photo_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.controller, super.key});

  final PetPalController controller;

  @override
  Widget build(BuildContext context) {
    return PixelPageScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 34, 22, 24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 118,
              height: 118,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2CF),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: PetPalColors.line, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: PetPalColors.softShadow.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to PetPal',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Choose your companion',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            _EntryCard(
              icon: Pixel.camera,
              title: 'Upload My Pet Photo',
              subtitle: 'AI creates your own pixel pet',
              onTap: () {
                Navigator.of(context).push(
                  petPalRoute(
                    builder: (_) => UploadPhotoScreen(controller: controller),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child:
                        Container(height: 2, color: const Color(0x887C5A30))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: PetPalColors.cocoa,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Expanded(
                    child:
                        Container(height: 2, color: const Color(0x887C5A30))),
              ],
            ),
            const SizedBox(height: 14),
            _EntryCard(
              icon: Pixel.grid,
              title: 'Choose from Character Library',
              subtitle: 'Pick one of 6 crafted companions',
              onTap: () {
                Navigator.of(context).push(
                  petPalRoute(
                    builder: (_) =>
                        CharacterLibraryScreen(controller: controller),
                  ),
                );
              },
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFF7E8C2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8B87F), width: 2),
            ),
            child: Icon(icon, color: PetPalColors.honey, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9A7544),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Pixel.chevronright, color: PetPalColors.cocoa, size: 28),
        ],
      ),
    );
  }
}
