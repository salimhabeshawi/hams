# Hams testing checklist

This document is the manual release checklist from the product specification.
Record the device, Android version, build identifier, date, and result for
each run. Do not copy real device names into reports; use the Hams display name.

## Automated checks

Run from the repository root:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
cd android && ./gradlew testDebugUnitTest
```

The automated suite covers generated-name rules and filtering, persisted
settings, theme seeds and modes, onboarding, expressive empty states, audio
packet authentication, jitter ordering, DSP limiting, and the Android platform
boundary. A release build additionally requires the private signing setup
described in the README.

## Manual release checklist

**Setup:** one speaker phone and three or four listener phones on a real local
network. Use generated or user-chosen Hams names only.

1. First launch onboarding; generate a random name; rename it; use “Surprise
   me”.
2. Verify the speaker guide detects the hotspot and listeners find the speaker
   through that hotspot.
3. Exercise request, accept, decline, cooldown, auto-accept, and always allow.
4. Verify correct PIN, wrong PIN, and lockout behavior.
5. Check audio quality with phone, wired headset, USB, and Bluetooth
   microphone modes.
6. Check perceived latency and Boost at 100%, 200%, 300%, and 400%; verify no
   clipping or harshness and that leveling does not pump noise.
7. Unplug headphones: audio must become silent immediately and the blocking
   screen must appear. Reconnect: verify a fade-in resume.
8. Connect and disconnect Bluetooth headphones.
9. Run screen-off background streaming for 30 minutes on Samsung and another
   Android manufacturer.
10. Rotate screens, background/foreground the app, and verify the session
    remains synchronized.
11. Turn off the hotspot or leave Wi-Fi; verify reconnect and clear ended
    session behavior.
12. End the session from the speaker; verify every listener stops audio and
    sees the next step.
13. Deny microphone and notification permissions; verify clear recovery
    guidance and that notification denial does not crash the session.
14. Check duplicate names, full-session handling, blocked/declined requests,
    and speaker pause/reconnect states.
15. Verify no audio is saved, no real device name appears, and the app works
    with internet disabled and no SIM.
16. Install the signed universal APK on a 32-bit phone and a 64-bit phone.
    Launch, run one short session, and uninstall it successfully.

## Release evidence

Attach analyzer/test/build output and the two real-device results to the
release record. If a physical 32-bit or 64-bit phone is unavailable, record
that as an open risk in [`DECISIONS.md`](DECISIONS.md); an emulator is not a
substitute for this acceptance check.
