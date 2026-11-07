// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark }

enum ThemeSeed {
  blueberry('Blueberry', Color(0xFF4285F4)),
  poppy('Poppy', Color(0xFFEA4335)),
  meadow('Meadow', Color(0xFF34A853)),
  sunflower('Sunflower', Color(0xFFFBBC04)),
  mint('Mint', Color(0xFF00AC47)),
  lagoon('Lagoon', Color(0xFF00897B)),
  orchid('Orchid', Color(0xFF7248B9)),
  indigo('Indigo', Color(0xFF3F51B5)),
  rose('Rose', Color(0xFFE91E63)),
  tangerine('Tangerine', Color(0xFFFF6D00)),
  lime('Lime', Color(0xFFAFB42B)),
  sky('Sky', Color(0xFF00BCD4)),
  cocoa('Cocoa', Color(0xFF795548),
  ),
  slate('Slate', Color(0xFF607D8B)),
  coral('Coral', Color(0xFFFF7043)),
  lilac('Lilac', Color(0xFF9C27B0));

  const ThemeSeed(this.label, this.color);
  final String label;
  final Color color;
}

class AppTheme {
  static ThemeData build({
    required ThemeSeed seed,
    required Brightness brightness,
    bool amoled = false,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed.color,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );
    final dark = brightness == Brightness.dark;
    final colors = amoled && dark
        ? scheme.copyWith(surface: Colors.black, surfaceContainer: const Color(0xFF111111))
        : scheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: amoled && dark ? Colors.black : null,
      fontFamily: 'RobotoFlex',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}
