// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/identity/name_generator.dart';
import '../../core/persistence/app_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/expressive_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.preferences, required this.onThemeChanged, super.key});
  final AppPreferences preferences;
  final VoidCallback onThemeChanged;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  late String name = widget.preferences.deviceName;
  late AppThemeMode mode = widget.preferences.themeMode;
  late bool amoled = widget.preferences.amoled;
  late bool haptics = widget.preferences.haptics;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Appearance', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: ThemeSeed.values.map((s) => Semantics(label: s.label, button: true, child: InkWell(onTap: () async { await widget.preferences.setThemeSeed(s); widget.onThemeChanged(); setState(() {}); }, child: CircleAvatar(radius: 22, backgroundColor: s.color, child: widget.preferences.themeSeed == s ? const Icon(Icons.check, color: Colors.white) : null)))).toList()),
      const SizedBox(height: 16),
      Row(children: [ConnectedChoice(value: AppThemeMode.light, groupValue: mode, label: 'Light', onChanged: _setMode), ConnectedChoice(value: AppThemeMode.system, groupValue: mode, label: 'System', onChanged: _setMode), ConnectedChoice(value: AppThemeMode.dark, groupValue: mode, label: 'Dark', onChanged: _setMode)]),
      SwitchListTile(title: const Text('AMOLED black'), subtitle: const Text('Use pure black surfaces in dark mode'), value: amoled && mode == AppThemeMode.dark, onChanged: mode == AppThemeMode.dark ? (v) async { await widget.preferences.setAmoled(v); setState(() => amoled = v); widget.onThemeChanged(); } : null),
      const Divider(height: 32),
      Text('Device', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      ListTile(leading: AvatarBadge(name: name, seed: widget.preferences.deviceId.hashCode, size: 48), title: Text(name), subtitle: const Text('Shown to nearby participants'), trailing: IconButton(tooltip: 'Rename', icon: const Icon(Icons.edit), onPressed: _rename)),
      TextButton.icon(onPressed: () async { final generated = NameGenerator().generate(); await widget.preferences.setDeviceName(generated); setState(() => name = generated); }, icon: const Icon(Icons.shuffle), label: const Text('Surprise me')),
      const Divider(height: 32),
      Text('Feedback', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      SwitchListTile(title: const Text('Haptics'), value: haptics, onChanged: (v) async { await widget.preferences.setHaptics(v); setState(() => haptics = v); }),
      const SwitchListTile(title: Text('Sounds'), value: true, onChanged: null),
      const Divider(height: 32),
      const ListTile(title: Text('Audio'), subtitle: Text('Microphone and listener options will be available when sessions are enabled.')),
      const ListTile(title: Text('Connection'), subtitle: Text('Auto-accept and trusted listeners will be available when sessions are enabled.')),
      ListTile(title: const Text('About'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/about')),
    ]),
  );
  Future<void> _setMode(AppThemeMode value) async { await widget.preferences.setThemeMode(value); setState(() => mode = value); widget.onThemeChanged(); }
  Future<void> _rename() async {
    final controller = TextEditingController(text: name);
    final result = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Rename device'), content: TextField(controller: controller, autofocus: true, maxLength: 24), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save'))]));
    if (result == null) return;
    final error = NameValidator.validate(result);
    if (error != null && mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))); return; }
    await widget.preferences.setDeviceName(result); if (mounted) setState(() => name = NameValidator.normalize(result));
  }
}
