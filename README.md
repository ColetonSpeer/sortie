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
xcross sdk install ~/Downloads/Xcode_27.1_Universal.xip   # 27.1 or newer: the fold bridge needs its SDK
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
  freeze the process; this costs some battery. The session is re-asserted
  whenever the app changes state and by a 15 s watchdog, because a phone
  call, Siri or a Blabber dictation can leave it inactive, and an inactive
  session means iOS freezes the app within seconds of leaving it. With the
  option off, the phone sorts only while on screen, for about 30 s after
  you leave, and in the background-refresh windows below.
- **Background refresh (both phones).** Independently of the above, iOS
  BGAppRefresh/BGProcessing and Android WorkManager wake Sortie in a fresh
  isolate every so often (iOS decides when; roughly every 15 min to a few
  hours for an app that is used daily). That isolate builds the services
  for one bounded cycle: refresh the inbox, connect to the control folder,
  claim the lease if no higher-priority device is present, sort one batch,
  release, and exit within the ~30 s the OS grants. Its lines are tagged
  `[bg]` in `sortie.log`.

Honest limits: nothing a third-party iOS app can do keeps an IMAP IDLE
connection up as reliably as Apple Mail's system daemon. If the phone has to
sort on its own for long stretches, the robust design is a push relay (a
server that holds the IDLE connection and sends APNs pushes that wake the
app); that is not built.

### iPhone Duo (folding iPhone)

Sortie treats opening and closing the phone as a resize, which is what Apple
asks for: the outer display gets the stacked phone layout, the inner display
is wide enough for the two-pane layout, and nothing is tied to an
orientation or a fixed screen size. What is specific to the Duo:

- **The panes follow the fold.** On the inner display the list sits left of
  the crease and the message right of it. Flat, the divider lies on the
  seam; partially folded (book pose) the whole reserved strip stays empty.
  Folded upright like a laptop, the message reads on the raised half and the
  list scrolls on the flat half.
- **Dialogs, menus and sheets stay on one side** of a partially folded
  screen. Flutter leaves `MediaQuery.displayFeatures` empty on iOS, so
  `FoldReporter` (ios/Runner/AppDelegate.swift) reads UIKit's iOS 27.1
  reserved regions from inside Flutter's view and streams the fold to
  `FoldAware` (lib/platform/fold/fold_geometry.dart), which publishes active
  folds as display features and the full geometry through `FoldScope`.
- **Nothing is lost when you fold.** The open message, its scroll position
  and its read-guard hold survive the switch between the stacked and the
  two-pane layout (the reader is keyed per message), so a message you are
  reading keeps its "do not move while open" protection through a fold.
- **Narrow panes.** The reader's toolbar collapses Flag, Move and Delete
  into its menu below 420 pt, and the list takes at most 45 % of a two-pane
  window, so the inner display held upright is not cramped.
- **Swipe actions work on every phone layout**, not only below 600 pt.
- The status bar and camera strip along one edge of the inner display is
  an ordinary asymmetric safe-area inset; `SafeArea` handles it and no
  layout assumes opposite insets are equal.
- Landscape stays enabled on iPhone (tent mode), orientation is never
  locked at run time (the inner display ignores that anyway), and
  `UIRequiresFullScreen` is not set, so Split View works.

All of this needs the iOS 27.1 SDK: an app built with an older SDK is
letterboxed on the inner display. `release-ios.yml` therefore runs on the
`xcode-27` GitHub image (Xcode 27.1); an xcross dev build needs the
`Xcode_27.1` xip for the same reason.

Found on the real phone (2026-11-06) and fixed since:

- **Closing the phone went black** although `sortie.log` showed frames being
  built for the outer display within milliseconds. Flutter's own
  `FlutterMetalLayer` does not follow the window to the other panel;
  `FLTUseFlutterMetalLayer = false` in Info.plist (the system `CAMetalLayer`)
  fixed it. Two belt-and-braces measures stay in: the engine's display link
  is recreated at start-up and on demand when no frame follows a screen
  change (flutter/flutter issue 195401), and the root view controller keeps
  Flutter's view pixel aligned (issue 195954).
- **Unfolding with a message open blanked the reader.** The mail route used
  a different page type below and above 600 pt, so the resize replaced the
  route and the reader's key was in two routes at once. One page type now;
  only the transition depends on the width.
- The inner display's status bar and camera strip is an 84 pt inset on one
  side; Scaffold bodies are not inset horizontally by themselves.
- A phone restored from a backup keeps its accounts but not their keychain
  passwords (`first_unlock_this_device`): Accounts → Sign in.
- `pymobiledevice3 apps install` hangs forever once an earlier install was
  interrupted; `pymobiledevice3 diagnostics restart`, unlock, install again.

### Sending

Pressing Send spools the message and queues it. The SMTP submission runs on
its own lane, independent of the IMAP command connection, so a long folder
sync or a command the server is slow to answer never delays a message you
pressed Send on. Only the copy into Sent (and the removal of the autosaved
draft) needs IMAP; those follow through the normal queue, which also runs
between folders during the periodic other-folders pass instead of after it.
A folder sync that runs past 60 s is logged with its duration and counts.

### Dark mode for HTML mail

With a dark app theme, HTML mail is re-coloured onto a dark page the way
mail apps' dark modes do: light greyish backgrounds become dark greys, dark
text becomes light, saturated brand colours (status bars, buttons) stay with
their own text, pastel tints are deepened and dark accents lifted so links
stay readable; images are untouched. "Original formatting" in the message
menu still shows the author's colours on a white page.

### Meeting invitations

