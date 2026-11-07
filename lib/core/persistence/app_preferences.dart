// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../identity/name_generator.dart';

class AppPreferences {
  AppPreferences(this._prefs);
  final SharedPreferences _prefs;
  static Future<AppPreferences> load() async => AppPreferences(await SharedPreferences.getInstance());
  String get deviceId => _prefs.getString('deviceId') ?? _newDeviceId();
  String _newDeviceId() {
    final id = const Uuid().v4();
    _prefs.setString('deviceId', id);
    return id;
  }
  String get deviceName => _prefs.getString('deviceName') ?? _newName();
  String _newName() {
    final name = NameGenerator().generate();
    _prefs.setString('deviceName', name);
    return name;
  }
  Future<void> setDeviceName(String name) async => _prefs.setString('deviceName', NameValidator.normalize(name));
  ThemeSeed get themeSeed => ThemeSeed.values.firstWhere((s) => s.name == _prefs.getString('themeSeed'), orElse: () => ThemeSeed.blueberry);
  Future<void> setThemeSeed(ThemeSeed value) async => _prefs.setString('themeSeed', value.name);
  AppThemeMode get themeMode => AppThemeMode.values.firstWhere((m) => m.name == _prefs.getString('themeMode'), orElse: () => AppThemeMode.system);
  Future<void> setThemeMode(AppThemeMode value) async => _prefs.setString('themeMode', value.name);
  bool get amoled => _prefs.getBool('amoled') ?? false;
  Future<void> setAmoled(bool value) async => _prefs.setBool('amoled', value);
  bool get haptics => _prefs.getBool('haptics') ?? true;
  Future<void> setHaptics(bool value) async => _prefs.setBool('haptics', value);
  bool get onboardingDone => _prefs.getBool('onboardingDone') ?? false;
  Future<void> setOnboardingDone() async => _prefs.setBool('onboardingDone', true);
}
