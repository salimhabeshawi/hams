// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hams/core/theme/app_theme.dart';

void main() {
  test('all theme seeds produce readable primary colors', () {
    for (final seed in ThemeSeed.values) {
      for (final brightness in Brightness.values) {
        final theme = AppTheme.build(seed: seed, brightness: brightness);
        expect(
          ThemeData.estimateBrightnessForColor(theme.colorScheme.primary),
          isA<Brightness>(),
        );
        expect(
          theme.colorScheme.primary.computeLuminance(),
          isNot(equals(theme.colorScheme.surface.computeLuminance())),
        );
      }
    }
  });
}
