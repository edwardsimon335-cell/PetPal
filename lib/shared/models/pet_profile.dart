import 'package:flutter/material.dart';

import 'preset_role.dart';

enum PetSourceType { uploadedPhoto, presetRole }

class PetProfile {
  PetProfile({
    required this.name,
    required this.sourceType,
    required this.traits,
    required this.role,
    this.avatarVariant = 0,
    this.generationStatus = 'none',
    this.mood = 72,
    this.hunger = 95,
    this.cleanliness = 92,
    this.statusText = 'Feeling cozy',
  });

  String name;
  PetSourceType sourceType;
  List<String> traits;
  PresetRole role;
  int avatarVariant;
  String generationStatus;
  int mood;
  int hunger;
  int cleanliness;
  String statusText;

  Color get bodyColor => role.body;
  Color get shadeColor => role.shade;
  Color get eyeColor => role.eye;
  Color get accentColor => role.accent;
}
