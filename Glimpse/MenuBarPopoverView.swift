//
//  MenuBarPopoverView.swift
//  Glimpse
//
//  Popover UI shown when clicking the menu bar icon
//

import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject var timerManager: TimerManager?
    @ObservedObject private var streakTracker = StreakTracker.shared
    
    let onSkipToBreak: () -> Void
    let onTogglePause: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "eye")
                    .font(.title2)
                    .accessibilityHidden(true)
                Text("Glimpse")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Glimpse menu")
            
            Divider()
            
            // Status
            VStack(spacing: 8) {
                if let timerManager = timerManager {
                    if timerManager.isPaused {
                        Text("Paused")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    } else if timerManager.isOnBreak {
                        Text("Break in progress")
                            .font(.title3)
                        Text("\(timerManager.timeRemainingFormatted)")
                            .font(.system(.title, design: .monospaced))
                    } else {
                        Text("Next break in")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text(timerManager.timeRemainingFormatted)
                            .font(.system(.title, design: .monospaced))
                    }
                }
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // Actions
            VStack(spacing: 12) {
                // Pause/Resume
                Button(action: onTogglePause) {
                    HStack {
                        Image(systemName: timerManager?.isPaused == true ? "play.fill" : "pause.fill")
                        Text(timerManager?.isPaused == true ? "Resume" : "Pause")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(timerManager?.isPaused == true ? "Resume timer" : "Pause timer")
                .accessibilityHint("Controls the break reminder timer")
                
                // Skip to break
                if timerManager?.isPaused == false && timerManager?.isOnBreak == false {
                    Button(action: onSkipToBreak) {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip to Break")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Skip to break now")
                    .accessibilityHint("Immediately trigger the break reminder")
                }
                
                Divider()
                
                // Streak
                HStack {
                    Text(streakTracker.streakEmoji.isEmpty ? "No breaks yet today" : streakTracker.streakEmoji)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Divider()
                
                // Settings
                Button(action: onOpenSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .frame(width: 280)
    }
}

#Preview {
    MenuBarPopoverView(
        timerManager: nil,
        onSkipToBreak: {},
        onTogglePause: {},
        onOpenSettings: {}
    )
}
