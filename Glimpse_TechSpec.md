# Glimpse — Technical Specification

**Version:** 1.0  
**Platform:** macOS 13.0+ (Ventura and later)  
**Language:** Swift 5.9+  
**UI Framework:** SwiftUI  
**Architecture:** Single-target macOS app, menu bar only

---

## 1. Project Structure

```
Glimpse/
├── Glimpse.xcodeproj
├── Glimpse/
│   ├── GlimpseApp.swift              # App entry point, MenuBarExtra
│   ├── Models/
│   │   ├── AppState.swift            # Observable app state
│   │   ├── BreakStreak.swift         # Streak tracking logic
│   │   └── Messages.swift            # Hardcoded message arrays
│   ├── Managers/
│   │   ├── TimerManager.swift        # 20-min countdown logic
│   │   ├── OverlayManager.swift      # Window creation/display
│   │   └── SettingsManager.swift     # UserDefaults wrapper
│   ├── Views/
│   │   ├── MenuBarView.swift         # Popover content
│   │   ├── OverlayView.swift         # Full-screen overlay UI
│   │   ├── SettingsView.swift        # Settings window
│   │   └── Components/
│   │       ├── CountdownTimerView.swift
│   │       ├── SkipButton.swift
│   │       └── MessageView.swift
│   ├── Utilities/
│   │   ├── Constants.swift           # Timing constants, colors
│   │   └── NSScreen+Extensions.swift # Multi-monitor helpers
│   ├── Resources/
│   │   └── Assets.xcassets
│   └── Info.plist
├── GlimpseTests/
│   └── TimerManagerTests.swift
├── README.md
├── LICENSE
└── .gitignore
```

---

## 2. Core Components

### 2.1 GlimpseApp.swift (Entry Point)

```swift
import SwiftUI

@main
struct GlimpseApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isPaused ? "eye.slash" : "eye")
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
```

**Key decisions:**
- `MenuBarExtra` (macOS 13+) for native menu bar presence
- `.menuBarExtraStyle(.window)` for popover behavior
- No `WindowGroup` — app has no main window
- `LSUIElement = YES` in Info.plist to hide dock icon

### 2.2 AppState.swift (Observable State)

```swift
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    // Timer state
    @Published var isPaused: Bool = false
    @Published var secondsUntilBreak: Int = 1200  // 20 minutes
    @Published var isOverlayVisible: Bool = false
    @Published var breakSecondsRemaining: Int = 20
    
    // Streak state
    @Published var todayStreak: Int = 0
    @Published var consecutiveSkips: Int = 0
    
    // Settings (loaded from UserDefaults)
    @AppStorage("overlayOpacity") var overlayOpacity: Double = 0.75
    @AppStorage("useDarkMode") var useDarkMode: Bool = true
    @AppStorage("useOverlay") var useOverlay: Bool = true
    @AppStorage("skipFrictionEnabled") var skipFrictionEnabled: Bool = false
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("customColorHex") var customColorHex: String = ""
    
    // Managers
    let timerManager: TimerManager
    let overlayManager: OverlayManager
    
    init() {
        self.timerManager = TimerManager()
        self.overlayManager = OverlayManager()
        // Wire up timer callbacks
    }
}
```

### 2.3 TimerManager.swift

```swift
import Foundation
import Combine

class TimerManager: ObservableObject {
    private var workTimer: Timer?
    private var breakTimer: Timer?
    
    var onWorkTimerComplete: (() -> Void)?
    var onBreakTimerComplete: (() -> Void)?
    var onWorkTimerTick: ((Int) -> Void)?
    var onBreakTimerTick: ((Int) -> Void)?
    
    private var workSecondsRemaining: Int = 1200
    private var breakSecondsRemaining: Int = 20
    
    func startWorkTimer() {
        workSecondsRemaining = 1200  // 20 minutes
        workTimer?.invalidate()
        workTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.workSecondsRemaining -= 1
            self.onWorkTimerTick?(self.workSecondsRemaining)
            
            if self.workSecondsRemaining <= 0 {
                self.workTimer?.invalidate()
                self.onWorkTimerComplete?()
            }
        }
    }
    
    func startBreakTimer() {
        breakSecondsRemaining = 20
        breakTimer?.invalidate()
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.breakSecondsRemaining -= 1
            self.onBreakTimerTick?(self.breakSecondsRemaining)
            
            if self.breakSecondsRemaining <= 0 {
                self.breakTimer?.invalidate()
                self.onBreakTimerComplete?()
            }
        }
    }
    
    func pause() {
        workTimer?.invalidate()
        breakTimer?.invalidate()
    }
    
    func resume() {
        startWorkTimer()
    }
    
    func skipBreak() {
        breakTimer?.invalidate()
    }
}
```

