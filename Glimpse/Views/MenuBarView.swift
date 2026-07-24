//
//  MenuBarView.swift
//  Glimpse
//
//  Menu bar popover showing status, streak, and controls.
//

import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    @Environment(\.openSettings) private var openSettings
    let onPauseResume: () -> Void
    let onSnooze: (_ hours: Int) -> Void
    let onSkipToBreak: () -> Void
    let onSkipBreak: () -> Void
    let onQuit: () -> Void

    @State private var showingSnoozeOptions = false
    @State private var snoozeTimerTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status header
            HStack {
                Image("MenuBarIcon")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Glimpse")
                        .font(.headline)
                    Text(appState.statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.bottom, 4)

            Divider()

            // Streak info
            HStack {
                Label("\(appState.streak.completedToday) breaks today", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "5BDDAF"))
                Spacer()
            }
            .font(.callout)

            if appState.streak.consecutiveSkips > 0 {
                HStack {
                    Label("\(appState.streak.consecutiveSkips) skipped in a row", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(hex: "E8837C"))
                    Spacer()
                }
                .font(.callout)
            }

            // Last 7 days mini-chart — only once there's history beyond today
            if appState.streak.dailyHistory.count > 1 {
                SevenDayHistoryView(counts: appState.streak.lastSevenDays())
            }

            Divider()

            // Controls — equal-width buttons
            HStack(spacing: 8) {
                Button {
                    onPauseResume()
                } label: {
                    Label(
                        appState.mode == .paused ? "Resume" : "Pause",
                        systemImage: appState.mode == .paused ? "play.fill" : "pause.fill"
                    )
                    .frame(maxWidth: .infinity)
                }

                if appState.mode == .working {
                    Button {
                        onSkipToBreak()
                    } label: {
                        Label {
                            Text("Take Break")
                        } icon: {
                            Image("MenuBarIcon")
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                if appState.mode == .onBreak && !appState.isOverlayShowing {
                    Button {
                        onSkipBreak()
                    } label: {
                        Label("Skip Break", systemImage: "forward.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(.bordered)

            // Snooze
            if appState.mode != .paused {
                if showingSnoozeOptions {
                    HStack(spacing: 6) {
                        ForEach([1, 2, 3, 4], id: \.self) { hours in
                            Button {
                                dismissSnoozeOptions()
                                onSnooze(hours)
                            } label: {
                                Text("\(hours)h")
                                    .font(.system(size: 12, weight: .medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    Button {
                        showingSnoozeOptions = true
                        startSnoozeAutoHideTimer()
                    } label: {
                        Label("Snooze", systemImage: "moon.zzz.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            // Settings and Quit
            HStack {
                Button {
                    openSettings()
                    NSApp.activate(ignoringOtherApps: true)
                    if let settingsWindow = NSApp.windows.first(where: { $0.title == "Settings" }) {
                        settingsWindow.makeKeyAndOrderFront(nil)
                    }
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(role: .destructive) {
                    onQuit()
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 280)
        .onDisappear {
            dismissSnoozeOptions()
        }
    }

    private func startSnoozeAutoHideTimer() {
        snoozeTimerTask?.cancel()
        snoozeTimerTask = Task {
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            guard !Task.isCancelled else { return }
            showingSnoozeOptions = false
        }
    }

    private func dismissSnoozeOptions() {
        snoozeTimerTask?.cancel()
        snoozeTimerTask = nil
        showingSnoozeOptions = false
    }
}

/// Compact bar row showing completed breaks for the last 7 days (today rightmost).
private struct SevenDayHistoryView: View {
    let counts: [Int]

    private var maxCount: Int { max(counts.max() ?? 0, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(counts.enumerated()), id: \.offset) { _, count in
                RoundedRectangle(cornerRadius: 2)
                    .fill(count > 0 ? Color(hex: "5BDDAF") : Color.secondary.opacity(0.25))
                    .frame(width: 14, height: count > 0 ? max(6, 22 * CGFloat(count) / CGFloat(maxCount)) : 3)
                    .help(count == 1 ? "1 break" : "\(count) breaks")
            }
            Spacer()
            Text("Last 7 days")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MenuBarView(
        appState: AppState(),
        onPauseResume: {},
        onSnooze: { _ in },
        onSkipToBreak: {},
        onSkipBreak: {},
        onQuit: {}
    )
}
