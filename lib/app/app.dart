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

class _PetPalAppState extends State<PetPalApp> with WidgetsBindingObserver {
  late final PetPalController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = PetPalController();
    controller.restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.onAppResumed();
    }
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
          late final Widget page;
          if (!controller.isReady) {
            page = const Scaffold(
              key: ValueKey('loading'),
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (controller.currentPet != null) {
            page = PetRoomScreen(
              key: const ValueKey('pet-room'),
              controller: controller,
            );
          } else {
            page = WelcomeScreen(
              key: const ValueKey('welcome'),
              controller: controller,
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: page,
          );
        },
      ),
    );
  }
}
