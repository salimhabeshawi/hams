# Decisions

- Use the installed Flutter 3.47.7 stable toolchain and its compile/target SDK defaults; this keeps the Android SDK level aligned with the current Flutter release.
- Use exact latest compatible pub.dev releases verified on 2026-11-07; this avoids pinning packages below the current stable toolchain.
- Keep the initial UI intentionally empty while the native engine smoke bridge proves the platform boundary before feature work begins.
- Phase 1 keeps the engine boundary untouched and uses explicit offline placeholder states for role actions; networking and audio remain Phase 2 work.
- Identity filtering is deterministic and synchronous for generated/renamed names, with the shipped blocklist asset documenting the offline policy. Hardware identifiers, addresses, audio, and PINs are not persisted.
- The Roboto Flex family is selected as the app typography contract; a build-time font asset must be supplied before release packaging if the repository's asset bundle is regenerated.
