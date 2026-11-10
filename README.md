# Hams

Hams is a free, open-source Android app for sending live voice over a local
Wi-Fi network. It is offline by design: there are no accounts, ads, analytics,
recordings, or outbound internet calls. Audio is sent from one phone to
connected phones and listeners must use headphones.

## Requirements

- Flutter stable and its matching Dart SDK
- Android SDK platform 37 and build-tools installed
- Android NDK `28.2.13676358`
- Java 17
- Android SDK tools on `PATH`

The project supports Android API 24 and the `armeabi-v7a`, `arm64-v8a`, and
`x86_64` ABIs. The application ID is `org.hams.app`, defined only in
[`android/app/build.gradle.kts`](android/app/build.gradle.kts). Change it
before the first public release.

## Build from a clean checkout

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.
The Android Gradle wrapper downloads the pinned Gradle dependencies when
needed. No network service is required by the app itself.

## Release signing

Never commit a keystore or `key.properties`. Generate a private keystore,
copy [`android/key.properties.example`](android/key.properties.example) to
`android/key.properties`, and replace every placeholder:

```sh
keytool -genkeypair -v -keystore hams-release-key.jks -alias hams \
  -keyalg RSA -keysize 2048 -validity 10000
cp android/key.properties.example android/key.properties
```

Set `storeFile` to the keystore path relative to the `android/` directory.
The release build enables R8 shrinking and uses
[`android/app/proguard-rules.pro`](android/app/proguard-rules.pro) to retain
Pigeon channel classes, JNI entry points, and foreground services.

## APK variants

Build one universal APK for sideloading:

```sh
flutter build apk --release
```

Build one APK per ABI:

```sh
flutter build apk --release --split-per-abi
```

Outputs are under `build/app/outputs/flutter-apk/`. The universal APK is
larger but is the simplest choice for manual installation. Use the ABI-specific
APK matching the device architecture when distributing smaller files.

## Troubleshooting

- **Flutter is not found:** add the Flutter SDK `bin` directory to `PATH`,
  then reopen the shell.
- **Android SDK or NDK missing:** install Android SDK platform 37 and NDK
  `28.2.13676358` in SDK Manager, then run `flutter doctor -v`.
- **Release signing fails:** verify all four values in
  `android/key.properties`, and ensure `storeFile` exists relative to
  `android/`.
- **No audio:** listeners require connected headphones. Reconnect them and
  check Android audio permissions and the selected route.
- **Phones cannot discover a session:** join the same local Wi-Fi or phone
  hotspot, accept Android's “stay connected without internet” prompt, disable
  VPN software, and try the 2.4 GHz hotspot band.
- **Background playback stops:** disable battery optimization for Hams and
  allow background/auto-start in the device manufacturer's battery settings.
- **Native build errors:** run `flutter clean`, `flutter pub get`, and retry.
  Confirm that the installed NDK matches the version above.

## License

Hams is licensed under GPL-3.0-or-later. See [`LICENSE`](LICENSE) and
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
