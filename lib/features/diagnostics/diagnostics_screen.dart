// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/persistence/app_preferences.dart';
import '../../platform/engine.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({required this.preferences, super.key});
  final AppPreferences preferences;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final Engine _engine = Engine();
  EngineSnapshot? _snapshot;
  Map<Object?, Object?>? _nativeReport;
  StreamSubscription<Map<Object?, Object?>>? _events;
  Timer? _timer;
  bool _developer = false;
  bool _loopback = false;
  bool _tone = false;
  int _versionTaps = 0;
  String? _copyStatus;

  @override
  void initState() {
    super.initState();
    _events = _engine.eventStream.listen((_) => _refresh());
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _events?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final snapshot = await _engine.snapshot();
      final report = await _engine.diagnosticsReport();
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _nativeReport = report;
        });
      }
    } on Object {
      // The report remains useful while the engine is unavailable.
    }
  }

  Map<String, Object?> _report() => <String, Object?>{
    'state': _snapshot?.state ?? 'unavailable',
    'session': _snapshot?.sessionId ?? 'none',
    'listenerCount':
        _nativeReport?['listenerCount'] ?? _snapshot?.listenerCount ?? 0,
    'maxListeners':
        _nativeReport?['maxListeners'] ?? _snapshot?.maxListeners ?? 50,
    'networkReady':
        _nativeReport?['networkReady'] ?? _snapshot?.networkReady ?? false,
    'headphonesConnected':
        _nativeReport?['headphonesConnected'] ??
        _snapshot?.headphonesConnected ??
        false,
    'bufferDepthMs': _nativeReport?['bufferDepthMs'] ?? 40,
    'estimatedLatencyMs': _nativeReport?['estimatedLatencyMs'] ?? 40,
    'packetLossPercent': _nativeReport?['packetLossPercent'] ?? 0,
    'jitterMs': _nativeReport?['jitterMs'] ?? 0,
    'codec':
        _nativeReport?['codec'] ?? 'Opus 48 kHz mono, 32 kbps constrained VBR',
    'noiseReduction': widget.preferences.noiseReduction,
  };

  Future<void> _copyReport() async {
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(_report()),
      ),
    );
    if (mounted) {
      setState(() => _copyStatus = 'Report copied without personal data');
    }
  }

  Future<void> _setDeveloper(bool enabled) async {
    setState(() => _developer = enabled);
    if (!enabled) {
      _loopback = false;
      _tone = false;
      await _engine.setDeveloperTest(loopback: false, tone: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MetricCard(
            label: 'Session',
            value: snapshot?.state ?? 'Unavailable',
          ),
          _MetricCard(
            label: 'Listeners',
            value:
                '${snapshot?.listenerCount ?? 0} / ${snapshot?.maxListeners ?? 50}',
          ),
          _MetricCard(
            label: 'Packet loss',
            value: '${_nativeReport?['packetLossPercent'] ?? 0}%',
          ),
          _MetricCard(
            label: 'Jitter / estimated latency',
            value:
                '${_nativeReport?['jitterMs'] ?? 0} ms / '
                '${_nativeReport?['estimatedLatencyMs'] ?? 40} ms',
          ),
          _MetricCard(
            label: 'Local interfaces',
            value:
                '${(_nativeReport?['localAddresses'] as List?)?.length ?? 0}',
          ),
          const ListTile(
            title: Text('Per-listener health'),
            subtitle: Text(
              'No listener metrics are available until a session is active.',
            ),
          ),
          ListTile(
            title: const Text('Copy report'),
            subtitle: Text(
              _copyStatus ?? 'Names and device identifiers are excluded',
            ),
            leading: const Icon(Icons.copy_all_outlined),
            onTap: _copyReport,
          ),
          GestureDetector(
            onTap: () {
              _versionTaps++;
              if (_versionTaps >= 7 && !_developer) _setDeveloper(true);
            },
            child: const ListTile(
              title: Text('Hams 1.0.0'),
              subtitle: Text('Tap seven times for developer tools'),
            ),
          ),
          if (_developer) ...[
            const Divider(height: 32),
            Text(
              'Developer tools',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SwitchListTile(
              title: const Text('Single-device loopback'),
              subtitle: const Text('Use the local engine path on 127.0.0.1'),
              value: _loopback,
              onChanged: (value) async {
                setState(() => _loopback = value);
                await _engine.setDeveloperTest(loopback: value, tone: _tone);
              },
            ),
            SwitchListTile(
              title: const Text('Test tone'),
              subtitle: const Text('Generate a bounded diagnostic tone'),
              value: _tone,
              onChanged: (value) async {
                setState(() => _tone = value);
                await _engine.setDeveloperTest(
                  loopback: _loopback,
                  tone: value,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