A mail that carries a `text/calendar` part (inline alternative as Exchange
and Google send it, or an `.ics` attachment) shows an invitation card above
the body: title, time, place, organizer, and Accept / Tentative / Decline.
Answering mails the organizer an iTIP `METHOD:REPLY` (as a
`text/calendar; method=REPLY` alternative plus `reply.ics`), which Exchange,
Google and most calendar servers apply automatically, and puts the event in
a local "Invitations" calendar unless a synced calendar already has it.
With more than one writable calendar, Accept / Tentative / Add ask which one
(the last choice is offered first) and the event is created through the
calendar service, so a Google or CalDAV calendar receives it.
"Add without replying" keeps the event with no answer sent; calendar objects
without an organizer (METHOD:PUBLISH or none) get a plain "Add to calendar".
Cancellations show a card with "Remove from calendar"; replies to your own
invitations show who answered what. The answer is remembered per device.
Mail with no calendar part at all (a Teams block pasted into a message, a
date in the text) has "Add to calendar" in the message menu: it opens the
event editor pre-filled with the subject, the text, the meeting link and the
first date and time the text mentions.

### New folders and the Trash

The rule advisor also reads the Trash: mail deleted in the last four months
becomes "deleted" evidence (once per message), so a sender or list you keep
throwing away can be offered a folder instead. When a clear group fits none
of your folders, the advisor may propose a new one; the suggestion shows
"(new folder)" and Accept creates the folder on the server before adding the
rule. The model says where it belongs: under INBOX for mail you act on, at
the top level for reference material, or as a subfolder of one of your
folders; the card lets you flip between those before accepting. About once a
month (or on "Ask now" after a day) the advisor also reviews every folder
with enough mail and proposes subfolders where one folder mixes distinct
kinds; accepting such a split can also move the parent's matching mail into
the new subfolder. Nothing is created or moved until you accept, and the
advisor never proposes a rule that deletes.

### Reviewing a draft with AI

The compose window has a "Review with AI" button (the wand). It sends the
text you wrote, not your signature or the quoted message, to the configured
AI backend with an optional instruction ("shorter", "more formal", ...) and
shows the suggested revision with a list of changes. Pick the depth:
Proofread (spelling and grammar only), Improve (the default: also clarity,
structure, tone, an explicit ask, and anything the reader will need; gaps
the model cannot fill become `[placeholders]` and "Needs your input" notes,
never guesses) or Rewrite (the best version of the email from what you meant
to say). Your signature goes along as context about who you are, and so
does the current date and time, so a call dated yesterday is written up as
something that happened rather than something coming up. Under the revision
there is a "Not quite right?" box: tell it what it got wrong ("the call
already happened", "we agreed on Friday") and it revises again with every
earlier correction still in force; the exchange stays visible until you use
the revision or start over. Both the review and Blabber are told never to
use em dashes, en dashes or double hyphens, and whatever still slips
through is turned into a comma or dropped before you see it. For a reply, the message
being answered and up to three earlier messages of the thread (from the local
cache, their own quoted tails stripped) go along as context, so the revision
answers what was asked and keeps names and dates straight; "Use revision" swaps
it in, leaving the signature and quote untouched, and can also apply a
better subject. It needs an AI backend under Settings → AI backend, honours
the pause switch and spend caps, and is counted in the usage meter.

### All inboxes and swiping conversations

With more than one account, the folder rail gets an "All inboxes" entry (and
the app opens there): every account's INBOX in one list, each row tagged with
its account, conversations built per account so the same mail arriving in two
accounts never merges, and each account's folders listed under its name in
the rail. Actions work as usual; moving mail asks you to pick messages from
one account at a time. On phones, swiping a row right deletes it and left
archives it, and swiping a collapsed conversation header does the same for
the whole conversation (your own copies in Sent stay).

Reply headers: enough_mail folds any header longer than 76 columns and, with
no space inside a long Outlook Message-ID, used to split the id itself, so
our replies did not thread for the recipient and a fragment such as
`d13.prod.outlook.com` could join two unrelated tickets in Sortie. The
composer now re-folds In-Reply-To and References only between ids, and the
parser and the threading code drop whitespace inside an id.

### Blabber: say it, Sortie writes it

Blabber turns rough thoughts into a finished email. On a phone, tap the
microphone in the compose toolbar (or the small mic button above Compose in
the inbox, which opens a new message straight into dictation) and talk: the
phone's own dictation (Apple or Google, on the device) transcribes what you
say, fillers and all, and keeps listening through pauses until you tap Stop.
"Make the email" sends the transcript, an optional instruction ("formal",
"two short paragraphs") and, for a reply, the thread being answered to the
configured AI backend, which writes the email in your voice: fillers and
false starts dropped, self-corrections ("actually Thursday") applied, nothing
invented. You see the subject, the email and the model's notes, can keep
talking or try again, and "Use it" puts the text into the composer above
your signature (and above the quote in a reply). Nothing is ever sent by
itself; the normal Send button still does that. On desktop there is no
dictation yet (Linux has no recogniser; Windows voice is not enabled), so
the Blabber button opens the same sheet with a text box to type or paste
into. Only the transcript leaves the device, to the AI backend you chose;
the audio never does. The first use asks for the microphone and speech
recognition permissions. Blabber honours the pause switch and the spend
caps and shows in the usage meter as "blabber".

## Releases

Tag `vX.Y.Z` and push. Four workflows build Linux (tar.gz), Windows (zip), Android
(signed APKs) and iOS (unsigned ipa) and attach them to the GitHub release. The same
workflows also run weekly so Windows/iOS regressions surface early.
