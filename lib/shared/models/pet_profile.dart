import 'package:flutter/material.dart';

import 'preset_role.dart';

enum PetSourceType { uploadedPhoto, presetRole }

enum MoodLevel { happy, calm, lonely, low }

enum HungerLevel { full, okay, hungry, veryHungry }

enum PetMainState { happy, calm, hungry, lonely }

String petLocalDateKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

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
    this.mood = 100,
    this.hunger = 100,
    this.cleanliness = 100,
    this.affinity = 0,
    this.statusText = 'Feeling cozy',
    DateTime? createdAt,
    DateTime? lastActiveAt,
    DateTime? lastSettlementAt,
    String? lastDailyResetDate,
    this.feedLastAt,
    this.caressLastAt,
    this.feedEffectiveCountToday = 0,
    this.caressEffectiveCountToday = 0,
    this.chatMoodGainToday = 0,
    this.validChatCountToday = 0,
    this.affinityGainToday = 0,
    this.returnTipShowCountToday = 0,
    this.offlineEventShowCountToday = 0,
    List<String>? shownEventIdsToday,
    List<String>? placedItemIds,
    this.dailyFirstFeedDone = false,
    this.dailyFirstCaressDone = false,
    this.dailyChatAffinityDone = false,
    this.dailyFirstReturnDone = false,
    this.lastOfflineEventAt,
    this.lastRoomItemUpdateAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now(),
        lastSettlementAt = lastSettlementAt ?? lastActiveAt ?? DateTime.now(),
        lastDailyResetDate =
            lastDailyResetDate ?? petLocalDateKey(DateTime.now()),
        shownEventIdsToday = shownEventIdsToday ?? <String>[],
        placedItemIds = placedItemIds ?? <String>[];

  static const feedCooldown = Duration(minutes: 90);
  static const caressCooldown = Duration(minutes: 10);

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
  int affinity;
  String statusText;
  DateTime createdAt;
  DateTime lastActiveAt;
  DateTime lastSettlementAt;
  String lastDailyResetDate;
  DateTime? feedLastAt;
  DateTime? caressLastAt;
  int feedEffectiveCountToday;
  int caressEffectiveCountToday;
  int chatMoodGainToday;
  int validChatCountToday;
  int affinityGainToday;
  int returnTipShowCountToday;
  int offlineEventShowCountToday;
  List<String> shownEventIdsToday;
  List<String> placedItemIds;
  bool dailyFirstFeedDone;
  bool dailyFirstCaressDone;
  bool dailyChatAffinityDone;
  bool dailyFirstReturnDone;
  DateTime? lastOfflineEventAt;
  DateTime? lastRoomItemUpdateAt;

  Color get bodyColor => role.body;
  Color get shadeColor => role.shade;
  Color get eyeColor => role.eye;
  Color get accentColor => role.accent;

  int get affinityLevel {
    if (affinity >= 30) return 5;
    if (affinity >= 14) return 4;
    if (affinity >= 7) return 3;
    if (affinity >= 3) return 2;
    return 1;
  }

  String get affinityLevelName {
    switch (affinityLevel) {
      case 5:
        return 'Best Buddy';
      case 4:
        return 'Trusted Friend';
      case 3:
        return 'Good Companion';
      case 2:
        return 'Getting Close';
      default:
        return 'New Friend';
    }
  }

  int? get nextAffinityRequirement {
    switch (affinityLevel) {
      case 1:
        return 3;
      case 2:
        return 7;
      case 3:
        return 14;
      case 4:
        return 30;
      default:
        return null;
    }
  }

  int get currentAffinityRequirement {
    switch (affinityLevel) {
      case 5:
        return 30;
      case 4:
        return 14;
      case 3:
        return 7;
      case 2:
        return 3;
      default:
        return 0;
    }
  }

  int get affinityProgressPercent {
    final next = nextAffinityRequirement;
    if (next == null) return 100;
    final base = currentAffinityRequirement;
    final span = next - base;
    if (span <= 0) return 100;
    return (((affinity - base) / span) * 100).clamp(0, 100).round();
  }

  MoodLevel get moodLevel {
    if (mood >= 80) return MoodLevel.happy;
    if (mood >= 60) return MoodLevel.calm;
    if (mood >= 30) return MoodLevel.lonely;
    return MoodLevel.low;
  }

  HungerLevel get hungerLevel {
    if (hunger >= 80) return HungerLevel.full;
    if (hunger >= 60) return HungerLevel.okay;
    if (hunger >= 30) return HungerLevel.hungry;
    return HungerLevel.veryHungry;
  }

  PetMainState get mainState {
    if (hunger < 50) return PetMainState.hungry;
    if (mood < 60) return PetMainState.lonely;
    if (hunger >= 80 && mood >= 80) return PetMainState.happy;
    return PetMainState.calm;
  }

  String get mainStateText {
    switch (mainState) {
      case PetMainState.happy:
        return '$name is feeling great today.';
      case PetMainState.calm:
        return '$name is enjoying a quiet moment.';
      case PetMainState.hungry:
        return '$name keeps looking at the bowl.';
      case PetMainState.lonely:
        return '$name missed you a little.';
    }
  }

  String get moodLevelText {
    switch (moodLevel) {
      case MoodLevel.happy:
        return 'Feeling happy';
      case MoodLevel.calm:
        return 'Feeling calm';
      case MoodLevel.lonely:
        return 'Missing you';
      case MoodLevel.low:
        return 'Needs some love';
    }
  }

  String get hungerLevelText {
    switch (hungerLevel) {
      case HungerLevel.full:
        return 'Full and cozy';
      case HungerLevel.okay:
        return 'Doing okay';
      case HungerLevel.hungry:
        return 'A little hungry';
      case HungerLevel.veryHungry:
        return 'Looking for food';
    }
  }

  Duration feedRemainingCooldown(DateTime now) {
    final last = feedLastAt;
    if (last == null) return Duration.zero;
    final remaining = feedCooldown - now.difference(last);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration caressRemainingCooldown(DateTime now) {
    final last = caressLastAt;
    if (last == null) return Duration.zero;
    final remaining = caressCooldown - now.difference(last);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isFeedInCooldown(DateTime now) =>
      feedRemainingCooldown(now) > Duration.zero;

  bool isCaressInCooldown(DateTime now) =>
      caressRemainingCooldown(now) > Duration.zero;

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
      'affinity': affinity,
      'affinityLevel': affinityLevel,
      'statusText': statusText,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'lastSettlementAt': lastSettlementAt.toIso8601String(),
      'lastDailyResetDate': lastDailyResetDate,
      'feedLastAt': feedLastAt?.toIso8601String(),
      'caressLastAt': caressLastAt?.toIso8601String(),
      'feedEffectiveCountToday': feedEffectiveCountToday,
      'caressEffectiveCountToday': caressEffectiveCountToday,
      'chatMoodGainToday': chatMoodGainToday,
      'validChatCountToday': validChatCountToday,
      'affinityGainToday': affinityGainToday,
      'returnTipShowCountToday': returnTipShowCountToday,
      'offlineEventShowCountToday': offlineEventShowCountToday,
      'shownEventIdsToday': shownEventIdsToday,
      'placedItemIds': placedItemIds,
      'dailyFirstFeedDone': dailyFirstFeedDone,
      'dailyFirstCaressDone': dailyFirstCaressDone,
      'dailyChatAffinityDone': dailyChatAffinityDone,
      'dailyFirstReturnDone': dailyFirstReturnDone,
      'lastOfflineEventAt': lastOfflineEventAt?.toIso8601String(),
      'lastRoomItemUpdateAt': lastRoomItemUpdateAt?.toIso8601String(),
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

    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final lastActiveAt =
        DateTime.tryParse(json['lastActiveAt'] as String? ?? '');

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
      mood: json['mood'] as int? ?? 100,
      hunger: json['hunger'] as int? ?? 100,
      cleanliness: json['cleanliness'] as int? ?? 100,
      affinity: json['affinity'] as int? ?? 0,
      statusText: json['statusText'] as String? ?? 'Feeling cozy',
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
      lastSettlementAt:
          DateTime.tryParse(json['lastSettlementAt'] as String? ?? '') ??
              lastActiveAt,
      lastDailyResetDate: json['lastDailyResetDate'] as String?,
      feedLastAt: DateTime.tryParse(json['feedLastAt'] as String? ?? ''),
      caressLastAt: DateTime.tryParse(json['caressLastAt'] as String? ?? ''),
      feedEffectiveCountToday: json['feedEffectiveCountToday'] as int? ?? 0,
      caressEffectiveCountToday: json['caressEffectiveCountToday'] as int? ?? 0,
      chatMoodGainToday: json['chatMoodGainToday'] as int? ?? 0,
      validChatCountToday: json['validChatCountToday'] as int? ?? 0,
      affinityGainToday: json['affinityGainToday'] as int? ?? 0,
      returnTipShowCountToday: json['returnTipShowCountToday'] as int? ?? 0,
      offlineEventShowCountToday:
          json['offlineEventShowCountToday'] as int? ?? 0,
      shownEventIdsToday:
          (json['shownEventIdsToday'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
      placedItemIds: (json['placedItemIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      dailyFirstFeedDone: json['dailyFirstFeedDone'] as bool? ?? false,
      dailyFirstCaressDone: json['dailyFirstCaressDone'] as bool? ?? false,
      dailyChatAffinityDone: json['dailyChatAffinityDone'] as bool? ?? false,
      dailyFirstReturnDone: json['dailyFirstReturnDone'] as bool? ?? false,
      lastOfflineEventAt:
          DateTime.tryParse(json['lastOfflineEventAt'] as String? ?? ''),
      lastRoomItemUpdateAt:
          DateTime.tryParse(json['lastRoomItemUpdateAt'] as String? ?? ''),
    );
  }
}
