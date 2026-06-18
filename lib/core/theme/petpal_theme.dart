import 'package:flutter/material.dart';

class PetPalColors {
  const PetPalColors._();

  static const ink = Color(0xFF2C1D12);
  static const bark = Color(0xFF5B3D1D);
  static const cocoa = Color(0xFF7C5A30);
  static const tan = Color(0xFFF7E8C2);
  static const cream = Color(0xFFFBF2D6);
  static const honey = Color(0xFFE7901F);
  static const amber = Color(0xFFF3A94E);
  static const line = Color(0xFFCBA368);
  static const blue = Color(0xFF3F97DF);
  static const heart = Color(0xFFE0533B);
  static const softShadow = Color(0x663C2612);
}

class PetPalTheme {
  const PetPalTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PetPalColors.honey,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: PetPalColors.tan,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: PetPalColors.bark,
          height: 1.05,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: PetPalColors.bark,
          height: 1.1,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: PetPalColors.bark,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: PetPalColors.cocoa,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
