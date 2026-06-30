import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petpal/app/petpal_controller.dart';
import 'package:petpal/shared/models/pet_profile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PetPalController controllerWithPet() {
    final controller = PetPalController();
    controller.selectRole(controller.roles.first);
    controller.createPresetPet(name: 'Mochi', traits: const ['Foodie']);
    return controller;
  }

  test('new pets start with V1.1 status defaults', () {
    final controller = controllerWithPet();
    final pet = controller.currentPet!;

    expect(pet.mood, 100);
    expect(pet.hunger, 100);
    expect(pet.affinity, 0);
    expect(pet.affinityLevel, 1);
    expect(pet.mainState, PetMainState.happy);
  });

  test('feed applies V1.1 gain once, then respects cooldown', () {
    final controller = controllerWithPet();
    final pet = controller.currentPet!
      ..hunger = 40
      ..mood = 70;

    controller.feed();

    expect(pet.hunger, 75);
    expect(pet.mood, 73);
    expect(pet.feedEffectiveCountToday, 1);
    expect(pet.affinity, 1);
    expect(controller.latestBubble, 'Mochi looks much better after eating.');

    controller.feed();

    expect(pet.hunger, 75);
    expect(pet.mood, 73);
    expect(pet.feedEffectiveCountToday, 1);
    expect(controller.latestBubble, 'Mochi is still full right now.');
  });

  test('offline settlement caps duration and protects low values', () {
    final controller = controllerWithPet();
    final now = DateTime(2026, 6, 30, 12);
    final pet = controller.currentPet!
      ..mood = 35
      ..hunger = 35
      ..lastSettlementAt = now.subtract(const Duration(hours: 48))
      ..lastDailyResetDate = petLocalDateKey(now);

    controller.handleRoomEntry(now: now);

    expect(pet.hunger, 30);
    expect(pet.mood, 30);
    expect(pet.lastSettlementAt, now);
  });

  test('chat mood gain has a daily cap and three valid chats add affinity',
      () async {
    final controller = controllerWithPet();
    final pet = controller.currentPet!
      ..mood = 40
      ..chatMoodGainToday = 28;

    await controller.sendMessage('first hello');
    await controller.sendMessage('second hello');
    await controller.sendMessage('third hello');

    expect(pet.chatMoodGainToday, 30);
    expect(pet.mood, 42);
    expect(pet.validChatCountToday, 3);
    expect(pet.affinity, 1);
    expect(pet.dailyChatAffinityDone, isTrue);
  });
}
