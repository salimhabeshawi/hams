// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/persistence/app_preferences.dart';
import '../../core/ui/expressive_widgets.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({required this.preferences, super.key});
  final AppPreferences preferences;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Hams'),
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
        IconButton(
          tooltip: 'About',
          onPressed: () => context.push('/about'),
          icon: const Icon(Icons.info_outline),
        ),
        IconButton(
          tooltip: 'Help',
          onPressed: () => context.push('/help'),
          icon: const Icon(Icons.help_outline),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      AvatarBadge(
                        name: preferences.deviceName,
                        seed: preferences.deviceId.hashCode,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          preferences.deviceName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/settings'),
                        child: const Text('Rename'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Choose your role',
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: constraints.maxWidth > 650
                        ? Row(
                            children: [
                              _RoleCard(
                                title: 'Speak',
                                subtitle: 'Share your voice with listeners',
                                icon: Icons.mic,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                onTap: () => context.push('/speak'),
                              ),
                              const SizedBox(width: 16),
                              _RoleCard(
                                title: 'Listen',
                                subtitle: 'Hear a nearby speaker',
                                icon: Icons.headphones,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                onTap: () => context.push('/listen'),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _RoleCard(
                                title: 'Speak',
                                subtitle: 'Share your voice with listeners',
                                icon: Icons.mic,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                onTap: () => context.push('/speak'),
                              ),
                              const SizedBox(height: 16),
                              _RoleCard(
                                title: 'Listen',
                                subtitle: 'Hear a nearby speaker',
                                icon: Icons.headphones,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                onTap: () => context.push('/listen'),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: ColorBlockedCard(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Semantics(
          button: true,
          label: title,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(subtitle, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
