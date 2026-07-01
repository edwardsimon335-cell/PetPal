import 'dart:math' as math;

import '../shared/models/pet_profile.dart';
import '../shared/models/petpal_v12_models.dart';

class OfflineEventEngine {
  OfflineEventEngine({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  OfflineEventConfig? selectEvent({
    required PetProfile pet,
    required Duration offlineDuration,
    required DateTime now,
    required List<OfflineEventConfig> events,
    required List<MomentConfig> moments,
    required List<UserMomentRecord> savedMoments,
    required List<OfflineEventHistory> history,
  }) {
    final offlineMinutes = offlineDuration.inMinutes;
    final petType = petTypeForSpecies(pet.role.species);
    final currentWindow = timeWindowFor(now);
    final savedActiveMomentIds = savedMoments
        .where((record) => !record.isDeleted)
        .map((record) => record.momentId)
        .toSet();
    final shownToday = pet.shownEventIdsToday.toSet();
    final today = petLocalDateKey(now);
    final eventIdsEver = history.map((item) => item.eventId).toSet();

    final weighted = <_WeightedEvent>[];
    for (final event in events) {
      if (!event.enabled || event.archived) continue;
      if (!petTypeMatches(event.petType, petType)) continue;
      if (offlineMinutes < event.offlineMinMinutes) continue;
      final max = event.offlineMaxMinutes;
      if (max != null && offlineMinutes > max) continue;
      if (!_inRange(pet.mood, event.moodMin, event.moodMax)) continue;
      if (!_inRange(pet.hunger, event.hungerMin, event.hungerMax)) continue;
      if (pet.affinityLevel < event.affinityMinLevel) continue;
      if (!_windowMatches(event.timeWindow, currentWindow)) continue;
      if (shownToday.contains(event.eventId)) continue;
      if (event.oncePerPet && eventIdsEver.contains(event.eventId)) continue;
      final requiredItem = event.requiredItem;
      if (requiredItem != null && !pet.placedItemIds.contains(requiredItem)) {
        continue;
      }
      if (event.canUnlockMoment) {
        final momentId = event.momentId;
        if (momentId == null) continue;
        final moment = _findMoment(moments, momentId);
        if (moment == null || !moment.enabled || moment.archived) continue;
        if (!petTypeMatches(moment.petType, petType)) continue;
        if (savedActiveMomentIds.contains(momentId)) {
          // V1.2 stores each pet+moment once. Deleted records can be saved again.
          continue;
        }
        if (_momentWasUnlockedToday(momentId, today, history, events)) {
          continue;
        }
      }

      final weight = _weightFor(event, pet, currentWindow);
      if (weight > 0) weighted.add(_WeightedEvent(event, weight));
    }

    if (weighted.isEmpty) return null;
    final total = weighted.fold<int>(0, (sum, item) => sum + item.weight);
    var pick = _random.nextInt(total);
    for (final item in weighted) {
      if (pick < item.weight) return item.event;
      pick -= item.weight;
    }
    return weighted.last.event;
  }

  static String timeWindowFor(DateTime now) {
    final hour = now.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  int _weightFor(
    OfflineEventConfig event,
    PetProfile pet,
    String currentWindow,
  ) {
    var weight = event.baseWeight.toDouble();
    final traits = pet.traits.map((trait) => trait.toLowerCase()).toSet();
    final hasTraitMatch = event.personalityTags
        .map((trait) => trait.toLowerCase())
        .any(traits.contains);
    if (hasTraitMatch) weight *= 1.3;
    if (event.requiredItem != null &&
        pet.placedItemIds.contains(event.requiredItem)) {
      weight *= 1.5;
    }
    var relatedBonus = 0;
    for (final itemId in event.relatedItems) {
      if (pet.placedItemIds.contains(itemId)) {
        relatedBonus += event.itemWeightBonus;
      }
    }
    weight += relatedBonus.clamp(0, event.itemWeightBonus * 3);
    if (_windowMatches(event.preferredTimeWindow, currentWindow)) {
      weight *= 1.2;
    }
    if (pet.hunger < 50 && event.eventType == 'food') weight *= 1.4;
    if (pet.mood >= 80 &&
        (event.eventType == 'play' || event.eventType == 'mood')) {
      weight *= 1.3;
    }
    if (pet.mood < 60 &&
        (event.eventType == 'wait' || event.eventType == 'mood')) {
      weight *= 1.3;
    }
    return weight.round().clamp(1, 10000).toInt();
  }

  bool _inRange(int value, int? min, int? max) {
    if (min != null && value < min) return false;
    if (max != null && value > max) return false;
    return true;
  }

  bool _windowMatches(List<String> windows, String currentWindow) {
    return windows.isEmpty ||
        windows.contains('all') ||
        windows.contains(currentWindow);
  }

  MomentConfig? _findMoment(List<MomentConfig> moments, String momentId) {
    for (final moment in moments) {
      if (moment.momentId == momentId) return moment;
    }
    return null;
  }

  bool _momentWasUnlockedToday(
    String momentId,
    String today,
    List<OfflineEventHistory> history,
    List<OfflineEventConfig> events,
  ) {
    for (final item in history) {
      if (!item.momentSaved || petLocalDateKey(item.triggeredAt) != today) {
        continue;
      }
      final sourceEvent =
          events.where((event) => event.eventId == item.eventId);
      if (sourceEvent.isNotEmpty && sourceEvent.first.momentId == momentId) {
        return true;
      }
    }
    return false;
  }
}

class _WeightedEvent {
  const _WeightedEvent(this.event, this.weight);

  final OfflineEventConfig event;
  final int weight;
}
