// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/identity/name_generator.dart';
import '../../core/persistence/app_preferences.dart';
import '../../core/ui/expressive_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.preferences, super.key});
  final AppPreferences preferences;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  var page = 0;
  late String name = widget.preferences.deviceName;
  final pages = const <(String, String, IconData)>[
    ('Welcome to Hams', 'Clear voice communication that works offline.', Icons.waves),
    ('Headphones matter', 'Listeners always use headphones to protect privacy and comfort.', Icons.headphones),
    ('Connect locally', 'Join the speaker’s hotspot. Hams does not need the internet.', Icons.wifi),
    ('Your device name', 'Choose a friendly name others can see.', Icons.badge),
    ('Ready when you are', 'Pick a role and start a session.', Icons.celebration),
  ];
  @override
  Widget build(BuildContext context) {
    final item = pages[page];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: page == 3 ? null : () => _finish(), child: const Text('Skip'))),
              Expanded(child: PageView.builder(controller: controller, onPageChanged: (value) => setState(() => page = value), itemCount: pages.length, itemBuilder: (_, index) => _OnboardingPage(data: pages[index], name: name, onName: (value) => setState(() => name = value)))),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(pages.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.all(4), width: i == page ? 28 : 8, height: 8, decoration: BoxDecoration(color: i == page ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(8))))),
              const SizedBox(height: 20),
              MorphingButton(onPressed: page == pages.length - 1 ? _finish : () => controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut), child: Text(page == pages.length - 1 ? 'Get started' : 'Continue', style: const TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _finish() async {
    final error = NameValidator.validate(name);
    if (error != null) { if (page == 3) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error))); return; }
    await widget.preferences.setDeviceName(name);
    await widget.preferences.setOnboardingDone();
    if (mounted) context.go('/');
  }
}

class _OnboardingPage extends StatefulWidget {
  const _OnboardingPage({required this.data, required this.name, required this.onName});
  final (String, String, IconData) data;
  final String name;
  final ValueChanged<String> onName;
  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage> {
  late final TextEditingController controller = TextEditingController(text: widget.name);
  @override
  void didUpdateWidget(covariant _OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && controller.text != widget.name) {
      controller.value = TextEditingValue(text: widget.name, selection: TextSelection.collapsed(offset: widget.name.length));
    }
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(widget.data.$3, size: 96, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 28),
    Text(widget.data.$1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 16),
    Text(widget.data.$2, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
    if (widget.data.$3 == Icons.badge) ...[
      const SizedBox(height: 24),
      TextField(key: const Key('onboarding-name'), controller: controller, onChanged: widget.onName, maxLength: 24, decoration: const InputDecoration(labelText: 'Device name')),
      TextButton(onPressed: () => widget.onName(NameGenerator().generate()), child: const Text('Surprise me')),
    ],
  ])));
}
