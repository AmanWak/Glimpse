# Glimpse

> Protect your eyes with a glimpse.

Glimpse is a macOS menu bar application that helps you practice the **20-20-20 rule**: every 20 minutes, look at something 20 feet away for 20 seconds. The app provides gentle-but-firm interruptions via a full-screen semi-opaque overlay with a countdown timer, encouraging you to take meaningful eye breaks.

![Glimpse Icon](Glimpse/Assets.xcassets/AppIcon.appiconset/AppIcon.png)

## Features

### Core Functionality
- **Menu Bar Integration**: Lives in your menu bar with no dock icon
- **20-Minute Timer**: Automatic countdown to your next break
- **Full-Screen Overlay**: Blurred, semi-transparent overlay that appears on all monitors
- **Motivational Messages**: 30 curated messages (25 standard + 5 rare surprises)
- **Skip Button**: Dismiss breaks early when needed
- **Pause/Resume**: Control the timer from the menu bar
- **Streak Tracking**: Count and celebrate your breaks throughout the day
- **Multi-Monitor Support**: Overlay appears on all connected screens

### Customization
- **Appearance Modes**: Dark (purple), Light (white), or Custom color
- **Opacity Control**: Adjust overlay transparency (50%-90%)
- **Break Style**: Choose between full-screen overlay or system notifications
- **Skip Friction**: Optional confirmation after 2 consecutive skips
- **Launch at Login**: Start automatically when you log in

## Installation

### Requirements
- macOS 12.0 (Monterey) or later
- Xcode 15.0 or later (for building from source)

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/AmanWak/Glimpse.git
   cd Glimpse
   ```

2. Open the project in Xcode:
   ```bash
   open Glimpse.xcodeproj
   ```

3. Build and run the project:
   - Select the "Glimpse" scheme
   - Press `Cmd + R` to build and run

4. (Optional) Archive and export for distribution:
   - Product → Archive
   - Distribute App → Copy App

## Usage

### First Launch
1. Launch Glimpse - it will appear in your menu bar with an eye icon
2. The 20-minute timer begins immediately
3. Click the eye icon to view status and settings

### During Work
- The timer counts down in the background
- Click the eye icon to check time remaining
- Use Pause/Resume as needed

### Break Time
- A full-screen overlay appears after 20 minutes
- A motivational message and countdown (20 → 0) is displayed
- Wait 20 seconds for the break to complete automatically
- Or click "Skip" to dismiss early

### Menu Bar Popover
Click the eye icon to access:
- **Status**: Time until next break or "Paused"
- **Pause/Resume**: Toggle the timer
- **Skip to Break**: Trigger overlay immediately
- **Streak**: Daily break counter with 🔥 emoji
- **Settings**: Open preferences panel

### Settings Panel
Configure the app to your preferences:

**Appearance**
- Choose Dark, Light, System, or Custom color mode
- Adjust overlay opacity with a slider

**Behavior**
- Select Overlay or Notification-only break style
- Enable Skip Friction for confirmation after repeated skips

**General**
- Toggle Launch at Login
- View app version and information

## The 20-20-20 Rule

The 20-20-20 rule is a simple eye care practice recommended by optometrists:

> **Every 20 minutes, look at something 20 feet away for 20 seconds.**

This helps reduce digital eye strain, dry eyes, and fatigue caused by prolonged screen use.

## Development

### Architecture
- **AppDelegate**: Menu bar lifecycle and app coordination
- **TimerManager**: 20-minute interval and break countdown logic
- **OverlayWindowController**: Full-screen overlay window management
- **SettingsManager**: User preferences persistence (UserDefaults)
- **StreakTracker**: Daily break counting and skip tracking
- **MessageProvider**: Random message selection with rare message probability
- **NotificationManager**: System notification fallback

### Testing
Run unit tests:
```bash
xcodebuild test -scheme Glimpse -destination 'platform=macOS'
```

Or use Xcode:
- Press `Cmd + U` to run all tests

### Contributing
Contributions are welcome! Please feel free to submit issues or pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Privacy

Glimpse respects your privacy:
- ✅ All data stored locally (no cloud sync)
- ✅ No analytics or telemetry
- ✅ No network requests
- ✅ App-sandboxed for security
- ✅ Open source - you can verify the code

## License

Copyright © 2025 Aman Wakankar. All rights reserved.

## Acknowledgments

- Inspired by the clinical recommendation for the 20-20-20 rule
- Built with SwiftUI and AppKit for macOS
- Menu bar design follows Apple's Human Interface Guidelines

## Support

Found a bug or have a feature request?
- Open an issue on [GitHub](https://github.com/AmanWak/Glimpse/issues)
- Contact: [Your contact info]

---

**Remember: Your eyes will thank you!** 👁️✨
