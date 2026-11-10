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
  String? state;
  String? sessionId;
  String? title;
  String? speakerName;
  int? listenerCount;
  int? maxListeners;
  bool? networkReady;
  bool? headphonesConnected;
  double? level;
  String? reason;
}

class SpeakerAnnouncement {
  String? sessionId;
  String? deviceId;
  String? name;
  String? title;
  bool? pinRequired;
  int? listeners;
  int? maxListeners;
  int? tcpPort;
  int? udpPort;
  String? state;
  String? address;
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
