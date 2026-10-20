# Sortie

An email client that sorts itself. Native apps for Linux, Windows, Android and iOS
from one Flutter codebase.

- **AI sorting** with your own Anthropic API key or any OpenAI-compatible endpoint
  (Ollama, LM Studio, vLLM, OpenAI). Deterministic rules and learned sender history run
  first; the model only sees what they cannot decide. Every decision shows its reason,
  can be undone, and corrections teach it.
- **Reads come first.** A message is never moved while it is open on any device, and by
  default it stays in the inbox until you have read it (plus a short grace period).
- **Takeover without a server.** All your devices share a hidden IMAP folder for a
  leader lease, heartbeats, presence and the sort journal. Desktops sort; if the sorting
  device shuts down another running instance takes over. Phones sort while open.
- Generic IMAP/SMTP accounts (password auth). OAuth for Gmail / Microsoft 365 is on the
  backlog.

Design documents: [docs/coordination-protocol.md](docs/coordination-protocol.md),
[docs/sorter-design.md](docs/sorter-design.md).

## Development setup (Linux)

```sh
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
  libstdc++-12-dev libsecret-1-dev libayatana-appindicator3-dev libnotify-dev
# Flutter 3.47.x stable in ~/flutter, Android SDK in ~/android-sdk
export PATH=$HOME/flutter/bin:$PATH ANDROID_HOME=$HOME/android-sdk
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
CC=/usr/bin/clang CXX=/usr/bin/clang++ flutter run -d linux
flutter run -d <android-device>
```

Run with fake data before configuring an account:
`flutter run -d linux --dart-define=SORTIE_DEMO=true`.

### iOS from Linux (development builds)

Xcode cannot run here, but [xcross](https://github.com/RZI3D/xcross) builds, signs
(free Apple ID) and installs Flutter iOS **debug** builds from Linux, using the Swift
toolchain and an `Xcode.xip`:

```sh
xcross setup
xcross sdk install ~/Downloads/Xcode_26_Universal.xip
xcross auth --apple-id you@example.com
xcross doctor
sudo xcross tunnel        # in a second terminal, iOS 17+ device over USB
xcross flutter run        # hot reload works
```

xcross is authenticated with the App Store Connect API key in `~/sortie-keys/`
(`xcross auth --issuer-id … --key-id … --private-key …`), so signing needs no 2FA and
profiles last a year.

Known Linux-only plugin bug: `flutter_foreground_task` 11.0.3 imports
`FlutterForegroundTaskEarlyRegistration.h` but ships the header as
`Flutterforegroundtaskearlyregistration.h`; xcross builds fail until a correctly-cased
copy exists next to it in `~/.pub-cache/hosted/pub.dev/flutter_foreground_task-11.0.3/ios/…/include/flutter_foreground_task_early_registration/`
(and in `~/.cache/xcross/swiftpm/*/plugins/Packages/flutter_foreground_task/…`).
Builds are memory-hungry: run them with `taskset -c 0-3` on this laptop.

Release (AOT) iOS builds require macOS; `release-ios.yml` builds on a GitHub macOS
runner. With the `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` and `APPLE_TEAM_ID`
secrets set it produces a development-signed `.ipa` that installs on registered devices;
otherwise an unsigned `.ipa` for AltStore / Sideloadly / `xtool`.

### Android release signing

The release key lives outside the repo in `~/sortie-keys/` (see its README). Copy
`key.properties` to `android/key.properties` (gitignored). CI reads the key from the
`ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` secrets.
Never change the key: sideloaded updates only install over the same signature.

### IMAP integration tests

```sh
docker compose -f tool/docker-compose.dovecot.yml up -d
flutter test test/data/integration --dart-define=IMAP_TEST_HOST=localhost --dart-define=IMAP_TEST_PORT=3143
```

### Desktop windows

On Linux/Windows/macOS the app runs one Flutter engine with several native
windows (`multiview_desktop`): the main window plus one window per open
composer. All windows share the same riverpod container (`globalScope` in
`main.dart`), so the composer reads and writes the same services as the main
window with no IPC. `sortie --compose` opens a new message at startup.

Drafts autosave 20 s after the first unsaved change; each save replaces the
previous copy in Drafts and sending removes it. The Linux runner needs the
three `multiview_desktop_linux_runner_*` calls in `my_application.cc`, and
`linux/CMakeLists.txt` links X11 into the plugin.

### Notifications

New-mail notifications are a per-device choice (Settings → Notifications) and
are never shared through the mail account: *Every message* (default on
computers), *Important only* (default on phones) or *Off*. "Important" is
decided from headers alone, no model calls: flagged mail, people you have
written to (Sent folder, answered mail), replies in your conversations, and
mail addressed directly to you by a person. Mailing lists, bulk and
auto-submitted mail, automated senders (`no-reply@`, `notifications@`, ...)
and mail where you are only copied stay quiet. Mail already read on another
device, your own copies and anything older than a day are never announced;
bursts of more than eight messages collapse into one summary.

### Sorting in the background on phones

Desktops sort as long as Sortie runs, focused or hidden in the tray. Phones
keep sorting after you leave the app too, each in the way its platform
allows (Settings → Devices → "Keep sorting in the background", on by
default):

- **Android** runs a persistent low-priority foreground service
  (`remoteMessaging` type, so Android 15's six-hours-a-day cap on data-sync
  services does not apply) that keeps the IMAP IDLE connections up.
- **iOS** has no such service. Sortie holds a silent audio session
  (`audio` background mode, mixes with whatever is playing) so iOS does not
  freeze the process; this costs some battery. With it off, the phone sorts
  only while on screen, for about 30 s after you leave, and in the short
  background-refresh windows iOS grants.

## Releases

Tag `vX.Y.Z` and push. Four workflows build Linux (tar.gz), Windows (zip), Android
(signed APKs) and iOS (unsigned ipa) and attach them to the GitHub release. The same
workflows also run weekly so Windows/iOS regressions surface early.
