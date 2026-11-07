// SPDX-License-Identifier: GPL-3.0-or-later
import 'engine.g.dart';

class Engine {
  Engine({EngineApi? api}) : _api = api ?? EngineApi();

  final EngineApi _api;

  Future<String> ping() async {
    final PingReply reply = await _api.ping(PingRequest(value: 'hello'));
    return reply.value ?? '';
  }

  Future<String> version() => _api.version();
}
