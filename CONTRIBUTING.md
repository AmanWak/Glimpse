# Contributing to Glimpse

Thanks for taking a look. Glimpse is a small, solo-maintained project, so a little
coordination up front goes a long way.

## Before you start

- **Bugs:** open an issue with the bug template. Steps to reproduce, break style, and
  your macOS version make it much easier to fix.
- **Features:** open a feature request first, before writing code. Glimpse deliberately
  stays small: no accounts, sync, analytics, or network calls. Ideas that keep it that
  way are the most likely to land.

## Building

Requires Xcode 26 or later.

```bash
open Glimpse.xcodeproj          # ⌘B to build, ⌘R to run, ⌘U to test
```

Or from the command line:

```bash
xcodebuild build -scheme Glimpse -destination 'platform=macOS'
xcodebuild test  -scheme Glimpse -destination 'platform=macOS'
```

## How the code is organized

Glimpse uses a coordinator/callback pattern rather than MVVM:

- **`GlimpseApp`** is the coordinator. It owns the managers and wires them together
  with closures; all orchestration (start/skip/complete break, pause, snooze, sleep/wake,
  auto-pause) lives there.
- **`AppState`** (`@Observable @MainActor`) is the single source of truth.
- **Managers** (`TimerManager`, `OverlayManager`, `NotchManager`, `AppWatcher`, …) are
  plain classes that report through `on…` callbacks. They never reference `AppState`.

## Rules for overlay, banner, and notch windows

These exist because breaking them caused real crashes and main-thread deadlocks:

- Views hosted in `NSHostingView` (`OverlayView`, `BannerView`, `NotchView`) take only
  **plain values** (`Int`, `String`, `Color`, …), never `AppState` or any `@Observable`
  object. The manager owns the countdown and rebuilds the view each tick.
- No `@State`, Combine, `.animation()`, or `.contentTransition()` inside those views.
- To dismiss a window: invalidate timers → set `rootView` to `AnyView(EmptyView())` →
  `orderOut(nil)` → drop the reference. **Never** call `contentView = nil` or `close()`.
- Show windows with `orderFront(nil)`, not `makeKeyAndOrderFront` (the first overlay
  window is the one intentional exception, because ESC-to-skip needs a key window).
- Defer timer-completion callbacks and the Skip action with `DispatchQueue.main.async`.

## Code style

- 4-space indentation, no tabs.
- Every file starts with the standard header (file name, `Glimpse`, one-line purpose,
  no author or date).
- Types in PascalCase; functions camelCase and verb-first (`startWorkTimer`, `hideOverlay`).
- Match the surrounding code; there's no linter, so consistency is on us.

## Tests

Unit tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest:

- One file per type: `AppStateTests.swift`, test types are `struct`s.
- Each test builds its own instances. No shared setup.
- Models and pure-logic managers are tested; views and window-bound managers aren't.

Tests run hosted inside the app, against real `UserDefaults`. If a test touches
settings, save and restore only the keys it owns.

## Pull requests

- Keep each PR to one change, with a short description of what and why.
- Make sure the build and tests pass (CI runs both).
- For anything visual, include a screenshot or a short screen recording.
