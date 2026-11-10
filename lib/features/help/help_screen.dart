// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _platform = MethodChannel('hams/settings');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Keep Hams running')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Keep Hams running',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'For reliable sessions with the screen off, allow Hams to run in the background. Hams works offline and does not need internet access.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () =>
              _platform.invokeMethod<void>('openBatteryOptimization'),
          icon: const Icon(Icons.battery_saver_outlined),
          label: const Text('Open battery settings'),
        ),
        const SizedBox(height: 16),
        const _HelpSection(
          title: 'Battery and background access',
          body: 'Turn off battery optimization for Hams. If your phone offers an Auto-start, Background activity, or Unrestricted battery option, enable it for Hams.',
        ),
        const _HelpSection(
          title: 'Phone-specific tips',
          body: 'Samsung: allow background usage. Xiaomi, Redmi, and POCO: enable Auto-start and set Battery to No restrictions. Tecno, Infinix, and itel: allow Auto-start and background activity. Oppo, Realme, and OnePlus: allow Auto-launch and set Battery to Unrestricted. Vivo: allow Auto-start and high background power use. Huawei and Honor: enable Auto-launch and remove Hams from protected-app restrictions. Google Pixel and Motorola: choose Unrestricted battery usage.',
        ),
        const _HelpSection(
          title: 'Hotspot tips',
          body: 'Disable the hotspot auto-off timer. If a phone cannot find the hotspot, set its band to 2.4 GHz or enable Extended compatibility. If Android asks whether to stay connected without internet, choose Yes. Turn off VPN apps while connecting.',
        ),
        const _HelpSection(
          title: 'Phone calls',
          body: 'A call temporarily pauses audio. Audio resumes when the call ends; listeners can tap the resume control if automatic resume is unavailable.',
        ),
      ],
    ),
  );
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    ),
  );
}
