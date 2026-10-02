<p align="center">
  <img src="assets/app-icon.png" alt="Glimpse" width="128" height="128">
</p>

<h1 align="center">Glimpse</h1>

<p align="center">
  <strong>A free, native macOS menu bar app for the 20-20-20 rule.</strong><br>
  Every 20 minutes, look at something 20 feet away for 20 seconds —<br>
  and Glimpse knows when <em>not</em> to interrupt you.
</p>

<p align="center">
  <a href="https://github.com/AmanWak/Glimpse/releases/latest"><img src="https://img.shields.io/github/v/release/AmanWak/Glimpse?label=release" alt="Latest release"></a>
  <a href="https://github.com/AmanWak/Glimpse/actions/workflows/ci.yml"><img src="https://github.com/AmanWak/Glimpse/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/macOS-26.1%2B-blue" alt="macOS 26.1+">
  <img src="https://img.shields.io/badge/SwiftUI%20%2B%20AppKit-native-orange" alt="Native SwiftUI + AppKit">
  <img src="https://img.shields.io/badge/dependencies-zero-lightgrey" alt="Zero dependencies">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/AmanWak/Glimpse" alt="MIT License"></a>
</p>

---

| Menu Bar Popover | Full-Screen Overlay | Settings |
|:---:|:---:|:---:|
| ![Menu bar popover](assets/screenshots/popover.png) | ![Break overlay](assets/screenshots/overlay.png) | ![Settings window](assets/screenshots/settings.png) |

## Why Glimpse

I was getting dry eyes from staring at a screen all day while working on computer science
projects. Most break reminders fix that by interrupting you at the worst possible moment,
so they get uninstalled. Glimpse tries to be the one you keep:

- **Lives in your notch.** Breaks can appear as a small Live-Activity-style pill that eases
  out of the MacBook notch, instead of taking over the screen.
- **Waits until you stop typing.** A due break holds off (up to a minute) for a natural
  pause in your keystrokes, so it never lands mid-sentence.
- **Stays out of meetings and games.** Breaks pause automatically while a watched app
  (Zoom, Teams, Slack, Steam, …) or a game is in front, or while a game controller is connected.
- **Tiny and private.** Native Swift, ~2 MB, zero third-party dependencies. No account,
  no analytics, no network calls.
- **Free.** No subscription, no paid tier, MIT-licensed.

## Features

### Break styles
- **Notch pill** — a Live-Activity-style countdown at the MacBook notch (top-center on Macs without one)
- **Full-screen overlay** — blur, 32 curated colors, adjustable opacity, countdown, skip button, Esc to skip
- **Floating banner** — a lighter interruption that follows your cursor
- **Notification only** — for people who just want a nudge

### Knows when not to interrupt
- **Hold break while typing** (on by default)
- **App-aware pause** — one list covering meeting apps, game launchers, and any app you add
- **Game pause** — breaks hold while a game is the frontmost app, no setup needed
- **Controller pause** — breaks hold while a game controller is connected
- **Sleep-aware** — a long sleep resets the timer instead of firing a stale break on wake
- **Snooze** for 1–4 hours from the menu bar

### Habit support
- Completed breaks today and a 7-day history at a glance
- Consecutive-skip counter, with optional confirmation after repeated skips
- Heads-up notification 30 seconds before a break
- Curated break messages (eye care, posture, breathing, movement), plus your own notes

### Settings
- Work interval 5–60 min, break length 10–120 s
- Menu bar countdown, launch at login, completion sound

## Installation

### Download

Grab the latest build from the [Releases page](https://github.com/AmanWak/Glimpse/releases/latest),
unzip it, and move **Glimpse.app** to `/Applications`.

Glimpse isn't notarized yet, so macOS blocks it the first time you open it:

1. Open Glimpse once and dismiss the warning.
2. Go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**.

> **Note:** The current release (v1.2) predates notch mode, hold-while-typing, app/game/controller
> pause, snooze, and the 7-day history. Those are on `main` and will ship in the next release —
> [build from source](#build-from-source) to try them now.

### Build From Source

Requires Xcode 26 or later.

```bash
git clone https://github.com/AmanWak/Glimpse.git
cd Glimpse
open Glimpse.xcodeproj
```

Build with ⌘B and run with ⌘R, or from the command line:

```bash
xcodebuild build -scheme Glimpse -destination 'platform=macOS'
```

## How It Works

1. Glimpse runs a work timer for your chosen interval.
2. With 30 seconds left, it can send a heads-up notification.
3. When the timer hits zero, it checks whether now is a good moment — not typing, no watched
   app or game in front, no controller connected — and starts the break in your chosen style.
4. Completing a break counts toward today's total; skipping one counts toward the skip streak.
5. The next work cycle starts automatically.

## Privacy

Glimpse makes no network requests and collects nothing. Settings and your break history are
stored locally in `UserDefaults`. Typing detection reads only the time since your last
keypress (via `CGEventSource`) — never which keys — so it needs no Accessibility or Input
Monitoring permission.

## Known Limitations

- Browser-based meetings such as Google Meet aren't detected by app-aware pause yet.
- The deployment target is macOS 26.1, though most of the APIs Glimpse uses exist on earlier
  versions.
- No iCloud sync, accounts, or App Store distribution — by design, for now.

## Tech Stack

| | |
|---|---|
| **Language** | Swift |
| **UI** | SwiftUI + AppKit (`NSHostingView` overlay windows) |
| **Frameworks** | SwiftUI, AppKit, UserNotifications, ServiceManagement, GameController |
| **Testing** | Swift Testing — 127 unit tests |
| **Dependencies** | None |

## Contributing

Bug reports and ideas are welcome — please [open an issue](https://github.com/AmanWak/Glimpse/issues/new/choose).
See [CONTRIBUTING.md](CONTRIBUTING.md) before sending a pull request.

## License

[MIT](LICENSE) © 2026 Aman Wakankar
