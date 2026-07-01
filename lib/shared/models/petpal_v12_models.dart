import 'package:flutter/material.dart';

import 'pet_profile.dart';

enum MomentFilter { all, home, special }

String petTypeForSpecies(String species) {
  final lower = species.toLowerCase();
  if (lower.contains('dog') || lower.contains('corgi')) return 'dog';
  if (lower.contains('cat') || lower.contains('kitten')) return 'cat';
  return 'all';
}

bool petTypeMatches(String configType, String petType) {
  return configType == 'all' || configType == petType;
}

Color colorForStableId(String id) {
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  const palette = [
    Color(0xFFE7901F),
    Color(0xFF3F97DF),
    Color(0xFFE0533B),
    Color(0xFF5AA469),
    Color(0xFF9D74E8),
    Color(0xFFD18A4C),
  ];
  return palette[hash % palette.length];
}

class RoomItemConfig {
  const RoomItemConfig({
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.petType,
    required this.description,
    required this.unlockAffinityLevel,
    required this.defaultUnlocked,
    required this.displayOrder,
    required this.enabled,
    required this.archived,
    this.iconUrl,
    this.roomAssetUrl,
    this.defaultRoomAssetUrl,
    this.minAppVersion,
    this.maxAppVersion,
  });

  final String itemId;
  final String itemName;
  final String itemType;
  final String petType;
  final String? iconUrl;
  final String? roomAssetUrl;
  final String? defaultRoomAssetUrl;
  final String description;
  final int unlockAffinityLevel;
  final bool defaultUnlocked;
  final int displayOrder;
  final bool enabled;
  final bool archived;
  final String? minAppVersion;
  final String? maxAppVersion;

  bool supportsPet(PetProfile pet) =>
      petTypeMatches(petType, petTypeForSpecies(pet.role.species));

  bool isUnlocked(PetProfile pet) =>
      defaultUnlocked || pet.affinityLevel >= unlockAffinityLevel;

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'item_type': itemType,
      'pet_type': petType,
      'icon_url': iconUrl,
      'room_asset_url': roomAssetUrl,
      'default_room_asset_url': defaultRoomAssetUrl,
      'description': description,
      'unlock_affinity_level': unlockAffinityLevel,
      'default_unlocked': defaultUnlocked,
      'display_order': displayOrder,
      'enabled': enabled,
      'archived': archived,
      'min_app_version': minAppVersion,
      'max_app_version': maxAppVersion,
    };
  }
}

class OfflineEventConfig {
  const OfflineEventConfig({
    required this.eventId,
    required this.eventName,
    required this.eventType,
    required this.petType,
    required this.personalityTags,
    required this.relatedItems,
    required this.itemWeightBonus,
    required this.timeWindow,
    required this.preferredTimeWindow,
    required this.offlineMinMinutes,
    this.offlineMaxMinutes,
    this.moodMin,
    this.moodMax,
    this.hungerMin,
    this.hungerMax,
    required this.affinityMinLevel,
    required this.baseWeight,
    required this.rewardMood,
    required this.rewardHunger,
    required this.rewardAffinity,
    required this.canUnlockMoment,
    this.momentId,
    required this.oncePerPet,
    required this.titleTemplate,
    required this.bodyTemplate,
    required this.imageKey,
    required this.enabled,
    required this.archived,
    this.requiredItem,
    this.minAppVersion,
    this.maxAppVersion,
  });

  final String eventId;
  final String eventName;
  final String eventType;
  final String petType;
  final List<String> personalityTags;
  final String? requiredItem;
  final List<String> relatedItems;
  final int itemWeightBonus;
  final List<String> timeWindow;
  final List<String> preferredTimeWindow;
  final int offlineMinMinutes;
  final int? offlineMaxMinutes;
  final int? moodMin;
  final int? moodMax;
  final int? hungerMin;
  final int? hungerMax;
  final int affinityMinLevel;
  final int baseWeight;
  final int rewardMood;
  final int rewardHunger;
  final int rewardAffinity;
  final bool canUnlockMoment;
  final String? momentId;
  final bool oncePerPet;
  final String titleTemplate;
  final String bodyTemplate;
  final String imageKey;
  final bool enabled;
  final bool archived;
  final String? minAppVersion;
  final String? maxAppVersion;

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_name': eventName,
      'event_type': eventType,
      'pet_type': petType,
      'personality_tags': personalityTags,
      'required_item': requiredItem,
      'related_items': relatedItems,
      'item_weight_bonus': itemWeightBonus,
      'time_window': timeWindow,
      'preferred_time_window': preferredTimeWindow,
      'offline_min_minutes': offlineMinMinutes,
      'offline_max_minutes': offlineMaxMinutes,
      'mood_min': moodMin,
      'mood_max': moodMax,
      'hunger_min': hungerMin,
      'hunger_max': hungerMax,
      'affinity_min_level': affinityMinLevel,
      'base_weight': baseWeight,
      'reward_mood': rewardMood,
      'reward_hunger': rewardHunger,
      'reward_affinity': rewardAffinity,
      'can_unlock_moment': canUnlockMoment,
      'moment_id': momentId,
      'once_per_pet': oncePerPet,
      'title_template': titleTemplate,
      'body_template': bodyTemplate,
      'image_key': imageKey,
      'enabled': enabled,
      'archived': archived,
      'min_app_version': minAppVersion,
      'max_app_version': maxAppVersion,
    };
  }
}

