import 'package:flutter/material.dart';

import '../core/theme/petpal_theme.dart';
import '../features/onboarding/welcome_screen.dart';
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
      home: WelcomeScreen(controller: controller),
    );
  }
}
