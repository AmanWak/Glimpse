# Glimpse — CLAUDE.md

## Project Overview

Glimpse is a macOS menu bar app that implements the 20-20-20 eye health rule: every 20 minutes, look at something 20 feet away for 20 seconds. It displays a full-screen overlay during breaks.

- **Platform:** macOS 14+ (uses `@Observable`, `MenuBarExtra`)
- **UI:** SwiftUI + AppKit hybrid (NSHostingView for overlay windows)
- **Build system:** Xcode only (`Glimpse.xcodeproj`), no SPM/CocoaPods
- **Dependencies:** Zero external — Apple frameworks only (SwiftUI, AppKit, Combine, Foundation, UserNotifications, ServiceManagement)
- **Bundle ID:** `amanW.Glimpse`
- **LSUIElement:** YES (no Dock icon, no Cmd+Tab entry)

## Build & Test Commands

```bash
# Build
xcodebuild build -scheme Glimpse -destination 'platform=macOS'

# Run all unit tests
xcodebuild test -scheme Glimpse -destination 'platform=macOS'

# Run a single test file (example)
xcodebuild test -scheme Glimpse -destination 'platform=macOS' -only-testing:GlimpseTests/AppStateTests

# Run a single test method (example)
xcodebuild test -scheme Glimpse -destination 'platform=macOS' -only-testing:GlimpseTests/AppStateTests/testInitialState
```

Or use Xcode: Cmd+B (build), Cmd+U (run tests).

## Project Structure

```
Glimpse/
├── GlimpseApp.swift              # @main entry point + coordinator logic
├── Models/
│   ├── AppState.swift            # @Observable @MainActor — single source of truth
│   ├── BreakStreak.swift         # Daily break streak tracking (Codable struct)
│   └── Messages.swift            # Curated break reminder messages
├── Managers/
│   ├── TimerManager.swift        # Work/break timer (plain class, callbacks)
│   ├── OverlayManager.swift      # NSWindow-based overlay windows
│   └── NotificationManager.swift # UNUserNotificationCenter wrapper (singleton)
├── Views/
│   ├── OverlayView.swift         # Full-screen break overlay
│   ├── MenuBarView.swift         # Menu bar popover
│   ├── SettingsView.swift        # Settings window (General + Appearance)
│   └── Components/
│       ├── CountdownTimerView.swift
│       ├── SkipButton.swift
│       ├── MessageView.swift
│       └── VisualEffectBlur.swift  # NSViewRepresentable
├── Utilities/
│   ├── Constants.swift           # Timing values, UserDefaults keys
│   ├── Color+Hex.swift           # Color <-> hex string extension
│   └── SleepWakeHandler.swift    # System sleep/wake observer
GlimpseTests/
├── AppStateTests.swift           # 16 tests
├── TimerManagerTests.swift       # 9 tests
├── BreakStreakTests.swift        # 9 tests
├── ColorHexTests.swift           # 8 tests
└── MessagesTests.swift           # 7 tests
```

## Architecture

**Coordinator/callback pattern** — not MVVM or MVC.

- **`GlimpseApp`** is the coordinator. It wires AppState, TimerManager, OverlayManager, and SleepWakeHandler via closures. All orchestration logic (start break, complete break, skip, pause/resume) lives here.
- **`AppState`** (`@Observable @MainActor final class`) is the single source of truth.
- **Managers** are plain classes that communicate via callback closures (`onTick`, `onWorkComplete`, `onBreakComplete`, `onSleep`, `onWake`, `onDismiss`). They do NOT reference AppState.
- **`NotificationManager`** is a singleton (`NotificationManager.shared`).

### Critical: Overlay Snapshot Pattern

The overlay uses a **snapshot pattern** to prevent EXC_BAD_ACCESS crashes:

- `OverlayView` receives only **primitive values** (`Int`, `Color`, `Double`, `String`, `Bool`) at creation — never `AppState`.
- It manages its own countdown with `@State` + `Timer.publish`.
- Zero `@Observable` observation registrations = zero zombie callback crashes on NSWindow teardown.

