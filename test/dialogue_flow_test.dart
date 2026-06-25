import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petpal/app/petpal_controller.dart';
import 'package:petpal/shared/models/chat_message.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PetPalController controllerWithPet() {
    final controller = PetPalController();
    controller.selectRole(controller.roles.first);
    controller.createPresetPet(name: 'Mochi', traits: const ['Sassy']);
    return controller;
  }

  test('sending a message records user + pet lines and resolves status',
      () async {
    final controller = controllerWithPet();

    await controller.sendMessage('hello there');

    expect(controller.messages.length, 2);
    final user = controller.messages[0];
    final pet = controller.messages[1];
    expect(user.role, ChatRole.user);
    expect(user.text, 'hello there');
    expect(user.status, ChatStatus.sent);
    expect(pet.role, ChatRole.pet);
    expect(controller.latestBubble, pet.text);
    expect(controller.petThinking, isFalse);
    expect(controller.chatBusy, isFalse);
  });

  test('rapid sends are queued and answered in order', () async {
    final controller = controllerWithPet();

    await Future.wait([
      controller.sendMessage('first'),
      controller.sendMessage('second'),
    ]);

    final userMessages =
        controller.messages.where((m) => m.isUser).map((m) => m.text).toList();
    expect(userMessages, ['first', 'second']);
    // Every user message is answered, so the history holds 2 pairs.
    expect(controller.messages.length, 4);
    expect(controller.messages.where((m) => m.isPet).length, 2);
  });

  test('feed produces a personality line that enters the record', () async {
    final controller = controllerWithPet();

    controller.feed();

    expect(controller.messages.length, 1);
    expect(controller.messages.single.isPet, isTrue);
    // Sassy feed line from the controller.
    expect(controller.latestBubble, 'Hmph. Acceptable. More?');
  });

  test('poking the pet reacts without recording or spending stats', () async {
    final controller = controllerWithPet();
    final moodBefore = controller.currentPet!.mood;

    controller.pokePet();

    expect(controller.messages, isEmpty);
    expect(controller.currentPet!.mood, moodBefore);
    expect(controller.latestBubble, isNotEmpty);
  });

  test('remembering a message flags it and shows a hint', () async {
    final controller = controllerWithPet();
    await controller.sendMessage('my favorite color is blue');
    final petMessage = controller.messages.firstWhere((m) => m.isPet);

    controller.rememberMessage(petMessage);

    expect(petMessage.remembered, isTrue);
    expect(controller.memoryHint, isNotNull);
  });
}
