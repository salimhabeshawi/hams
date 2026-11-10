// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hams/core/ui/expressive_widgets.dart';
import 'package:hams/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app launches into onboarding', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const HamsApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Hams'), findsOneWidget);
  });

  testWidgets('level visualizer exposes an accessible live value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LevelBlob(level: .75))),
    );
    expect(find.bySemanticsLabel('Audio level'), findsOneWidget);
    expect(find.text('75 percent'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state keeps failure guidance visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpressiveEmptyState(
            title: 'No speakers found',
            message: 'Join the local network and try again.',
            icon: Icons.wifi_find,
          ),
        ),
      ),
    );
    expect(find.text('No speakers found'), findsOneWidget);
    expect(find.text('Join the local network and try again.'), findsOneWidget);
  });
}