### 2.4 OverlayManager.swift

```swift
import AppKit
import SwiftUI

class OverlayManager {
    private var overlayWindows: [NSWindow] = []
    
    func showOverlay(content: some View) {
        // Create overlay on each screen
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen, content: content)
            overlayWindows.append(window)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func dismissOverlay() {
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
    }
    
    private func createOverlayWindow<Content: View>(for screen: NSScreen, content: Content) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver  // Above most windows
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(rootView: content)
        window.contentView = hostingView
        
        return window
    }
    
    func canShowOverlay() -> Bool {
        // Check if any full-screen app is active
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return true
        }
        
        // Check active window for full-screen mode
        if let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] {
            for windowInfo in windows {
                if let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                   ownerPID == frontmostApp.processIdentifier,
                   let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
                   let screen = NSScreen.main {
                    // Compare window bounds to screen bounds
                    // If equal, likely full-screen app
                    let windowHeight = bounds["Height"] as? CGFloat ?? 0
                    let screenHeight = screen.frame.height
                    if windowHeight >= screenHeight {
                        return false
                    }
                }
            }
        }
        return true
    }
}
```

### 2.5 OverlayView.swift

```swift
import SwiftUI

struct OverlayView: View {
    @EnvironmentObject var appState: AppState
    let message: String
    let onSkip: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Blur effect
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
            
            // Color overlay
            overlayColor
                .opacity(appState.overlayOpacity)
            
            // Content
            VStack(spacing: 60) {
                Spacer()
                
                // Message
                Text(message)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white)
                
                // Timer
                Text("\(appState.breakSecondsRemaining)")
                    .font(.system(size: 200, weight: .ultraLight))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                // Skip button
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    private var overlayColor: Color {
        if !appState.customColorHex.isEmpty {
            return Color(hex: appState.customColorHex) ?? defaultColor
        }
        return defaultColor
    }
    
    private var defaultColor: Color {
        appState.useDarkMode ? Color(red: 0.2, green: 0.1, blue: 0.3) : Color.white
    }
}

// NSVisualEffectView wrapper for blur
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
```

### 2.6 Messages.swift

```swift
import Foundation

struct Messages {
    static let standard: [String] = [
        "Look at something far away.",
        "Find a window. Look outside.",
        "Rest your eyes for a moment.",
        "Look at the horizon.",
        "Give your eyes a break.",
        "Focus on something distant.",
        "Let your eyes relax.",
        "Gaze into the distance.",
        "Look away from the screen.",
        "Your eyes will thank you.",
        "20 seconds of rest.",
        "Find the farthest point you can see.",
        "Breathe. Look away.",
        "A small break for healthier eyes.",
        "Stretch your vision.",
        "Look up from the screen.",
        "Take a visual break.",
        "Rest. Refocus. Return.",
        "Look at something 20 feet away.",
        "Pause and look around.",
        "Soft eyes. Deep breath.",
        "Give your focus a rest.",
        "Look beyond your screen.",
        "A moment for your eyes.",
        "Blink. Breathe. Look away."
    ]
    
    static let rare: [String] = [
        "Don't blink. Blink and you're dead.",
        "The eyes are the window to the soul. Clean your windows.",
        "Plot twist: the 20 feet was inside you all along.",
        "Your optometrist would be proud.",
        "Achievement unlocked: Self Care."
    ]
    
    static func random() -> String {
        // 10% chance for rare message (2% each for 5 messages)
        if Double.random(in: 0...1) < 0.10 {
            return rare.randomElement() ?? standard[0]
        }
        return standard.randomElement() ?? standard[0]
    }
}
```

### 2.7 MenuBarView.swift

