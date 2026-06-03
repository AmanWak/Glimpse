<p align="center">
  <img src="assets/app-icon.png" alt="Glimpse" width="128" height="128">
</p>

<h1 align="center">Glimpse</h1>

<p align="center">
  A native macOS menu bar app for eye breaks and the 20-20-20 rule.<br>
  Every 20 minutes, look at something 20 feet away for 20 seconds.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2026.1%2B-blue" alt="macOS 26.1+">
  <img src="https://img.shields.io/badge/swift-5.9%2B-orange" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/price-free-brightgreen" alt="Free">
  <img src="https://img.shields.io/badge/dependencies-zero-lightgrey" alt="Zero dependencies">
</p>

---

## Current Status

Glimpse is a personal, self-published macOS app. The current local project is version `1.2` and is configured with a `macOS 26.1` deployment target in Xcode. Earlier macOS support may be possible, but it is not what the project currently declares.

The app is not distributed through the Mac App Store and is not currently presented here as a notarized commercial release. If you download or build it yourself, macOS may require the usual self-published app approval flow.

## Why I Built This

I was getting dry eyes from staring at a screen all day while working on computer science projects. Glimpse is my attempt at a lightweight, native Mac utility that makes eye breaks harder to ignore without adding accounts, subscriptions, analytics, or a heavy productivity workflow.

## Screenshots

| Menu Bar Popover | Full-Screen Overlay | Settings |
|:---:|:---:|:---:|
| ![Menu bar popover](assets/screenshots/popover.png) | ![Break overlay](assets/screenshots/overlay.png) | ![Settings window](assets/screenshots/settings.png) |

> Note: screenshots may lag the current local build. The app currently includes additional settings for app-aware pause, notes, timing, sound, and menu-bar countdown behavior.

## Features

### Break Reminders
- **Full-screen overlay** with blur, configurable color, configurable opacity, countdown, skip button, and Esc-to-skip behavior
- **Floating banner mode** for a lighter interruption that follows the cursor during breaks
- **Notification-only mode** for users who prefer system notifications
- **Heads-up notification** 30 seconds before a break, if enabled
- **Skip confirmation** after repeated skips, if enabled

### Menu Bar Workflow
- Menu-bar-only app with no Dock icon
- Optional live countdown in the menu bar
- Pause/resume from the popover
- Snooze for 1-4 hours
- Start a break early
- Quit directly from the popover

### Tracking And Habit Support
- Completed-break count for the current day
- Consecutive-skip counter
- Curated break messages across eye care, posture, breathing, movement, and rare/fun variants
- Optional notes shown during overlay breaks, with editable user notes

### Settings
- Work interval presets from 5-60 minutes
- Break duration presets from 10-120 seconds
- Break style: full-screen overlay, floating banner, or notification only
- 32 curated overlay colors
- Overlay opacity from 50%-100%
- Launch at login
- Heads-up notifications
- Sound on break completion
- Menu-bar countdown visibility
- App-aware pause for selected running apps such as Zoom, Teams, Slack, FaceTime, Discord, and custom running apps

## Known Limitations

- Browser-based meetings such as Google Meet are not auto-detected by the current app-aware pause implementation.
- The README release link has intentionally been removed until the release artifact/version is verified.
- The project target currently says macOS 26.1, even though some APIs used by the app are available on earlier macOS versions.
- There is no analytics dashboard, weekly history, iCloud sync, account system, or App Store distribution.
- `Refocus` is only a documented future concept in `Refocus_Feature_Plan.md`; it is not implemented.

## Installation

### Build From Source

Requires Xcode with support for the project's current macOS deployment target.

```bash
git clone https://github.com/AmanWak/Glimpse.git
cd Glimpse
open Glimpse.xcodeproj
```

Build with Cmd+B and run with Cmd+R.

Or from the command line:

```bash
xcodebuild build -scheme Glimpse -destination 'platform=macOS'
```

## How It Works

1. Glimpse starts a work timer using the selected work interval.
2. At 30 seconds remaining, it can send a heads-up notification.
3. When the timer reaches zero, it starts a break using the selected break style.
4. Completing the break increments today's completed-break count.
5. Skipping the break increments the consecutive-skip count instead.
6. The next work cycle starts automatically.

## Tech Stack

| | |
|---|---|
| **Language** | Swift 5.9+ |
| **UI** | SwiftUI + AppKit |
| **Frameworks** | SwiftUI, AppKit, UserNotifications, ServiceManagement |
| **Architecture** | Observable app state with callback-driven managers |
| **Testing** | Swift Testing framework |
| **Dependencies** | None |

## License

MIT
