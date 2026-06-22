import 'package:flutter/material.dart';

import '../core/theme/petpal_theme.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/pet_room/pet_room_screen.dart';
import 'petpal_controller.dart';

class PetPalApp extends StatefulWidget {
  const PetPalApp({super.key});

  @override
  State<PetPalApp> createState() => _PetPalAppState();
}

class _PetPalAppState extends State<PetPalApp> {
  late final PetPalController controller;

  @override
  void initState() {
    super.initState();
    controller = PetPalController();
    controller.restore();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetPal',
      debugShowCheckedModeBanner: false,
      theme: PetPalTheme.light(),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (!controller.isReady) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.currentPet != null) {
            return PetRoomScreen(controller: controller);
          }
          return WelcomeScreen(controller: controller);
        },
      ),
    );
  }
}
