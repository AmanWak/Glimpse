# Prompting Claude Code for Glimpse

This guide explains how to effectively use Claude Code alongside Xcode to build Glimpse.

---

## Setup

### 1. Create Project in Xcode First

Before using Claude Code, create the project skeleton in Xcode:

1. Open Xcode → File → New → Project
2. Select **macOS → App**
3. Configure:
   - Product Name: `Glimpse`
   - Team: Your personal team
   - Organization Identifier: `com.amanwakankar`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck "Include Tests" (add later)
4. Save to your preferred location
5. Delete `ContentView.swift` (we won't use it)

### 2. Add These Files to Claude Code Context

Copy `Glimpse_PRD.md` and `Glimpse_TechSpec.md` into your project folder. When starting Claude Code:

```bash
cd ~/path/to/Glimpse
claude
```

Then in Claude Code:
```
/add Glimpse_PRD.md Glimpse_TechSpec.md
```

This gives Claude Code full context on what you're building.

---

## Prompting Strategy

### Golden Rule: One Component at a Time

Don't ask for the entire app. Build iteratively:

```
❌ "Build the entire Glimpse app"
✅ "Create GlimpseApp.swift with MenuBarExtra setup"
```

### Always Reference the Spec

```
✅ "Following the tech spec, create TimerManager.swift with the work timer and break timer logic"
✅ "Based on the PRD, implement the 25 standard messages and 5 rare messages in Messages.swift"
```

---

## Prompt Sequence

Use these prompts in order. After each, review the code in Xcode, test it, then proceed.

### Phase 1: Core Structure

**Prompt 1: App Entry Point**
```
Create GlimpseApp.swift following the tech spec. It should:
- Use MenuBarExtra with an eye SF Symbol
- Toggle between eye and eye.slash based on paused state
- Use .menuBarExtraStyle(.window)
- Include a Settings scene
- Create an @StateObject for AppState (just reference it, we'll create it next)
```

**Prompt 2: App State**
```
Create Models/AppState.swift as an ObservableObject with:
- @Published properties for isPaused, secondsUntilBreak, isOverlayVisible, breakSecondsRemaining
- @Published streak tracking: todayStreak, consecutiveSkips
- @AppStorage properties for all settings from the tech spec
- Initialize TimerManager and OverlayManager (we'll create these next)
Make it @MainActor.
```

**Prompt 3: Timer Manager**
```
Create Managers/TimerManager.swift exactly as specified in the tech spec. Include:
- workTimer and breakTimer using Foundation Timer
- Callbacks: onWorkTimerComplete, onBreakTimerComplete, onWorkTimerTick, onBreakTimerTick
- startWorkTimer(), startBreakTimer(), pause(), resume(), skipBreak()
- 1200 seconds for work, 20 seconds for break
```

**Prompt 4: Messages**
```
Create Models/Messages.swift with:
- static let standard: [String] containing all 25 messages from the PRD
- static let rare: [String] containing all 5 rare messages from the PRD
- static func random() -> String that has 10% chance to return rare message
```

### Phase 2: Menu Bar UI

**Prompt 5: Menu Bar View**
```
Create Views/MenuBarView.swift following the tech spec. It should show:
- Status text: "Next break in X:XX" or "Paused"
- Streak display: "🔥 X breaks today"
- Pause/Resume button with play.fill/pause.fill icons
- "Take a break now" button
- SettingsLink
- Quit button
Frame width 220, inject AppState via @EnvironmentObject
```

**Prompt 6: Wire Up Menu Bar**
```
Update GlimpseApp.swift to:
1. Create AppState as @StateObject
2. Pass it to MenuBarView via environmentObject
3. Update the menu bar icon to read appState.isPaused for eye vs eye.slash
```

**Test checkpoint:** Build and run. You should see the eye icon in menu bar. Clicking should show the popover with status and buttons.

### Phase 3: Settings

**Prompt 7: Settings Views**
```
Create Views/SettingsView.swift with:
- TabView containing GeneralSettingsView and AppearanceSettingsView
- GeneralSettingsView: launch at login toggle, break style picker (overlay vs notification), skip friction toggle
- AppearanceSettingsView: theme picker (dark/light), opacity slider (50-90%), color picker
- Frame 400x250
All settings should bind to AppState's @AppStorage properties
```

**Prompt 8: Color Extension**
```
Create Utilities/Color+Hex.swift with the Color extension from the tech spec for hex string conversion.
```

**Test checkpoint:** Open Settings, change values, quit app, reopen. Settings should persist.

### Phase 4: Overlay System

**Prompt 9: Overlay Manager**
```
Create Managers/OverlayManager.swift following the tech spec exactly:
- Array of NSWindow for multi-monitor
- showOverlay(content:) creates borderless window for each NSScreen.screens
- Window level .screenSaver, collection behavior canJoinAllSpaces
- dismissOverlay() closes all windows
- canShowOverlay() checks for full-screen apps
```

**Prompt 10: Visual Effect Blur**
```
Create Views/Components/VisualEffectBlur.swift - an NSViewRepresentable wrapping NSVisualEffectView with configurable material and blendingMode.
```

**Prompt 11: Overlay View**
```
Create Views/OverlayView.swift:
- ZStack with VisualEffectBlur background, color overlay with opacity
- VStack with message text (24pt), timer text (200pt ultraLight), Skip button
- Read colors from AppState (dark purple default, white for light mode, or custom hex)
- Take message: String, onSkip: () -> Void, onComplete: () -> Void as parameters
Use the exact layout from the tech spec's ASCII diagram.
```

### Phase 5: Integration

**Prompt 12: Connect Everything**
```
Update AppState to:
1. Initialize TimerManager with callbacks wired to show/hide overlay
2. When onWorkTimerComplete fires: 
   - Check overlayManager.canShowOverlay()
   - If yes, show OverlayView with random message, start break timer
   - If no, send notification instead
3. When break completes naturally: increment streak, reset consecutiveSkips, restart work timer
4. When skip pressed: increment consecutiveSkips, check if friction needed, dismiss overlay, restart work timer
5. Start work timer on init
```

**Prompt 13: Skip Friction Logic**
```
Add to OverlayView:
- @State showConfirmation = false
- When skip pressed and appState.skipFrictionEnabled and consecutiveSkips >= 2:
  - Show "Are you sure?" confirmation instead of immediate skip
- Otherwise skip normally
```

**Prompt 14: Notification Fallback**
```
Create Managers/NotificationManager.swift with:
- requestPermission() using UNUserNotificationCenter
- sendBreakNotification(message:) that sends immediate local notification
Call requestPermission() on app launch.
```

### Phase 6: Polish

**Prompt 15: Sleep/Wake Handling**
```
Create Utilities/SleepWakeHandler.swift that listens to NSWorkspace willSleepNotification and didWakeNotification.
Wire it into AppState to pause timer on sleep, resume on wake.
```

**Prompt 16: Launch at Login**
```
Add to AppState a function setLaunchAtLogin(enabled:) using SMAppService.mainApp.register/unregister.
Call it when launchAtLogin @AppStorage changes using .onChange modifier.
```

**Prompt 17: Streak Reset at Midnight**
```
Add logic to AppState to reset todayStreak to 0 when the date changes.
Store last active date in UserDefaults, check on app launch and periodically.
```

**Prompt 18: Info.plist**
```
What changes do I need in Info.plist to:
1. Hide dock icon (LSUIElement)
2. Set minimum macOS version to 13.0
3. Set bundle identifier to com.amanwakankar.glimpse
```

---

## Debugging Prompts

When something breaks:

```
"The overlay isn't appearing. Here's my OverlayManager code: [paste code]. The showOverlay function is being called but no window appears. What's wrong?"
```

```
"The timer keeps running even when I click pause. Here's my TimerManager and how I'm calling it from AppState: [paste both]. How do I fix this?"
```

```
"Build error: 'Cannot find AppState in scope' in MenuBarView. I have @EnvironmentObject var appState: AppState but it's not working."
```

Always provide:
1. The specific error or unexpected behavior
2. The relevant code
3. What you expected to happen

---

## Testing Prompts

```
"Write unit tests for TimerManager that verify:
1. Work timer counts down from 1200
2. Break timer counts down from 20
3. Pause stops both timers
4. Callbacks fire at completion"
```

```
"Write a test for Messages.random() that verifies rare messages appear roughly 10% of the time over 1000 iterations."
```

---

## Final Prompts

**README Generation:**
```
Generate a README.md for Glimpse with:
- Project description and tagline
- Screenshot placeholder
- Features list
- Installation instructions (download from releases)
- Build from source instructions
- Tech stack
- License (MIT)
```

**Release Checklist:**
```
What are the exact steps to:
1. Archive Glimpse in Xcode
2. Export it as a distributable app
3. Create a DMG
4. Upload to GitHub Releases
```

---

## Tips

1. **Copy-paste from Xcode to Claude Code** when you need help fixing something
2. **Test after every prompt** - don't stack up multiple changes
3. **Keep the tech spec open** in another window for reference
4. **Use `/clear`** in Claude Code if context gets cluttered
5. **Commit after each working feature** - easy rollback if something breaks