```swift
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status
            Text(statusText)
                .font(.headline)
            
            // Streak
            HStack {
                Text("🔥")
                Text("\(appState.todayStreak) breaks today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Pause/Resume
            Button(action: togglePause) {
                Label(
                    appState.isPaused ? "Resume" : "Pause",
                    systemImage: appState.isPaused ? "play.fill" : "pause.fill"
                )
            }
            
            // Skip to break
            Button(action: triggerBreak) {
                Label("Take a break now", systemImage: "eye")
            }
            .disabled(appState.isPaused)
            
            Divider()
            
            // Settings
            SettingsLink {
                Label("Settings...", systemImage: "gear")
            }
            
            Divider()
            
            // Quit
            Button("Quit Glimpse") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 220)
    }
    
    private var statusText: String {
        if appState.isPaused {
            return "Paused"
        }
        let minutes = appState.secondsUntilBreak / 60
        let seconds = appState.secondsUntilBreak % 60
        return String(format: "Next break in %d:%02d", minutes, seconds)
    }
    
    private func togglePause() {
        appState.isPaused.toggle()
        if appState.isPaused {
            appState.timerManager.pause()
        } else {
            appState.timerManager.resume()
        }
    }
    
    private func triggerBreak() {
        // Trigger overlay immediately
        appState.timerManager.pause()
        // Show overlay logic
    }
}
```

### 2.8 SettingsView.swift

```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
        }
        .frame(width: 400, height: 250)
        .environmentObject(appState)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $appState.launchAtLogin)
            
            Picker("Break style", selection: $appState.useOverlay) {
                Text("Full-screen overlay").tag(true)
                Text("Notification only").tag(false)
            }
            
            Toggle("Ask \"Are you sure?\" after 2 consecutive skips", isOn: $appState.skipFrictionEnabled)
        }
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Form {
            Picker("Theme", selection: $appState.useDarkMode) {
                Text("Dark (Purple)").tag(true)
                Text("Light (White)").tag(false)
            }
            
            HStack {
                Text("Overlay opacity")
                Slider(value: $appState.overlayOpacity, in: 0.5...0.9)
                Text("\(Int(appState.overlayOpacity * 100))%")
                    .frame(width: 40)
            }
            
            ColorPicker("Custom color", selection: customColorBinding)
        }
        .padding()
    }
    
    private var customColorBinding: Binding<Color> {
        // Convert hex string to Color and back
        Binding(
            get: { Color(hex: appState.customColorHex) ?? .purple },
            set: { appState.customColorHex = $0.toHex() ?? "" }
        )
    }
}
```

---

## 3. Info.plist Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleName</key>
    <string>Glimpse</string>
    <key>CFBundleDisplayName</key>
    <string>Glimpse</string>
    <key>CFBundleIdentifier</key>
    <string>com.amanwakankar.glimpse</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
```

**Critical:** `LSUIElement = true` hides the app from the Dock.

---

## 4. Notification Fallback

```swift
import UserNotifications

class NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            // Handle result
        }
    }
    
    static func sendBreakNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time for a break"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

---

## 5. Launch at Login

```swift
import ServiceManagement

func setLaunchAtLogin(enabled: Bool) {
    do {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    } catch {
        print("Failed to set launch at login: \(error)")
    }
}
```

Requires macOS 13+ for `SMAppService`.

---

## 6. Sleep/Wake Handling

```swift
import Combine

class SleepWakeHandler {
    private var cancellables = Set<AnyCancellable>()
    
    var onWake: (() -> Void)?
    var onSleep: (() -> Void)?
    
    init() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                self?.onSleep?()
            }
            .store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.onWake?()
            }
            .store(in: &cancellables)
    }
}
```

---

## 7. Color Extension

```swift
import SwiftUI

extension Color {
    init?(hex: String) {
        guard !hex.isEmpty else { return nil }
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
    
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
```

---

## 8. Testing Strategy

| Component | Test Cases |
|-----------|------------|
| TimerManager | Timer counts down correctly, callbacks fire at 0, pause/resume works |
| Messages | `random()` returns valid strings, rare messages appear at expected rate |
| OverlayManager | Windows created for all screens, dismissed correctly |
| AppState | UserDefaults persist, streak resets at midnight |
| SkipFriction | Counter increments, resets after successful break |

---

## 9. Build & Distribution

### Development signing:
```bash
# In Xcode: Signing & Capabilities
# Team: Personal Team (free)
# Signing Certificate: Sign to Run Locally
```

### Release build:
```bash
xcodebuild -scheme Glimpse -configuration Release archive
```

### GitHub Release:
1. Archive in Xcode
2. Export as "Copy App" (Developer ID signed if available)
3. Create .dmg or .zip
4. Upload to GitHub Releases

---

## 10. Dependencies

**None.** Pure SwiftUI + AppKit. No external packages required.
