import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petpal/app/petpal_controller.dart';
import 'package:petpal/features/pet_room/widgets/pet_stage.dart';
import 'package:petpal/features/pet_room/widgets/pet_sprite_view.dart';

void main() {
  testWidgets('NuoNuo renders the animated sprite stage without errors',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = PetPalController();
    controller
        .selectRole(controller.roles.firstWhere((role) => role.id == 'nuonuo'));
    controller.createPresetPet(name: 'NuoNuo', traits: const ['Quiet']);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [Positioned.fill(child: PetStage(controller: controller))],
          ),
        ),
      ),
    );

    // Advance the stage ticker a few frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(PetSpriteView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
