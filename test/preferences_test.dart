// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hams/core/persistence/app_preferences.dart';
import 'package:hams/core/theme/app_theme.dart';

void main() {
  test('identity and appearance preferences survive reload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final first = await AppPreferences.load();
    final id = first.deviceId;
    await first.setDeviceName('Gentle Mango');
    await first.setThemeSeed(ThemeSeed.orchid);
    await first.setThemeMode(AppThemeMode.dark);
    final second = await AppPreferences.load();
    expect(second.deviceId, id);
    expect(second.deviceName, 'Gentle Mango');
    expect(second.themeSeed, ThemeSeed.orchid);
    expect(second.themeMode, AppThemeMode.dark);
  });
}
