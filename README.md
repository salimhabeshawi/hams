# Hams

Hams is an offline Android app for sending voice over a local Wi-Fi network.
It has no accounts, ads, analytics, or outbound internet calls.

## Status

Phase 0 establishes the Flutter, Kotlin, C++/NDK, Pigeon, and CI foundations.

## Build

Install the latest stable Flutter SDK with Android SDK/NDK support, then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The application ID is `org.hams.app`, defined in
`android/app/build.gradle.kts`; change it before the first public release.
The release signing file is `android/key.properties` and is intentionally
ignored. Never commit signing keys.

For sideloading, `flutter build apk --release` produces a universal APK.
ABI-specific APKs can be produced with Flutter's `--split-per-abi` option.

## License

GPL-3.0-or-later. Native and package licenses are listed in
`THIRD_PARTY_NOTICES.md`.

A new Flutter project.
