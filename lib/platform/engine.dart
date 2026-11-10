// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/services.dart';

import 'engine.g.dart';

export 'engine.g.dart' show EngineSnapshot, SpeakerAnnouncement;

class Engine {
  Engine({EngineApi? api}) : _api = api ?? EngineApi();

  final EngineApi _api;
  static const EventChannel events = EventChannel('hams/events');
  Stream<Map<Object?, Object?>> get eventStream => events
      .receiveBroadcastStream()
      .where((value) => value is Map)
      .cast<Map<Object?, Object?>>()
      .map((value) => value.cast<Object?, Object?>());

  Future<String> ping() async {
    final PingReply reply = await _api.ping(PingRequest(value: 'hello'));
    return reply.value ?? '';
  }

  Future<String> version() => _api.version();

  Future<EngineSnapshot> snapshot() => _api.snapshot();

  Future<void> startSpeaker({
    required String deviceId,
    required String name,
    String? title,
    String? pin,
    required bool autoAccept,
  }) => _api.startSpeaker(deviceId, name, title, pin, autoAccept);

  Future<void> stopSession() => _api.stopSession();
  Future<void> discover() => _api.discover();
  Future<List<SpeakerAnnouncement>> speakers() => _api.speakers();

  Future<void> connect({
    required String address,
    required int port,
    String? pin,
    required String deviceId,
    required String name,
  }) => _api.connect(address, port, pin, deviceId, name);

  Future<void> cancelConnection() => _api.cancelConnection();
  Future<void> respondToRequest(
    String deviceId,
    bool accept,
    bool alwaysAllow,
  ) => _api.respondToRequest(deviceId, accept, alwaysAllow);
  Future<void> removeListener(String deviceId, bool block) =>
      _api.removeListener(deviceId, block);
  Future<void> setMuted(bool muted) => _api.setMuted(muted);
  Future<void> setBoost(double boost) => _api.setBoost(boost);

  Future<void> setNoiseReduction(bool enabled) =>
      const MethodChannel('hams/settings').invokeMethod<void>(
        'setNoiseReduction',
        <String, Object>{'enabled': enabled},
      );

  Future<Map<Object?, Object?>?> diagnosticsReport() async {
    final result = await const MethodChannel('hams/diagnostics')
        .invokeMethod<Object?>('report');
    return result is Map ? result.cast<Object?, Object?>() : null;
  }

  Future<void> setDeveloperTest({required bool loopback, required bool tone}) =>
      const MethodChannel('hams/diagnostics').invokeMethod<void>(
        'setDeveloperTest',
        <String, Object>{'loopback': loopback, 'tone': tone},
      );
}
