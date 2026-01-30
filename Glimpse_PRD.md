# Glimpse — Product Requirements Document

**Version:** 1.0  
**Author:** Aman Wakankar  
**Date:** January 2025  
**Tagline:** Protect your eyes with a glimpse.

---

## 1. Overview

Glimpse is a macOS menu bar application that helps users practice the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds. The app provides gentle-but-firm interruptions via a full-screen semi-opaque overlay with a countdown timer, encouraging users to take meaningful eye breaks.

### 1.1 Problem Statement

Screen workers (developers, students, designers) experience digital eye strain from prolonged screen use. The 20-20-20 rule is clinically recommended but difficult to remember. Existing solutions either use ignorable notifications or lack visual polish and customization.

### 1.2 Target Users

- Students and knowledge workers spending 6+ hours daily on screens
- Health-conscious individuals who want accountability
- Users who find gentle notifications too easy to ignore

### 1.3 Success Metrics

- Project completed and deployed to GitHub with downloadable release
- Personal daily usage for 2+ weeks
- Functional portfolio piece demonstrating Swift/macOS development

---

## 2. User Experience

### 2.1 First Launch

1. App opens with menu bar icon (eye symbol) — no dock icon
2. Brief onboarding tooltip: "Glimpse will remind you to look away every 20 minutes. Click the eye to pause or adjust settings."
3. Timer begins immediately

### 2.2 Core Loop

1. User works normally for 20 minutes
2. Full-screen overlay appears with:
   - Blurred background
   - Semi-opaque color layer (purple dark mode / white light mode)
   - Large centered countdown timer (20 → 0)
   - Motivational message at top
   - Skip button at bottom
3. After 20 seconds, overlay automatically dismisses
4. Cycle repeats

### 2.3 Menu Bar Interactions

Clicking the eye icon reveals a popover with:

- **Status:** "Next break in 12:34" or "Paused"
- **Pause/Resume button:** Toggle timer
- **Skip to break:** Trigger overlay immediately
- **Streak display:** "🔥 7 breaks today"
- **Settings gear icon:** Opens settings panel

### 2.4 Overlay Behavior

| Scenario | Behavior |
|----------|----------|
| User waits 20 seconds | Overlay dismisses, streak increments |
| User clicks Skip | Overlay dismisses, streak does NOT increment |
| User clicks Skip twice consecutively | Normal dismiss |
| User clicks Skip third time in a row (if friction enabled) | "Are you sure?" confirmation appears |
| Full-screen app active (e.g., game) | Falls back to system notification |
| Multiple monitors connected | Overlay appears on ALL screens |

### 2.5 Messages

The overlay displays a random message from a curated list. Messages should be:
- Brief (under 10 words)
- Varied in tone (encouraging, playful, direct)
- Occasionally surprising (rare messages at ~2% probability)

**Standard messages (25):**
1. "Look at something far away."
2. "Find a window. Look outside."
3. "Rest your eyes for a moment."
4. "Look at the horizon."
5. "Give your eyes a break."
6. "Focus on something distant."
7. "Let your eyes relax."
8. "Gaze into the distance."
9. "Look away from the screen."
10. "Your eyes will thank you."
11. "20 seconds of rest."
12. "Find the farthest point you can see."
13. "Breathe. Look away."
14. "A small break for healthier eyes."
15. "Stretch your vision."
16. "Look up from the screen."
17. "Take a visual break."
18. "Rest. Refocus. Return."
19. "Look at something 20 feet away."
20. "Pause and look around."
21. "Soft eyes. Deep breath."
22. "Give your focus a rest."
23. "Look beyond your screen."
24. "A moment for your eyes."
25. "Blink. Breathe. Look away."

**Rare messages (5, ~2% probability each):**
1. "Don't blink. Blink and you're dead." (Doctor Who reference)
2. "The eyes are the window to the soul. Clean your windows."
3. "Plot twist: the 20 feet was inside you all along."
4. "Your optometrist would be proud."
5. "Achievement unlocked: Self Care."

---

## 3. Features

### 3.1 Core Features (v1.0)

| Feature | Description | Priority |
|---------|-------------|----------|
| Menu bar presence | Eye icon, no dock icon | P0 |
| 20-minute timer | Countdown to next break | P0 |
| Full-screen overlay | Blurred, colored, centered timer | P0 |
| Skip button | Dismiss overlay early | P0 |
| Pause/Resume | Toggle from menu bar | P0 |
| Streak tracking | Count consecutive breaks taken | P0 |
| Settings panel | Color, mode, friction toggle | P0 |
| Notification fallback | When overlay cannot display | P0 |
| Multi-monitor support | Overlay on all screens | P0 |
| Message rotation | Random message each break | P0 |

### 3.2 Settings

| Setting | Options | Default |
|---------|---------|---------|
| Appearance | Dark (purple) / Light (white) / Custom color | System preference |
| Break style | Overlay / Notification only | Overlay |
| Skip friction | Off / On ("Are you sure?" on 3rd consecutive skip) | Off |
| Launch at login | On / Off | Off |
| Overlay opacity | Slider (50% - 90%) | 75% |

### 3.3 Out of Scope (v1.0)

- Standing reminders
- Hydration reminders
- iOS companion app
- iCloud sync
- Audio cues
- Custom user messages
- Analytics/telemetry
- App Store distribution (GitHub release only)

---

## 4. Design Specifications

### 4.1 Menu Bar Icon

- SF Symbol: `eye` (default state)
- SF Symbol: `eye.slash` (paused state)
- No text label

### 4.2 Overlay Visual Design

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                                                             │
│                    "Look at the horizon."                   │
│                         (message)                           │
│                                                             │
│                                                             │
│                           14                                │
│                     (large timer)                           │
│                                                             │
│                                                             │
│                         [ Skip ]                            │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

- **Background:** Blurred (NSVisualEffectView or equivalent)
- **Color layer:** Semi-opaque, user-configurable
- **Timer font:** System font, ultra-light weight, ~200pt
- **Message font:** System font, regular weight, ~24pt
- **Skip button:** Minimal, text-only style, ~16pt

### 4.3 Settings Panel

Native macOS settings window with sections:
- Appearance (color picker, opacity slider)
- Behavior (overlay vs notification, friction toggle)
- General (launch at login)

---

## 5. Edge Cases

| Scenario | Handling |
|----------|----------|
| App launched while overlay should be showing | Start fresh 20-min timer |
| Computer sleeps during countdown | Pause timer, resume on wake |
| User has multiple Spaces | Overlay appears on current Space only |
| Accessibility: screen reader active | Announce message via VoiceOver |
| User force-quits during overlay | Overlay dismisses with app |

---

## 6. Future Considerations (v2+)

- Customizable interval (not just 20 minutes)
- Customizable break duration (not just 20 seconds)
- Standing/hydration reminders
- iOS companion with notifications
- Widgets for streak display
- Menu bar countdown text option
- Statistics view (breaks taken this week, streaks)

---

## 7. Release Checklist

- [ ] App runs from menu bar without dock icon
- [ ] 20-minute timer functions correctly
- [ ] Overlay displays on all monitors
- [ ] Overlay falls back to notification when needed
- [ ] Skip button works
- [ ] Streak increments correctly
- [ ] Settings persist across launches
- [ ] Launch at login works
- [ ] README with screenshots
- [ ] GitHub release with signed .app or .dmg