class MomentConfig {
  const MomentConfig({
    required this.momentId,
    required this.title,
    required this.momentType,
    required this.diaryTemplate,
    required this.petType,
    required this.sourceType,
    required this.displayOrder,
    required this.enabled,
    required this.archived,
    this.imageUrl,
    this.thumbnailUrl,
    this.defaultImageUrl,
    this.minAppVersion,
    this.maxAppVersion,
  });

  final String momentId;
  final String title;
  final String momentType;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? defaultImageUrl;
  final String diaryTemplate;
  final String petType;
  final String sourceType;
  final int displayOrder;
  final bool enabled;
  final bool archived;
  final String? minAppVersion;
  final String? maxAppVersion;

  Map<String, dynamic> toJson() {
    return {
      'moment_id': momentId,
      'title': title,
      'moment_type': momentType,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'default_image_url': defaultImageUrl,
      'diary_template': diaryTemplate,
      'pet_type': petType,
      'source_type': sourceType,
      'display_order': displayOrder,
      'enabled': enabled,
      'archived': archived,
      'min_app_version': minAppVersion,
      'max_app_version': maxAppVersion,
    };
  }
}

class UserMomentRecord {
  UserMomentRecord({
    required this.momentRecordId,
    required this.momentId,
    required this.petId,
    required this.sourceEventId,
    required this.titleSnapshot,
    required this.diaryTextSnapshot,
    required this.imageUrlSnapshot,
    required this.momentTypeSnapshot,
    required this.createdAt,
    this.isFavorite = false,
    this.deletedAt,
  });

  final String momentRecordId;
  final String momentId;
  final String petId;
  final String sourceEventId;
  final String titleSnapshot;
  final String diaryTextSnapshot;
  final String imageUrlSnapshot;
  final String momentTypeSnapshot;
  final DateTime createdAt;
  bool isFavorite;
  DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'momentRecordId': momentRecordId,
      'momentId': momentId,
      'petId': petId,
      'sourceEventId': sourceEventId,
      'titleSnapshot': titleSnapshot,
      'diaryTextSnapshot': diaryTextSnapshot,
      'imageUrlSnapshot': imageUrlSnapshot,
      'momentTypeSnapshot': momentTypeSnapshot,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory UserMomentRecord.fromJson(Map<String, dynamic> json) {
    return UserMomentRecord(
      momentRecordId: json['momentRecordId'] as String? ?? '',
      momentId: json['momentId'] as String? ?? '',
      petId: json['petId'] as String? ?? '',
      sourceEventId: json['sourceEventId'] as String? ?? '',
      titleSnapshot: json['titleSnapshot'] as String? ?? 'Little Memory',
      diaryTextSnapshot: json['diaryTextSnapshot'] as String? ?? '',
      imageUrlSnapshot: json['imageUrlSnapshot'] as String? ?? '',
      momentTypeSnapshot: json['momentTypeSnapshot'] as String? ?? 'home',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
    );
  }
}

class MomentAsset {
  MomentAsset({
    required this.assetId,
    required this.momentId,
    required this.imageUrl,
    required this.sourceType,
    required this.createdAt,
    this.petId,
    this.roleId,
    this.thumbnailUrl,
    this.status = 'ready',
  });

  final String assetId;
  final String momentId;
  final String imageUrl;
  final String sourceType;
  final String? petId;
  final String? roleId;
  final String? thumbnailUrl;
  final String status;
  final DateTime createdAt;

