import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petpal/app/app.dart';

void main() {
  testWidgets('shows the PetPal welcome flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PetPalApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to PetPal'), findsOneWidget);
    expect(find.text('Upload My Pet Photo'), findsOneWidget);
    expect(find.text('Choose from Character Library'), findsOneWidget);
  });
}
