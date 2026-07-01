import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petpal/app/offline_event_engine.dart';
import 'package:petpal/app/petpal_controller.dart';
import 'package:petpal/shared/models/pet_profile.dart';
import 'package:petpal/shared/models/petpal_v12_models.dart';
import 'package:petpal/shared/repositories/petpal_v12_seed_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PetPalController controllerWithPet({
    int roleIndex = 0,
    PetPalV12SeedRepository seedRepository = const PetPalV12SeedRepository(),
  }) {
    final controller = PetPalController(seedRepository: seedRepository);
    controller.selectRole(controller.roles[roleIndex]);
    controller.createPresetPet(
      name: controller.roles[roleIndex].name,
      traits: controller.roles[roleIndex].defaultTraits,
    );
    return controller;
  }

  test('pet type matching does not route generic pets into cat or dog events',
      () {
    expect(petTypeMatches('all', 'cat'), isTrue);
    expect(petTypeMatches('cat', 'cat'), isTrue);
    expect(petTypeMatches('dog', 'all'), isFalse);
    expect(petTypeMatches('cat', 'dog'), isFalse);
  });

  test('offline event engine respects required room items', () {
    const seed = PetPalV12SeedRepository();
    final event =
        seed.offlineEvents().firstWhere((item) => item.eventId == 'toy_chase');
    final controller = controllerWithPet(roleIndex: 3); // Biscuit, a dog.
    final pet = controller.currentPet!
      ..createdAt = DateTime(2026, 6, 29, 12)
      ..lastSettlementAt = DateTime(2026, 6, 30, 9);
    final engine = OfflineEventEngine();

    final withoutToy = engine.selectEvent(
      pet: pet,
      offlineDuration: const Duration(hours: 3),
      now: DateTime(2026, 6, 30, 12),
      events: [event],
      moments: seed.moments(),
      savedMoments: const [],
      history: const [],
    );
    expect(withoutToy, isNull);

    pet.placedItemIds.add('toy_ball');
    final withToy = engine.selectEvent(
      pet: pet,
      offlineDuration: const Duration(hours: 3),
      now: DateTime(2026, 6, 30, 12),
      events: [event],
      moments: seed.moments(),
      savedMoments: const [],
      history: const [],
    );
    expect(withToy?.eventId, 'toy_chase');
  });

  test('moment event without an image queues generation and stays hidden', () {
    const seed = PetPalV12SeedRepository();
    final event = seed
        .offlineEvents()
        .firstWhere((item) => item.eventId == 'blanket_nap');
    final moment = seed.momentById('blanket_nap')!;
    final controller = controllerWithPet(
      seedRepository: SingleEventSeedRepository(event: event, moment: moment),
    );
    final now = DateTime(2026, 6, 30, 12);
    final pet = controller.currentPet!
      ..createdAt = now.subtract(const Duration(days: 1))
      ..lastSettlementAt = now.subtract(const Duration(hours: 3))
      ..lastDailyResetDate = petLocalDateKey(now)
      ..placedItemIds.add('soft_blanket');

    controller.handleRoomEntry(now: now);

    expect(controller.pendingAwayEvent, isNull);
    expect(controller.pendingMomentEvents, hasLength(1));
    expect(controller.offlineEventHistory, isEmpty);
    expect(pet.offlineEventShowCountToday, 0);
    expect(pet.shownEventIdsToday, isEmpty);
  });

  test('ready moment image allows pending event to display later', () {
    const seed = PetPalV12SeedRepository();
    final event = seed
        .offlineEvents()
        .firstWhere((item) => item.eventId == 'blanket_nap');
    final moment = seed.momentById('blanket_nap')!;
    final controller = controllerWithPet(
      seedRepository: SingleEventSeedRepository(event: event, moment: moment),
    );
    final now = DateTime(2026, 6, 30, 12);
    final pet = controller.currentPet!
      ..createdAt = now.subtract(const Duration(days: 1))
      ..lastSettlementAt = now.subtract(const Duration(hours: 3))
      ..lastDailyResetDate = petLocalDateKey(now)
      ..placedItemIds.add('soft_blanket');

    controller.handleRoomEntry(now: now);
    final pending = controller.pendingMomentEvents.single;
    controller.momentAssets.add(
      MomentAsset(
        assetId: 'asset-1',
        momentId: moment.momentId,
        petId: pending.petId,
        imageUrl: 'https://example.com/blanket_nap.png',
        sourceType: 'ai',
        createdAt: now,
      ),
    );

    controller.handleRoomEntry(now: now.add(const Duration(minutes: 5)));

    expect(controller.pendingAwayEvent, isNotNull);
    expect(controller.pendingAwayEvent!.imageUrl,
        'https://example.com/blanket_nap.png');
    expect(controller.pendingMomentEvents, isEmpty);
    expect(controller.offlineEventHistory, hasLength(1));
    expect(pet.offlineEventShowCountToday, 1);
  });

  test('saving a pending moment creates a record and delete soft-hides it',
      () async {
    const seed = PetPalV12SeedRepository();
    final controller = controllerWithPet();
    final pet = controller.currentPet!;
    final event = seed
        .offlineEvents()
        .firstWhere((item) => item.eventId == 'blanket_nap');
    final moment = seed.momentById('blanket_nap')!;
    final history = OfflineEventHistory(
      historyId: 'history-1',
      petId: 'local-test',
      eventId: event.eventId,
      eventType: event.eventType,
      triggeredAt: DateTime(2026, 6, 30, 12),
      offlineDurationMinutes: 180,
      moodBefore: pet.mood,
      hungerBefore: pet.hunger,
      affinityBefore: pet.affinity,
      moodAfter: pet.mood,
      hungerAfter: pet.hunger,
      affinityAfter: pet.affinity,
      placedItemIdsSnapshot: const ['soft_blanket'],
    );
    controller.offlineEventHistory.add(history);
    controller.pendingAwayEvent = OfflineEventOccurrence(
      config: event,
      history: history,
      moment: moment,
      title: 'A Blanket Nap',
      body: 'Mochi curled up on the soft blanket.',
      rewardLabels: const ['New Moment'],
      imageKey: 'blanket_nap',
      imageUrl: 'https://example.com/blanket_nap.png',
    );

    final record = await controller.savePendingMoment();

    expect(record, isNotNull);
    expect(controller.visibleMoments(), hasLength(1));
    expect(record!.imageUrlSnapshot, 'https://example.com/blanket_nap.png');
    expect(history.momentSaved, isTrue);

    await controller.deleteMoment(record);

    expect(record.isDeleted, isTrue);
    expect(controller.visibleMoments(), isEmpty);
  });
}

class SingleEventSeedRepository extends PetPalV12SeedRepository {
  const SingleEventSeedRepository({required this.event, required this.moment});

  final OfflineEventConfig event;
  final MomentConfig moment;

  @override
  List<OfflineEventConfig> offlineEvents() => [event];

  @override
  List<MomentConfig> moments() => [moment];

  @override
  MomentConfig? momentById(String id) => id == moment.momentId ? moment : null;
}
