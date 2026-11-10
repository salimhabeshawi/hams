// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/persistence/app_preferences.dart';
import '../../core/ui/expressive_widgets.dart';
import '../../core/utils/adaptive.dart';
import '../../platform/engine.dart';

class ListenerScreen extends StatefulWidget {
  const ListenerScreen({required this.preferences, super.key});
  final AppPreferences preferences;

  @override
  State<ListenerScreen> createState() => _ListenerScreenState();
}

class _ListenerScreenState extends State<ListenerScreen> {
  final _engine = Engine();
  Timer? _timer;
  StreamSubscription<Map<Object?, Object?>>? _events;
  List<SpeakerAnnouncement> _speakers = <SpeakerAnnouncement>[];
  EngineSnapshot? _snapshot;
  double _boost = 2;
  bool _refreshing = false;
  bool _safetyAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
    _events = _engine.eventStream.listen((_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _events?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await _engine.discover();
      final speakers = await _engine.speakers();
      final snapshot = await _engine.snapshot();
      if (mounted) {
        setState(() {
          _speakers = speakers;
          _snapshot = snapshot;
        });
      }
    } on Object {
      if (mounted) {
        setState(
          () => _snapshot = EngineSnapshot(
            state: 'error',
            reason: 'Nearby speakers are unavailable',
          ),
        );
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _connect(SpeakerAnnouncement speaker) async {
    final pin = speaker.pinRequired == true ? await _askPin() : null;
    if (speaker.pinRequired == true && pin == null) return;
    try {
      await _engine.connect(
        address: speaker.address ?? '',
        port: speaker.tcpPort ?? 41711,
        pin: pin,
        deviceId: widget.preferences.deviceId,
        name: widget.preferences.deviceName,
      );
      await _refresh();
    } on Object {
      if (mounted) {
        setState(
          () => _snapshot = EngineSnapshot(
            state: 'error',
            reason: 'Could not connect. Check the PIN and try again.',
          ),
        );
      }
    }
  }

  Future<String?> _askPin() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Session PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final connected =
        _snapshot?.state == 'connected' || _snapshot?.state == 'paused';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listen'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh speakers',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AdaptiveTwoPane(
            primary: _buildDiscovery(context, connected),
            secondary: connected
                ? _buildSession(context)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscovery(BuildContext context, bool connected) {
    if (connected) return _buildSession(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text(
            'Nearby speakers',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (_speakers.isEmpty)
            ExpressiveEmptyState(
              title: _snapshot?.state == 'error'
                  ? 'Could not search'
                  : 'No speakers found',
              message:
                  _snapshot?.reason ??
                  'Make sure you are on the speaker’s hotspot.',
              icon: Icons.wifi_find_rounded,
              action: FilledButton.tonalIcon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ),
          ..._speakers.map(
            (speaker) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: AvatarBadge(
                    name: speaker.name ?? 'Speaker',
                    seed: (speaker.deviceId ?? '').hashCode,
                    size: 52,
                  ),
                  title: Text(speaker.name ?? 'Speaker'),
                  subtitle: Text(speaker.title ?? 'Live session'),
                  trailing: Icon(
                    speaker.pinRequired == true
                        ? Icons.lock_outline
                        : Icons.arrow_forward,
                  ),
                  onTap: () => _connect(speaker),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final headphones = _snapshot?.headphonesConnected == true;
    if (!headphones) return _buildHeadphoneBlock(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ColorBlockedCard(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Column(
            children: [
              AvatarBadge(
                name: _snapshot?.speakerName ?? 'Speaker',
                seed: (_snapshot?.sessionId ?? '').hashCode,
              ),
              const SizedBox(height: 12),
              Text(
                _snapshot?.speakerName ?? 'Connected',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(_snapshot?.title ?? 'Live session'),
              const SizedBox(height: 12),
              StatusChip(
                label: _snapshot?.state == 'paused' ? 'Speaker paused' : 'Live',
                icon: _snapshot?.state == 'paused'
                    ? Icons.pause_circle_outline
                    : Icons.graphic_eq,
              ),
              const SizedBox(height: 12),
              LevelBlob(
                level: _snapshot?.level ?? 0,
                label: 'Speaker audio level',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Boost ${(_boost * 100).round()}%',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: Slider(
            value: _boost,
            min: 1,
            max: 4,
            divisions: 6,
            label: '${(_boost * 100).round()}%',
            onChanged: (value) {
              setState(() => _boost = value);
              _engine.setBoost(value);
              if (value > 3 && !_safetyAcknowledged) {
                _showSafetyDialog();
              }
            },
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('100%'), Text('200%'), Text('300%'), Text('400%')],
        ),
        const SizedBox(height: 12),
        const StatusChip(
          label: 'Hearing safety: boost carefully',
          icon: Icons.hearing,
        ),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: () async {
            await _engine.cancelConnection();
            await _refresh();
          },
          icon: const Icon(Icons.link_off),
          label: const Text('Disconnect'),
        ),
      ],
    );
  }

  Future<void> _showSafetyDialog() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Protect your hearing'),
        content: const Text(
          'Boost above 300% can be very loud. Keep the volume comfortable '
          'and lower it if it feels harsh.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      setState(() => _safetyAcknowledged = true);
    }
  }

  Widget _buildHeadphoneBlock(BuildContext context) => Center(
    child: ColorBlockedCard(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.headphones, size: 64),
          const SizedBox(height: 16),
          Text(
            'Connect headphones',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Audio is silenced until allowed headphones are connected.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const StatusChip(
            label: 'Waiting for headphones',
            icon: Icons.volume_off_outlined,
          ),
        ],
      ),
    ),
  );
}
