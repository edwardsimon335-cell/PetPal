import 'package:flutter/material.dart';

import 'preset_role.dart';

enum PetSourceType { uploadedPhoto, presetRole }

class PetProfile {
  PetProfile({
    required this.name,
    required this.sourceType,
    required this.traits,
    required this.role,
    this.specialPersonalityDetail = '',
    this.sourcePhotoPath,
    this.remotePetId,
    this.avatarUrl,
    this.avatarVariant = 0,
    this.generationStatus = 'none',
    this.mood = 72,
    this.hunger = 95,
    this.cleanliness = 92,
    this.statusText = 'Feeling cozy',
    DateTime? createdAt,
    DateTime? lastActiveAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

  String name;
  PetSourceType sourceType;
  List<String> traits;
  PresetRole role;
  String specialPersonalityDetail;
  String? sourcePhotoPath;
  String? remotePetId;
  String? avatarUrl;
  int avatarVariant;
  String generationStatus;
  int mood;
  int hunger;
  int cleanliness;
  String statusText;
  DateTime createdAt;
  DateTime lastActiveAt;

  Color get bodyColor => role.body;
  Color get shadeColor => role.shade;
  Color get eyeColor => role.eye;
  Color get accentColor => role.accent;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sourceType': sourceType.name,
      'traits': traits,
      'roleId': role.id,
      'specialPersonalityDetail': specialPersonalityDetail,
      'sourcePhotoPath': sourcePhotoPath,
      'remotePetId': remotePetId,
      'avatarUrl': avatarUrl,
      'avatarVariant': avatarVariant,
      'generationStatus': generationStatus,
      'mood': mood,
      'hunger': hunger,
      'cleanliness': cleanliness,
      'statusText': statusText,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  factory PetProfile.fromJson(
    Map<String, dynamic> json, {
    required PresetRole role,
  }) {
    final sourceName =
        json['sourceType'] as String? ?? PetSourceType.presetRole.name;
    final sourceType = PetSourceType.values.firstWhere(
      (value) => value.name == sourceName,
      orElse: () => PetSourceType.presetRole,
    );

    return PetProfile(
      name: json['name'] as String? ?? role.name,
      sourceType: sourceType,
      traits: (json['traits'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      role: role,
      specialPersonalityDetail:
          json['specialPersonalityDetail'] as String? ?? '',
      sourcePhotoPath: json['sourcePhotoPath'] as String?,
      remotePetId: json['remotePetId'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      avatarVariant: json['avatarVariant'] as int? ?? 0,
      generationStatus: json['generationStatus'] as String? ?? 'none',
      mood: json['mood'] as int? ?? 72,
      hunger: json['hunger'] as int? ?? 95,
      cleanliness: json['cleanliness'] as int? ?? 92,
      statusText: json['statusText'] as String? ?? 'Feeling cozy',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt'] as String? ?? ''),
    );
  }
}
