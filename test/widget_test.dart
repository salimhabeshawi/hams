// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:hams/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app launches into onboarding', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const HamsApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Hams'), findsOneWidget);
  });
}
