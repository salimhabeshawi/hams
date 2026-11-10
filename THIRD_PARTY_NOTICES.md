# Third-party notices

Hams is GPL-3.0-or-later. This file records the third-party components
distributed or linked by the Android application. Their upstream license text
and copyright notices remain applicable.

| Component | Use | License |
| --- | --- | --- |
| Flutter and Dart | UI framework and runtime | BSD-3-Clause |
| AndroidX and Kotlin | Android platform integration | Apache-2.0 |
| Oboe | Low-latency Android audio I/O | Apache-2.0 |
| libopus | Audio codec source vendored under `android/app/src/main/cpp/vendor` | BSD-3-Clause |
| `flutter_riverpod` | State management | MIT |
| `go_router` | Navigation | BSD-3-Clause |
| `shared_preferences` | Local preferences | BSD-3-Clause |
| `uuid` | UUID v4 identity generation | MIT |
| `permission_handler` | Runtime permission bridge | MIT |
| `package_info_plus` | App version display | BSD-3-Clause |
| `intl` | Localization support | BSD-3-Clause |
| `pigeon` | Typed Flutter/native channel generation | BSD-3-Clause |
| `flutter_lints`, `mocktail`, `flutter_launcher_icons`, `flutter_native_splash` | Development and packaging tools | BSD-3-Clause / MIT |

RNNoise is not enabled in the current release engine. If it is enabled in a
future release, its BSD-3-Clause notice must be added here with the vendored
source notice. Full license texts are supplied by the Flutter and Android
toolchains and by the package source distributions used to build the APK.