  bool get isReady => status == 'ready' && imageUrl.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'momentId': momentId,
      'imageUrl': imageUrl,
      'sourceType': sourceType,
      'petId': petId,
      'roleId': roleId,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MomentAsset.fromJson(Map<String, dynamic> json) {
    return MomentAsset(
      assetId: json['assetId'] as String? ?? '',
      momentId: json['momentId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? 'ai',
      petId: json['petId'] as String?,
      roleId: json['roleId'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      status: json['status'] as String? ?? 'ready',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class PendingMomentEvent {
  PendingMomentEvent({
    required this.pendingId,
    required this.petId,
    required this.eventId,
    required this.momentId,
    required this.triggeredAt,
    required this.offlineDurationMinutes,
    required this.moodBefore,
    required this.hungerBefore,
    required this.affinityBefore,
    required this.placedItemIdsSnapshot,
    this.generationStatus = 'pending',
    this.generationTaskId,
    this.imageUrl,
    this.lastAttemptAt,
  });

  final String pendingId;
  final String petId;
  final String eventId;
  final String momentId;
  final DateTime triggeredAt;
  final int offlineDurationMinutes;
  final int moodBefore;
  final int hungerBefore;
  final int affinityBefore;
  final List<String> placedItemIdsSnapshot;
  String generationStatus;
  String? generationTaskId;
  String? imageUrl;
  DateTime? lastAttemptAt;

  bool get isReady => imageUrl != null && imageUrl!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'pendingId': pendingId,
      'petId': petId,
      'eventId': eventId,
      'momentId': momentId,
      'triggeredAt': triggeredAt.toIso8601String(),
      'offlineDurationMinutes': offlineDurationMinutes,
      'moodBefore': moodBefore,
      'hungerBefore': hungerBefore,
      'affinityBefore': affinityBefore,
      'placedItemIdsSnapshot': placedItemIdsSnapshot,
      'generationStatus': generationStatus,
      'generationTaskId': generationTaskId,
      'imageUrl': imageUrl,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    };
  }

  factory PendingMomentEvent.fromJson(Map<String, dynamic> json) {
    return PendingMomentEvent(
      pendingId: json['pendingId'] as String? ?? '',
      petId: json['petId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      momentId: json['momentId'] as String? ?? '',
      triggeredAt: DateTime.tryParse(json['triggeredAt'] as String? ?? '') ??
          DateTime.now(),
      offlineDurationMinutes: json['offlineDurationMinutes'] as int? ?? 0,
      moodBefore: json['moodBefore'] as int? ?? 0,
      hungerBefore: json['hungerBefore'] as int? ?? 0,
      affinityBefore: json['affinityBefore'] as int? ?? 0,
      placedItemIdsSnapshot:
          (json['placedItemIdsSnapshot'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
      generationStatus: json['generationStatus'] as String? ?? 'pending',
      generationTaskId: json['generationTaskId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      lastAttemptAt: DateTime.tryParse(json['lastAttemptAt'] as String? ?? ''),
    );
  }
}

class OfflineEventHistory {
  OfflineEventHistory({
    required this.historyId,
    required this.petId,
    required this.eventId,
    required this.eventType,
    required this.triggeredAt,
    required this.offlineDurationMinutes,
    required this.moodBefore,
    required this.hungerBefore,
    required this.affinityBefore,
    required this.moodAfter,
    required this.hungerAfter,
    required this.affinityAfter,
    required this.placedItemIdsSnapshot,
    this.momentSaved = false,
    this.momentRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? triggeredAt;

  final String historyId;
  final String petId;
  final String eventId;
  final String eventType;
  final DateTime triggeredAt;
  final int offlineDurationMinutes;
  final int moodBefore;
  final int hungerBefore;
  final int affinityBefore;
  final int moodAfter;
  final int hungerAfter;
  final int affinityAfter;
  final List<String> placedItemIdsSnapshot;
  bool momentSaved;
  String? momentRecordId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'historyId': historyId,
      'petId': petId,
      'eventId': eventId,
      'eventType': eventType,
      'triggeredAt': triggeredAt.toIso8601String(),
      'offlineDurationMinutes': offlineDurationMinutes,
      'moodBefore': moodBefore,
      'hungerBefore': hungerBefore,
      'affinityBefore': affinityBefore,
      'moodAfter': moodAfter,
      'hungerAfter': hungerAfter,
      'affinityAfter': affinityAfter,
      'placedItemIdsSnapshot': placedItemIdsSnapshot,
      'momentSaved': momentSaved,
      'momentRecordId': momentRecordId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OfflineEventHistory.fromJson(Map<String, dynamic> json) {
    return OfflineEventHistory(
      historyId: json['historyId'] as String? ?? '',
      petId: json['petId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      eventType: json['eventType'] as String? ?? 'special',
      triggeredAt: DateTime.tryParse(json['triggeredAt'] as String? ?? '') ??
          DateTime.now(),
      offlineDurationMinutes: json['offlineDurationMinutes'] as int? ?? 0,
      moodBefore: json['moodBefore'] as int? ?? 0,
      hungerBefore: json['hungerBefore'] as int? ?? 0,
      affinityBefore: json['affinityBefore'] as int? ?? 0,
      moodAfter: json['moodAfter'] as int? ?? 0,
      hungerAfter: json['hungerAfter'] as int? ?? 0,
      affinityAfter: json['affinityAfter'] as int? ?? 0,
      placedItemIdsSnapshot:
          (json['placedItemIdsSnapshot'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
      momentSaved: json['momentSaved'] as bool? ?? false,
      momentRecordId: json['momentRecordId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OfflineEventOccurrence {
  OfflineEventOccurrence({
    required this.config,
    required this.history,
    required this.title,
    required this.body,
    required this.rewardLabels,
    this.moment,
    this.imageKey,
    this.imageUrl,
  });

  final OfflineEventConfig config;
  final OfflineEventHistory history;
  final MomentConfig? moment;
  final String title;
  final String body;
  final List<String> rewardLabels;
  final String? imageKey;
  final String? imageUrl;

  bool get canSaveMoment =>
      config.canUnlockMoment && moment != null && !history.momentSaved;
}
