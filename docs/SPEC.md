# Hams — Product & Engineering Specification v1

## 0. Rules for the AI implementing this
- This file is the single source of truth. Do not invent requirements. If something is ambiguous, pick the most conservative option and record it in `docs/DECISIONS.md` (one line each, with reason).
- Before adding any package, check pub.dev (or Maven Central for Android libs) that it is maintained, null-safe, and compatible with the latest stable Flutter. Never rely on remembered version numbers; look them up. Prefer fewer dependencies.
- Never mention any specific audience, institution or use case in UI text, code comments, docs, store text or the README. Hams is a general-purpose tool (talks, meetings, guided tours, workshops, etc.).
- All user-visible strings go through Flutter gen-l10n (ARB). English only for now, but structured so other languages can be added later.
- After each phase: `flutter analyze` has zero issues, `flutter test` passes, and `flutter build apk --debug` succeeds.

## 1. Product
Hams is a free, open-source, Android-only app that turns one phone into a live microphone and streams the voice, fully offline over a local Wi-Fi network (usually the speaker's own phone hotspot), to up to 50 listener phones. Listeners hear the voice boosted and leveled through headphones only.
- Roles: exactly one Speaker (host) per session; many Listeners.
- Tagline: "Every voice, heard clearly."
- No internet use, no accounts, no analytics, no ads, no audio recording or saving of any kind.
- Only network permission usage is local sockets. Make no outbound internet calls anywhere in the app.

## 2. Non-negotiables
1. 100% offline, works with zero internet and no SIM.
2. Strict headphone rule: listeners never hear audio on the phone's loudspeaker or earpiece. No headphones route = silence plus a blocking screen.
3. Real device names (model, user-set device name, Bluetooth name, hotspot name) are never read for display, never transmitted, never shown. Only generated/custom Hams names appear anywhere.
4. Must work on as many Android phones as possible, including cheap 32-bit devices.
5. Low latency (typical mic-to-ear 150 ms or less on Wi-Fi with wired headphones), with no audible glitches.
6. Works with the screen off and the app in the background.
7. UI is Material 3 Expressive style, built in Flutter.

## 3. Platform & tooling
- Flutter: latest stable. Dart: matching latest stable, null-safety, strict analysis (`flutter_lints` plus `strict-casts`, `strict-inference`, `strict-raw-types`).
- Android `minSdk 24` (Android 7.0). `compileSdk`/`targetSdk`: the latest stable API level that Google Play currently requires (verify at build time).
- ABIs: build `armeabi-v7a`, `arm64-v8a`, `x86_64` (32-bit phones are common; do not drop `armeabi-v7a`).
- Application ID: `org.hams.app`, defined in exactly one place and documented in README (it must be changeable before first public release).
- Version `1.0.0+1`.
- State management: Riverpod (`flutter_riverpod`, no code generation). Navigation: `go_router`. Persistence: `shared_preferences`. IDs: `uuid`. Typed Flutter-to-Android API: `pigeon`. Other helpers allowed if justified: `permission_handler`, `package_info_plus`, `flutter_launcher_icons`, `flutter_native_splash`, `mocktail`.
- Feature-first folder structure: `lib/app`, `lib/core` (theme, l10n, utils), `lib/features/{onboarding,role_select,speaker,listener,settings,help,about,diagnostics}`, `lib/platform` (generated Pigeon + wrappers).
- Native Android layer in Kotlin plus C++ (NDK/CMake): the whole session engine (discovery, networking, crypto, audio capture/playback, DSP, codec, foreground services) lives natively. Flutter is UI plus state only and talks to the engine over Pigeon + EventChannels. Reason: robust background operation and real-time audio.
- Native libs: Oboe (Apache-2.0, via official AAR) for audio I/O; libopus (BSD-3, vendored source, latest stable 1.5.x) for the codec; RNNoise (BSD-3, vendored, Phase 6) for optional noise reduction.
- Release build: R8 minify with correct keep rules for JNI and Pigeon classes; signing via `key.properties` (never committed; `.gitignore` it; document in README).
- License: GPL-3.0-or-later. Add `LICENSE`, SPDX headers on source files, and third-party notices for Oboe, Opus, RNNoise, Flutter and packages.

## 4. Identity & names
- On first launch generate a persistent random `deviceId` (UUID v4). Never use any hardware or system identifier.
- Display name = random "Adjective Noun" (e.g., "Gentle Mango"), generated from the lists below. Stored locally; shown to others as the device's name.
- Rename: 2–24 characters; letters, digits, spaces, hyphen, apostrophe; trimmed; collapse repeated spaces. Run through the profanity/inappropriate filter (an asset `blocklist.txt` with English profanity, sexual, hate, violence terms; normalize leetspeak and spacing before matching; also reject names matching the Excluded themes below). A "Surprise me" button regenerates a random name. Renaming is allowed any time; if connected, the new name is sent live.
- The speaker may also set an optional Session Title (same rules), shown to listeners.
- Uniqueness: on the speaker side, if two listeners share a name, display "Name (2)". Do not force listeners to change.
- Avatar: a colored shape with two initials (first letter of adjective and noun). Color and shape are deterministic from a hash of `deviceId`: 12 harmonized colors from the current theme's tonal palette, 8 different Material expressive-style polygon shapes (cookie, flower, sunny, clover, burst, pill, puffy, squircle). Use a maintained pub.dev port of the Material Shapes/RoundedPolygon library if one exists; otherwise custom-paint them.
- Excluded themes for all generated names (strict): alcohol or drinks, pork, dogs, pigs, gambling or "luck" words, music/dance/instruments, romance, body parts, weapons/violence, scary/dark things, politics, deities, religious figures, religious places or terms, brands, anything teasing or insulting. Keep names friendly, calm and culturally neutral.
- Adjectives (use exactly these): Happy, Sunny, Gentle, Bright, Cheerful, Cozy, Breezy, Mellow, Jolly, Swift, Calm, Merry, Playful, Sparkly, Fluffy, Dreamy, Peaceful, Brave, Clever, Humble, Lively, Radiant, Misty, Golden, Silver, Velvet, Wise, Kind, Graceful, Glowing, Serene, Zesty, Fresh, Dewy, Bubbly, Tidy, Snug, Rosy, Sweet, Tender, Noble, Bold, Eager, Nimble, Chipper, Perky, Soaring, Shining, Twinkling, Hopeful, Joyful, Smiling, Curious, Friendly, Honest, Patient, Steady.
- Nouns (use exactly these): Mango, Papaya, Guava, Pomegranate, Apricot, Fig, Lemon, Orange, Apple, Pear, Plum, Melon, Kiwi, Lime, Coconut, Pineapple, Blueberry, Strawberry, Tangerine, Peach, Avocado, Raspberry, Mulberry, Clementine, Lychee, Watermelon, Banana, Jasmine, Lily, Daisy, Tulip, Orchid, Lotus, Sunflower, Lavender, Violet, Marigold, Iris, Blossom, Peony, Magnolia, Hibiscus, Clover, Fern, Mint, Basil, Sage, Bamboo, Acacia, Cedar, Olive, Palm, Maple, Willow, Juniper, Cypress, Meadow, River, Waterfall, Canyon, Valley, Lagoon, Breeze, Cloud, Rainbow, Sunrise, Sunbeam, Dawn, Moonbeam, Comet, Aurora, Dune, Oasis, Island, Reef, Pebble, Coral, Pearl, Opal, Amber, Jade, Ruby, Topaz, Crystal, Sapphire, Emerald, Garnet, Glacier, Brook, Creek, Harbor, Horizon, Hilltop, Orchard, Garden, Grove, Prairie, Snowflake, Raindrop, Dewdrop, Starlight, Sparrow, Falcon, Dove, Swan, Robin, Finch, Heron, Pelican, Butterfly, Firefly, Dolphin, Bluebird, Skylark, Starling, Ladybug, Dragonfly.

## 5. Network design
Topology is a star: listeners talk only to the speaker (works even when Wi-Fi client isolation blocks phone-to-phone traffic).

### 5.1 Supported networks
(a) Speaker's phone hotspot (primary use). (b) Any shared Wi-Fi network. The app never creates or configures the hotspot; it only guides the user (see 9).

### 5.2 Listener network binding (critical for compatibility)
A hotspot without internet often makes Android route traffic over mobile data or refuse the network. On the listener: request the Wi-Fi network via `ConnectivityManager.requestNetwork` (`TRANSPORT_WIFI`, do not require INTERNET/VALIDATED), and `bindProcessToNetwork` (or bind each socket to that `Network`) for the whole session. Release on exit. Acquire a `WifiManager.MulticastLock` while discovering. Acquire a Wi-Fi lock for the whole session (`WIFI_MODE_FULL_LOW_LATENCY` on API 29+, else `FULL_HIGH_PERF`). The speaker (hotspot host) binds to `0.0.0.0` and determines its own IPv4 addresses by enumerating network interfaces (any up, non-loopback, non-cellular, private-range IPv4); it announces on all of them.

### 5.3 Ports
Discovery UDP `41710` (multicast group `239.255.42.99`). Speaker control TCP preferred `41711`; speaker audio UDP preferred `41712`. If busy, use an ephemeral port and advertise it. Protocol version constant `1`.

### 5.4 Discovery (run all methods in parallel, dedupe by `sessionId`)
1. Multicast: listener sends `WHO` probes every 1.5 s; speaker answers by unicast and also multicasts an `ANNOUNCE` every 2 s.
2. Subnet broadcast: same probe/announce to the subnet broadcast address of each interface.
3. Gateway probe: listener unicasts `WHO` to its Wi-Fi gateway IP (when the listener is on the speaker's hotspot, the gateway is the speaker). This is the most reliable method.
4. Manual: an "Enter address" fallback in the listener's overflow menu (IPv4 plus port).
ANNOUNCE (JSON, UTF-8): `{app:"hams", v:1, sessionId, deviceId, name, title, pin:bool, listeners:int, max:50, tcp:port, udp:port, state:"live"|"paused"}`. A listener drops a speaker after 7 s of silence. The UI never shows IP addresses outside the Diagnostics screen and manual entry.

### 5.5 Control channel (TCP, speaker is server)
Framing: 4-byte big-endian length + JSON. Heartbeat `PING`/`PONG` every 2 s; connection considered dead after 7 s of silence. Messages:
- `JOIN_REQUEST {deviceId, name, pubKey(P-256, base64), pinProof?}`
- `JOIN_PENDING` (speaker has not decided)
- `JOIN_ACCEPT {listenerId(u16), epoch, salt, wrappedSessionKey, audio:{rate:48000, ch:1, frameMs:20, codec:"opus"}, udpPort}`
- `JOIN_DENY {reason: "declined"|"blocked"|"full"|"wrong_pin"|"locked", retryAfterSec}`
- `STATE {state:"live"|"paused"|"ended"}`, `REKEY {epoch, wrappedSessionKey}`, `KICK {reason}`, `LEAVE`
- `RENAME {name}`, `LISTENER_STATUS {headphones:bool, buffering:bool}`
- `SESSION_INFO {title, speakerName, listenerCount}` (never other listeners' names).
Rules: max 50 admitted listeners (`full` otherwise). Declined listener: 60 s cooldown for that `deviceId`. "Remove" = kicked, can ask again after 5 minutes. "Block" = refused until session ends. Wrong PIN 5 times = 60 s lockout for that `deviceId`; a wrong PIN is reported to the listener without bothering the speaker.

### 5.6 Admission
Default: the speaker sees a request and taps Accept or Decline. Speaker options: "Auto-accept everyone" toggle, and per-listener "Always allow" (a trusted list of `deviceId`s kept in preferences, removable in Settings). Optional PIN (4–6 digits, per session, not persisted, never logged): `pinProof = HMAC-SHA256(sharedSecret, "hams-pin" + pin)`; PIN success still requires Accept unless auto-accept/trusted applies.

### 5.7 Encryption (lightweight, always on)
P-256 ECDH (per-request ephemeral keys; Android Keystore not required) → HKDF-SHA256 → key-wrapping key. The speaker holds a random 128-bit session key per epoch. It sends the session key to each admitted listener wrapped with AES-128-GCM. Audio packets use AES-128-GCM (hardware accelerated via `javax.crypto`). Nonce = `salt(4) ‖ epoch(1) ‖ 0x000000 ‖ seq(4)`; the packet header is AAD. On Remove/Block, rotate the session key (new epoch) and send `REKEY` to the remaining listeners. Overhead is negligible; do not add anything heavier.

### 5.8 Audio transport (UDP, unicast per listener)
Listener opens a UDP socket and sends authenticated `HELLO` keepalives every 1 s to the speaker's UDP port; the speaker learns the listener's address from them (NAT/firewall friendly) and sends audio there. Set traffic class/TOS to `0xB8` on audio sockets (best effort).
Packet: `'H','M', ver(u8), type(u8: 1 audio, 2 hello), listenerId(u16), epoch(u8), seq(u32), ts(u32 ms, speaker clock)` + AES-GCM(payload). One Opus frame per packet (20 ms). Speaker encodes once and encrypts once per epoch (shared session key), then sends to each listener. Pre-allocate buffers; use a dedicated high-priority sender thread (`THREAD_PRIORITY_URGENT_AUDIO`); target CPU and GC overhead near zero for 50 listeners (about 2,500 packets/s).

### 5.9 Reconnect
Listener auto-reconnects on drop with backoff 1 s, 2 s, 3 s, then every 5 s, for up to 10 minutes, to the same speaker (matched by `deviceId`; rediscovered if its IP changed). The speaker keeps a dropped listener's admission valid for 10 minutes so no re-approval is needed. Stop reconnecting immediately when the session `ended` or the listener was kicked/blocked/declined, and show the reason. If the speaker restarts a new session, trusted/auto-accept rules apply; otherwise a new request is needed.

## 6. Audio pipeline

### 6.1 Speaker (capture → encode → send)
- Oboe input stream: mono, 48 kHz, `PerformanceMode::LowLatency`, shared mode, `Float` or `I16`; input preset `VoiceRecognition` (`VoiceCommunication` only when the Bluetooth headset mic is selected, as needed for SCO routing). Choose device via `setDeviceId`.
- Mic sources shown in-app by type with no real names: "Phone microphone", "Wired headset mic", "USB microphone", "Bluetooth headset mic (lower quality)". If two of the same type exist, number them. Hot-plug via `AudioDeviceCallback`. If the selected device disappears, fall back to Phone microphone with a message. Persist selection by type.
- Bluetooth mic: API 31+ `setCommunicationDevice`, below that `startBluetoothSco`; always release on stop.
- No speaker-side gain slider and no speaker-side AGC (leveling is done on listeners).
- Speaker phone stays silent: never play remote or monitor audio on the speaker.
- Fixed processing: 80 Hz high-pass filter, plus platform `NoiseSuppressor` when available, plus optional RNNoise (Phase 6).
- Opus: 48 kHz mono, 20 ms frames, application VOIP, signal type voice, 32 kbps constrained VBR, complexity 6, inband FEC on, expected packet loss 10%, DTX off. The encoder runs on its own thread; Oboe callback only fills a lock-free ring buffer (no allocation/locking in callbacks).
- Mute and Push-to-talk: Mute = stop sending audio (keep session), broadcast `STATE paused`. Push-to-talk mode = hold-to-talk button, otherwise paused. Both available on the live screen.
- Phone call or audio-focus loss: pause streaming, broadcast `paused`, auto-resume when focus returns.

### 6.2 Listener (receive → decode → DSP → play)
- Adaptive jitter buffer: target 40–80 ms (min 2 frames, max 8), reorder by `seq`, drop late packets, use Opus FEC then PLC for gaps, gentle drift compensation (drop/duplicate the least audible sample slice; no audible pitch change). Trim the buffer if it grows beyond the max.
- Decode → DSP chain → Oboe output (mono to stereo duplicate, 48 kHz, `LowLatency`, shared, fixed to the headphone device id).
- DSP chain (all native, float): DC blocker → slow leveler (AGC) → user Boost gain → look-ahead limiter.
  - Leveler: target about −18 dBFS short-term RMS; max gain +24 dB, min 0 dB; attack 50 ms (gain down), release 800 ms (gain up); noise gate: if level is below about −55 dBFS, freeze gain (never pump up silence/noise).
  - Boost: user slider 100%–400% (0 to +12 dB); default 200%. Shown as percentage. Persist.
  - Limiter: ceiling −1 dBFS, 5 ms look-ahead, soft-knee; guarantees no clipping or sudden spikes.
  - Fade-in 300 ms whenever audio starts or resumes (including after reconnect or headphone plug-in).
- Hearing safety: the first time Boost goes above 300%, show a confirmation dialog; while above 300% show a subtle warning chip. Tip text: start with low phone volume.
- Silence handling: when the speaker is paused, output exact silence (stop calling the decoder); resume with fade-in.
- Audio focus: request `AUDIOFOCUS_GAIN` (usage media, content type speech). Transient loss: pause and auto-resume when regained. Permanent loss: pause and show a "Tap to resume" state.
- Latency measurement: ping RTT over control channel plus the jitter buffer depth gives an estimated latency shown in Diagnostics. Show a tip that wired headphones give the lowest delay (Bluetooth adds its own delay).

### 6.3 Level meter
Native computes RMS/peak at about 20 Hz (speaker: input level; listener: output level) and sends it to Flutter through an EventChannel, throttled; the UI never processes audio.

## 7. Headphone enforcement (listener, 100% strict)
- Allowed output types: `TYPE_WIRED_HEADSET`, `TYPE_WIRED_HEADPHONES`, `TYPE_USB_HEADSET`, `TYPE_USB_DEVICE`, `TYPE_BLUETOOTH_A2DP`, `TYPE_BLUETOOTH_SCO`, `TYPE_BLE_HEADSET`, `TYPE_HEARING_AID` (use those available at runtime API level). Explicitly never: built-in speaker, earpiece, HDMI, remote submix, anything else.
- Open the Oboe output with `setDeviceId` of an allowed device. Pick by priority wired > USB > BLE > A2DP > SCO.
- `AudioDeviceCallback`: when no allowed device remains, within 100 ms fade out, stop output, drop incoming audio (stay connected), and show a blocking full-screen "Connect headphones" state (animation plus a plain instruction). When one appears, auto-resume with fade-in.
- If the Oboe stream disconnects or errors, re-check the allowed device before reopening; never reopen on the built-in speaker.
- Send `LISTENER_STATUS {headphones}` so the speaker's list can show "Waiting for headphones" for that listener.
- The check runs before first playback, on every route change, and on app resume.
- UI sound effects on the listener play only when headphones are present; never on the speaker phone during a live session (use haptics there).

## 8. Background & reliability
- Two foreground services: `SpeakerService` (type `microphone`) and `ListenerService` (type `mediaPlayback`). Declare the required `FOREGROUND_SERVICE_*` permissions and types. Start only from a user action while the app is visible. The engine lives in the service; the Flutter UI can be killed and re-attached (re-sync via a state snapshot call + event stream).
- Persistent notification (low importance channel, no sound): speaker has Mute/Unmute and End; listener has Disconnect.
- Locks while a session is active: partial wake lock, Wi-Fi lock, multicast lock (only while discovering). Optional "Keep screen on" switch (default off).
- "Keep Hams running" Help screen with static, offline text: how to disable battery optimization for Hams, how to allow background/auto-start on common brands (Samsung, Xiaomi/Redmi/POCO, Tecno/Infinix/itel, Oppo/Realme/OnePlus, Vivo, Huawei/Honor, Google Pixel, Motorola), with a button that opens the battery-optimization settings (prefer the settings-screen intent over the restricted direct-exemption permission).
- Hotspot tips (shown in guides/Help): disable the hotspot's auto-turn-off timer; if some phones can't find the hotspot, set the band to 2.4 GHz or enable "Extended compatibility"; if Android asks "stay connected without internet?", choose Yes (listeners); turn off VPN apps.

## 9. Screens & flows

### 9.1 Launch
Splash (Android 12+ splash API) → first launch only: Onboarding → Role Select. Every later launch goes straight to Role Select (always the first real screen).

### 9.2 Onboarding (first launch, 5 pages, skippable but not the name step)
1. Welcome: what Hams does. 2. Headphones rule for listeners. 3. How it connects: offline over the speaker's hotspot. 4. Your device name: shows a random name, "Surprise me" and rename. 5. Done.

### 9.3 Role Select
Two large expressive cards: "Speak" and "Listen" (distinct colors and shapes), plus Settings and Help icons, and your name/avatar chip (tap to rename). Switching role while a session is active asks for confirmation and disconnects the current role cleanly.

### 9.4 First-time role guides (shown automatically the first time each role is chosen; reopenable from Help)
- Speaker guide (stepper with live status checks): 1) Turn on your phone's hotspot (button opens hotspot settings: try `com.android.settings.TetherSettings`, fallback `ACTION_WIRELESS_SETTINGS`, fallback `ACTION_SETTINGS`; the step turns green when a local network address is detected). 2) Allow the microphone (just-in-time rationale then permission). 3) Choose a microphone. 4) Allow notifications and (optionally) battery exemption. 5) Go live.
- Listener guide: 1) Join the speaker's hotspot (button opens Wi-Fi settings, `ACTION_WIFI_SETTINGS`; checks that Wi-Fi is connected). 2) Connect headphones (live check turns green). 3) Allow notifications. 4) Pick the speaker.

### 9.5 Speaker screen
Pre-live: network status card (ready / not ready with fix button), microphone selector, optional Session Title, optional PIN switch (field appears), Auto-accept switch, big "Go live" button.
Live: large animated visualizer; Mute button and Push-to-talk mode toggle (with big hold button); session timer; listener count chip ("12 / 50"); requests section (badge, haptic on arrival; Accept / Decline per card, "Accept all" when 2+); listener list with avatar, name, status chip (Listening / Waiting for headphones / Reconnecting / Paused), and a menu (Remove, Block, Always allow); End session (confirmation dialog). Only the speaker sees the full listener list.

### 9.6 Listener screen
Discovery: list of nearby speakers as cards (avatar, name, title, lock icon if PIN, live/paused indicator), pull-to-refresh, empty state with help ("Make sure you are on the speaker's hotspot"), overflow → "Enter address".
Select → (PIN dialog if needed) → "Waiting for approval…" (wavy progress, Cancel) → Connected screen: visualizer, speaker avatar/name/title, status chip (Live / Speaker paused / Reconnecting / Waiting for headphones), Boost slider with 100/200/300/400% marks plus hearing-safety chip, estimated delay (small, optional), Disconnect button. If the speaker is not on the list yet, auto-retry silently.
Declined/blocked/full/wrong PIN/session ended each show a clear message and next step.

### 9.7 Settings
Appearance (Theme color grid, Light/System/Dark connected button group, "AMOLED black" switch enabled only when dark is active). Device (name, "Surprise me", avatar preview). Audio: speaker (default mic type, noise reduction), listener (default Boost). Connection (default Auto-accept, trusted listeners list with remove, blocked-this-session info). Feedback (haptics on/off, sounds on/off). Keep screen on during sessions. Help (guides, Keep Hams running, troubleshooting). Diagnostics. About. Reset app data (confirmation).

### 9.8 About
App name and tagline, version, "Free and open source (GPL-3.0)", "No ads, no tracking, works offline", link to source repo (placeholder constant), licenses page (Flutter license page plus native library notices).

### 9.9 Diagnostics (Settings; engineering-grade but friendly)
Local interfaces and IPs, active discovery methods and what they found, session ids, control/UDP port, per-listener packet loss/jitter (speaker), buffer depth, loss %, estimated latency and codec stats (listener), "Copy report" button (no real names inside). A hidden developer toggle (tap version 7 times) enables a single-device loopback test (speaker + listener engines in one process on 127.0.0.1) and a test tone generator.

## 10. Design system — Material 3 Expressive (Flutter)
- Always verify what the latest stable Flutter provides natively (new M3 components, `DynamicSchemeVariant`, slider/progress styles) and what a maintained pub.dev package provides; build the rest as reusable widgets in `lib/core/ui`. Expressive means: bold color, big shapes, springy motion, emphasized type. It must look clearly newer than plain Material 3.
- Color: `ColorScheme.fromSeed` with `DynamicSchemeVariant.vibrant` (compare against `expressive`; keep whichever looks richer and still keeps the seed hue recognizable). No dynamic wallpaper color. Verify text contrast meets WCAG AA in all themes and modes.
- Theme seeds (name: hex), default Blueberry: Blueberry `#4285F4`, Poppy `#EA4335`, Meadow `#34A853`, Sunflower `#FBBC04`, Mint `#00AC47`, Lagoon `#00897B`, Orchid `#7248B9`, Indigo `#3F51B5`, Rose `#E91E63`, Tangerine `#FF6D00`, Lime `#AFB42B`, Sky `#00BCD4`, Cocoa `#795548`, Slate `#607D8B`, Coral `#FF7043`, Lilac `#9C27B0`.
- Modes: Light / Dark / System (default System), persisted, smooth animated switching. AMOLED black option applies only in dark: scaffold and surfaces pure black, containers very dark neutral grays, primary colors unchanged.
- Typography: bundle Roboto Flex (variable, OFL) as an asset (no runtime font fetching, the app is offline). Use weight and width axes for emphasized titles (big expressive headlines, 700+ weight). Do not use the `google_fonts` runtime fetcher.
- Shape: large radii (28–48 dp), mixed shape language (squircle, cookie, flower); buttons morph shape on press (e.g., circle to squircle) with spring animation.
- Motion: spring-based tokens (fast/default/slow spatial with slight overshoot; effects springs without overshoot) implemented once in `core/motion`; emphasized easing for transitions; shared-axis page transitions; predictive back. Respect system "remove animations" by using reduced motion.
- Components: large collapsing top app bars, big primary button ("Go live"), connected button groups, expressive thick sliders, wavy progress indicator (custom painter if not available), loading indicator, color-blocked cards using primary/secondary/tertiary containers, avatars with polygon shapes, a morphing blob visualizer driven by the level meter.
- Layout: edge-to-edge, transparent system bars. Adaptive by window size class: compact under 600 dp, medium 600–839, expanded 840+. Portrait and landscape allowed (no orientation lock). Expanded/landscape speaker live screen = two panes (controls | listeners); expanded/landscape listener = two panes (speakers | session). Test on tablets.
- Accessibility: screen-reader labels (`Semantics`) on all controls, live-region announcements for state changes (connected, paused, headphones missing), 48 dp minimum touch targets, state never conveyed by color alone. Do not build special large-text or high-contrast modes; clamp the text scale factor to a maximum of 1.2 so layouts never overflow.
- Haptics: `HapticFeedback` on request arrival, accept, connect, disconnect, mute. Sound effects: short tasteful earcons generated by a script in `/tools` (sine tones with envelopes) committed as tiny assets; never played during a live speaker session; listeners only when headphones are connected. Both controlled by Settings switches (default on).
- App icon: adaptive icon (with monochrome/themed layer): a rounded cookie-shaped blue background and a white mark of three rising concentric sound arcs from a soft dot that subtly reads as an H. Supply as vector assets and configure `flutter_launcher_icons`. Splash: app icon on theme background via `flutter_native_splash` (Android 12+ API).

## 11. Permissions (request just-in-time with a rationale screen; never at app launch)
Manifest: `INTERNET`, `ACCESS_NETWORK_STATE`, `CHANGE_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, `WAKE_LOCK`, `MODIFY_AUDIO_SETTINGS`, `RECORD_AUDIO` (speaker only, requested when going live for the first time), `POST_NOTIFICATIONS` (API 33+), `BLUETOOTH_CONNECT` (API 31+, only when a Bluetooth route needs it), `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`. Do NOT request location or nearby-Wi-Fi permissions unless real-device testing proves they are required; if so, record it in `docs/DECISIONS.md`. Handle "permanently denied" with a button to app settings.

## 12. Persistence (`shared_preferences`)
deviceId, deviceName, theme seed, theme mode, AMOLED flag, haptics flag, sounds flag, keep-screen-on, listener Boost, default mic type, auto-accept default, trusted listener list (deviceId + last known name + date), onboarding-done flag, per-role guide-done flags, last session title. Never persisted: PIN, audio, IP addresses, real device names.

## 13. Edge cases that must be handled
Speaker hotspot turns off mid-session; listener leaves Wi-Fi; app killed by OEM; headphones unplugged mid-speech; Bluetooth headphones disconnect; incoming phone call (either side); two speakers nearby; session full (50); duplicate names; clock changes; very high packet loss (audio degrades gracefully, never loud bursts); speaker pauses for a long time (listeners stay connected); speaker taps End (listeners see "Session ended" and stop reconnecting); permission denied; notification permission denied (service still runs); device without a low-latency path (fall back to normal mode and increase buffer); mobile data enabled on listener; low battery; screen rotation without session loss; app update/restart (session ends cleanly).

## 14. Quality
- Tests: Dart unit tests (name generator never yields excluded themes and always matches `Adjective Noun`; rename validation and filter; settings; state machines for speaker/listener/admission; theme builder for all seeds and modes contrast sanity), widget tests (role select, onboarding, theme switching, headphone-blocked overlay, request accept flow with fake engine), Kotlin JUnit tests (packet codec, crypto round trip, rekey, jitter buffer ordering/loss, reconnect backoff, cooldowns), plus a single-device loopback integration test.
- Fake engine implementation of the Pigeon interface for UI tests and previews.
- Logging: no personal data; a small in-app ring log shown in Diagnostics.
- CI: GitHub Actions workflow (`analyze`, `test`, debug APK build, upload artifact).
- README: what it is, features, how it works offline, build steps (including NDK), how to sign a release, how to produce a universal APK for sideloading (`flutter build apk --release`) and per-ABI APKs, troubleshooting, the application-id note, license.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue templates (bug report asks for phone model/Android version/steps; this is the only place hardware info is requested, by the human reporter).

## 15. Manual test checklist (ship `docs/TESTING.md` with this)
Setup: 1 speaker + 3–4 listeners on real phones.
1. First launch onboarding; random name; rename; surprise me.
2. Speaker guide detects hotspot; listeners find the speaker via the hotspot.
3. Request, Accept, Decline, cooldown; Auto-accept; Always allow.
4. PIN correct, wrong, lockout.
5. Audio quality in each mic mode: phone mic, wired headset, USB, Bluetooth mic.
6. Latency feel; Boost slider 100–400% with no clipping or harshness; leveler lifts a quiet voice without pumping noise.
7. Unplug headphones: instant silence and blocking screen; replug: fade-in resume.
8. Bluetooth headphones connect/disconnect.
9. Screen off 30 minutes with background streaming on Samsung and