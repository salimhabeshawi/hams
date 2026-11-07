// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/engine.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/org/hams/app/EngineApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'org.hams.app'),
  ),
)
class PingRequest {
  String? value;
}

class PingReply {
  String? value;
  String? version;
}

class EngineSnapshot {
  String state = 'idle';
  String? sessionId;
  String? title;
  String? speakerName;
  int listenerCount = 0;
  int maxListeners = 50;
  bool networkReady = false;
  bool headphonesConnected = false;
  double level = 0;
  String? reason;
}

class SpeakerAnnouncement {
  String sessionId = '';
  String deviceId = '';
  String name = '';
  String? title;
  bool pinRequired = false;
  int listeners = 0;
  int maxListeners = 50;
  int tcpPort = 41711;
  int udpPort = 41712;
  String state = 'live';
  String address = '';
}

@HostApi()
abstract class EngineApi {
  PingReply ping(PingRequest request);
  String version();
  EngineSnapshot snapshot();
  void startSpeaker(String deviceId, String name, String? title, String? pin, bool autoAccept);
  void stopSession();
  void discover();
  List<SpeakerAnnouncement> speakers();
  void connect(String address, int port, String? pin, String deviceId, String name);
  void cancelConnection();
  void respondToRequest(String deviceId, bool accept, bool alwaysAllow);
  void removeListener(String deviceId, bool block);
  void setMuted(bool muted);
  void setBoost(double boost);
}
