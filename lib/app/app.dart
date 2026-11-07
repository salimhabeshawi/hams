// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/persistence/app_preferences.dart';
import '../core/theme/app_theme.dart';
import '../features/about/about_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/role_select/role_select_screen.dart';
import '../features/settings/settings_screen.dart';

class HamsApp extends StatefulWidget {
  const HamsApp({super.key, this.preferences});
  final AppPreferences? preferences;
  @override
  State<HamsApp> createState() => _HamsAppState();
}

class _HamsAppState extends State<HamsApp> {
  late Future<AppPreferences> _preferences;
  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences == null
        ? AppPreferences.load()
        : Future<AppPreferences>.value(widget.preferences!);
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<AppPreferences>(
        future: _preferences,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
          }
          return _ThemedApp(preferences: snapshot.data!);
        },
      );
}

class _ThemedApp extends StatefulWidget {
  const _ThemedApp({required this.preferences});
  final AppPreferences preferences;
  @override
  State<_ThemedApp> createState() => _ThemedAppState();
}

class _ThemedAppState extends State<_ThemedApp> {
  late ThemeSeed seed = widget.preferences.themeSeed;
  late AppThemeMode mode = widget.preferences.themeMode;
  late bool amoled = widget.preferences.amoled;
  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: widget.preferences.onboardingDone ? '/' : '/onboarding',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => RoleSelectScreen(preferences: widget.preferences)),
        GoRoute(path: '/onboarding', builder: (_, _) => OnboardingScreen(preferences: widget.preferences)),
        GoRoute(path: '/settings', builder: (_, _) => SettingsScreen(preferences: widget.preferences, onThemeChanged: _refreshTheme)),
        GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
      ],
    );
    return MaterialApp.router(
      title: 'Hams',
      theme: AppTheme.build(seed: seed, brightness: Brightness.light),
      darkTheme: AppTheme.build(seed: seed, brightness: Brightness.dark, amoled: amoled),
      themeMode: mode == AppThemeMode.system ? ThemeMode.system : mode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
  void _refreshTheme() => setState(() {
        seed = widget.preferences.themeSeed;
        mode = widget.preferences.themeMode;
        amoled = widget.preferences.amoled;
      });
}
