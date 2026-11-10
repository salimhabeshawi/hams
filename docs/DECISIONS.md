# Decisions

- Use the installed Flutter 3.47.7 stable toolchain and its compile/target SDK defaults; this keeps the Android SDK level aligned with the current Flutter release.
- Use exact latest compatible pub.dev releases verified on 2026-11-07; this avoids pinning packages below the current stable toolchain.
- Keep the initial UI intentionally empty while the native engine smoke bridge proves the platform boundary before feature work begins.
- Phase 1 keeps the engine boundary untouched and uses explicit offline placeholder states for role actions; networking and audio remain Phase 2 work.
- Identity filtering is deterministic and synchronous for generated/renamed names, with the shipped blocklist asset documenting the offline policy. Hardware identifiers, addresses, audio, and PINs are not persisted.
- The Roboto Flex family is selected as the app typography contract; a build-time font asset must be supplied before release packaging if the repository's asset bundle is regenerated.
- Phase 2 keeps the control-plane transport in Kotlin/JVM primitives (UDP discovery, framed TCP, and javax.crypto) while the audio path remains native; this preserves the no-allocation audio boundary and avoids adding an online dependency.
- The Flutter shell uses the Pigeon snapshot API plus a dedicated EventChannel for state notifications; discovery results remain display-name-only and addresses are kept out of normal UI cards.
- Phase 3 keeps packet authentication, jitter ordering, DSP safety limits, and route selection in small deterministic native components; Oboe capture is isolated behind a fixed ring buffer so the callback performs no allocation or locking.
- Phase 4 uses Android's native foreground-service notification and lock APIs with a shared in-process runtime bridge; this keeps the audio/session engine alive when Flutter UI is destroyed while preserving the existing Pigeon API.
- Phase 5 keeps request/listener cards driven by the existing event stream and aggregate snapshot; the current Pigeon snapshot has no typed request/listener payload, so the UI exposes stable empty/error states until that native contract is extended.
- Phase 6 keeps noise reduction in the native encoder thread with a 20% dry signal and an atomic live toggle; capture callbacks remain a lock-free ring-buffer handoff only. The repository-wide review found no Android hardware-name reads or transmissions: only generated/user-chosen Hams names cross the engine boundary.
- Phase 6 identity review grep result: no `Build.MODEL`, `Build.MANUFACTURER`, Bluetooth product/name, or hardware-name access was found in `lib/` or `android/app/src/main`; `deviceName` matches are the generated/user-chosen Hams identity persisted by `AppPreferences` and sent through the existing session protocol.
- Phase 7 uses a checked-in signing configuration template and fails release
  configuration without a private `android/key.properties` file; debug builds
  remain usable on clean checkouts.
- Open risk: the checked-in SPEC.md manual checklist ends mid-item after
  “Samsung and”; the missing remainder could not be validated and should be
  restored before final release sign-off.
- Open risk: this environment has an Android emulator but no physical 32-bit
  or 64-bit phone connected, so the required real-device install, audio, and
  background checks remain unverified.
- Open risk: Docker is unavailable, so no container-backed integration
  environment can be used; Flutter and Android unit tests remain runnable.