**Do NOT pass `AppState` or any `@Observable` object into views hosted in `NSHostingView`.** This is a hard rule.

### NSHostingView Teardown Order

When dismissing overlay windows, follow this exact sequence synchronously:
1. Replace rootView with `EmptyView()`
2. Set `contentView = nil`
3. `orderOut(nil)` then `close()`
4. Mutate `@Observable` state AFTER teardown

### Other AppKit Rules

- Use `window.orderFront(nil)` — NOT `makeKeyAndOrderFront` (don't steal focus)
- `.alert()` does NOT work on borderless `NSWindow` — use inline SwiftUI UI
- Avoid `.animation()` and `.contentTransition()` inside NSHostingView overlays
- Skip button defers `skipBreak()` via `DispatchQueue.main.async` to avoid closing NSWindow from within its own button action

## Code Style

### Formatting
- **4 spaces** indentation (no tabs)
- No SwiftLint or formatter configured

### File Headers
```swift
//
//  FileName.swift
//  Glimpse
//
//  One-line description of the file's purpose.
//
```
No author/date lines. Description only.

### Naming
- **Types:** PascalCase (`AppState`, `TimerManager`, `OverlayView`)
- **Functions:** camelCase, imperative verb-first (`startWorkTimer`, `hideOverlay`)
- **Properties:** camelCase (`secondsRemaining`, `overlayColorHex`)
- **Booleans:** prefixed with `is`/`was`/`has` (`isBreakTimer`, `wasRunningBeforeSleep`)
- **Callbacks:** `on`-prefixed (`onTick`, `onSkip`, `onDismiss`)
- **Constants:** nested enums in `Constants` (`Constants.workDuration`, `Constants.Keys.breakStreak`)
- **Extension files:** `Type+Feature.swift` (`Color+Hex.swift`)

### Access Control
- All classes are `final class`
- Implicit `internal` (no explicit `internal` keyword)
- `private` for implementation details
- No `public`/`open` (single-module app)

### Organization
- `// MARK: -` sections to organize files (e.g., `// MARK: - Runtime State`, `// MARK: - Methods`)
- `///` doc comments on properties and methods
- `//` inline comments for non-obvious logic

### Imports
- Minimal imports at file top, no blank lines between them
- Common: `import SwiftUI`, adding `import AppKit`/`import Combine`/`import ServiceManagement` only as needed

### Structs vs Classes
- **Structs:** All SwiftUI views, data models (`BreakStreak`), namespacing enums (`Constants`, `Messages`)
- **Classes:** Managers and `AppState` (need reference semantics, identity, or `@Observable`)

## Testing

### Framework
**Swift Testing** (`import Testing`, `@Test` macro) — not XCTest for unit tests.

### Conventions
- Test files: `{ClassName}Tests.swift`
- Test structs (not classes): `struct AppStateTests { ... }`
- Test methods: `@Test func testDescriptiveName()`
- Assertions: `#expect(value == expected)` (not XCTAssert)
- `@testable import Glimpse` in all test files
- `@MainActor` on test structs that test `@MainActor` types
- Each test creates its own instances — no shared setup/teardown
- Async tests use `async throws` with `try await Task.sleep`

### What to Test
- Models and managers have tests; views and the coordinator (`GlimpseApp`) do not
- Test state transitions, edge cases, computed properties, encoding/decoding

## Key Constants (from `Constants.swift`)

| Constant | Value | Description |
|----------|-------|-------------|
| `workDuration` | 1200s (20 min) | Work interval |
| `breakDuration` | 20s | Break interval |
| `defaultOverlayOpacity` | 0.85 | Overlay background opacity |
| `defaultOverlayColor` | "1A1A2E" | Dark navy/purple hex |
| `timerTickInterval` | 1.0s | Timer tick rate |

## Git Conventions

- **Branch:** `main` is the primary branch
- **Commit style:** Imperative verb-first subject line, optional detailed body with bullet points
- **No auto-commits** — only commit when explicitly asked
