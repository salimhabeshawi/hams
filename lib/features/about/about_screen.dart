// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          Icon(Icons.waves, size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text('Hams', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Clear voice communication, offline.', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          const ListTile(title: Text('Free and open source'), subtitle: Text('GPL-3.0')),
          const ListTile(title: Text('No ads, no tracking'), subtitle: Text('Works offline')),
          const ListTile(title: Text('Source code'), subtitle: Text('Repository link will be added before release')),
          const ListTile(title: Text('Licenses'), subtitle: Text('Flutter and native library notices')),
        ]),
      );
}
