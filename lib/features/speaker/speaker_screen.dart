// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/persistence/app_preferences.dart';
import '../../core/ui/expressive_widgets.dart';
import '../../core/utils/adaptive.dart';
import '../../platform/engine.dart';

class SpeakerScreen extends StatefulWidget {
  const SpeakerScreen({required this.preferences, super.key});
  final AppPreferences preferences;

  @override
  State<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends State<SpeakerScreen> {
  final _engine = Engine();
  final _title = TextEditingController();
  final _pin = TextEditingController();
  Timer? _timer;
  StreamSubscription<Map<Object?, Object?>>? _events;
  EngineSnapshot? _snapshot;
  bool _autoAccept = false;
  bool _pinEnabled = false;
  bool _muted = false;
  bool _pushToTalk = false;
  bool _pttPressed = false;
  bool _starting = false;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    _events = _engine.eventStream.listen((_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _events?.cancel();
    _title.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final value = await _engine.snapshot();
      if (mounted) setState(() => _snapshot = value);
    } on Object {
      if (mounted && _snapshot == null) {
        setState(
          () =>
              _snapshot = EngineSnapshot(reason: 'Session status unavailable'),
        );
      }
    }
  }

  Future<void> _goLive() async {
    setState(() => _starting = true);
    try {
      await _engine.setNoiseReduction(widget.preferences.noiseReduction);
      await _engine.startSpeaker(
        deviceId: widget.preferences.deviceId,
        name: widget.preferences.deviceName,
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        pin: _pinEnabled ? _pin.text : null,
        autoAccept: _autoAccept,
      );
      _startedAt = DateTime.now();
      await _refresh();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  String get _elapsed {
    final started = _startedAt;
    if (started == null) return '00:00';
    final seconds = DateTime.now().difference(started).inSeconds;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final live = _snapshot?.state == 'live' || _snapshot?.state == 'paused';
    return Scaffold(
      appBar: AppBar(title: const Text('Speak')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AdaptiveTwoPane(
            primary: _buildMain(context, live),
            secondary: live
                ? _buildListeners(context)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildMain(BuildContext context, bool live) => ListView(
    padding: EdgeInsets.zero,
    children: [
      ColorBlockedCard(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Row(
          children: [
            AvatarBadge(
              name: widget.preferences.deviceName,
              seed: widget.preferences.deviceId.hashCode,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                live ? 'Live session' : 'Ready to speak',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (live)
              StatusChip(
                label:
                    '${_snapshot?.listenerCount ?? 0} / '
                    '${_snapshot?.maxListeners ?? 50}',
                icon: Icons.people_alt_outlined,
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (!live) _buildSetup(context) else _buildLiveControls(context),
      if (_snapshot?.reason != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ExpressiveEmptyState(
            title: 'Session unavailable',
            message: _snapshot!.reason!,
            icon: Icons.wifi_off_rounded,
            action: OutlinedButton(
              onPressed: _refresh,
              child: const Text('Try again'),
            ),
          ),
        ),
    ],
  );

  Widget _buildSetup(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StatusChip(
        label: _snapshot?.networkReady == false
            ? 'Network not ready'
            : 'Local network ready',
        icon: _snapshot?.networkReady == false ? Icons.wifi_off : Icons.wifi,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _title,
        maxLength: 24,
        decoration: const InputDecoration(
          labelText: 'Session title',
          prefixIcon: Icon(Icons.title),
        ),
      ),
      SwitchListTile(
        title: const Text('Use a PIN'),
        value: _pinEnabled,
        onChanged: (value) => setState(() => _pinEnabled = value),
      ),
      if (_pinEnabled)
        TextField(
          controller: _pin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: '4–6 digit PIN'),
        ),
      SwitchListTile(
        title: const Text('Auto-accept requests'),
        value: _autoAccept,
        onChanged: (value) => setState(() => _autoAccept = value),
      ),
      const SizedBox(height: 12),
      Semantics(
        button: true,
        label: 'Go live',
        child: FilledButton.icon(
          onPressed: _starting ? null : _goLive,
          icon: const Icon(Icons.mic),
          label: Text(_starting ? 'Starting…' : 'Go live'),
        ),
      ),
    ],
  );

  Widget _buildLiveControls(BuildContext context) => Column(
    children: [
      LevelBlob(level: _snapshot?.level ?? 0, label: 'Microphone level'),
      Text(
        _snapshot?.state == 'paused' ? 'Paused' : 'Streaming locally',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(_elapsed, semanticsLabel: 'Session duration $_elapsed'),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.tonalIcon(
            onPressed: () async {
              await _engine.setMuted(!_muted);
              if (mounted) setState(() => _muted = !_muted);
            },
            icon: Icon(_muted ? Icons.mic_off : Icons.mic),
            label: Text(_muted ? 'Unmute' : 'Mute'),
          ),
          FilterChip(
            label: const Text('Push to talk'),
            selected: _pushToTalk,
            onSelected: (value) => setState(() => _pushToTalk = value),
          ),
        ],
      ),
      if (_pushToTalk) ...[
        const SizedBox(height: 12),
        GestureDetector(
          onTapDown: (_) async {
            setState(() => _pttPressed = true);
            await _engine.setMuted(false);
          },
          onTapUp: (_) async {
            setState(() => _pttPressed = false);
            await _engine.setMuted(true);
          },
          onTapCancel: () async {
            setState(() => _pttPressed = false);
            await _engine.setMuted(true);
          },
          child: Card(
            color: _pttPressed
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: Text(_pttPressed ? 'Talking' : 'Hold to talk'),
              ),
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () async {
          await _engine.stopSession();
          _startedAt = null;
          await _refresh();
        },
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text('End session'),
      ),
    ],
  );

  Widget _buildListeners(BuildContext context) => ListView(
    padding: EdgeInsets.zero,
    children: [
      Text(
        'Requests',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const ExpressiveEmptyState(
        title: 'No requests yet',
        message: 'New connection requests will appear here.',
        icon: Icons.inbox_outlined,
      ),
      const SizedBox(height: 20),
      Text(
        'Listeners',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const ExpressiveEmptyState(
        title: 'No listeners connected',
        message: 'When someone connects, their status will appear here.',
        icon: Icons.people_outline,
      ),
    ],
  );
}
