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
    let onSkipToBreak: () -> Void
    let onSkipBreak: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status header
            HStack {
                Image("MenuBarIcon")
                    .resizable()
                    .frame(width: 20, height: 20)
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

            Divider()

            // Controls
            HStack {
                Button {
                    onPauseResume()
                } label: {
                    Label(
                        appState.mode == .paused ? "Resume" : "Pause",
                        systemImage: appState.mode == .paused ? "play.fill" : "pause.fill"
                    )
                }

                Spacer()

                if appState.mode == .working {
                    Button {
                        onSkipToBreak()
                    } label: {
                        Label("Take Break Now", systemImage: "eye.fill")
                    }
                }

                if appState.mode == .onBreak && !appState.isOverlayShowing {
                    Button {
                        onSkipBreak()
                    } label: {
                        Label("Skip Break", systemImage: "forward.fill")
                    }
                }
            }
            .buttonStyle(.bordered)

            Divider()

            // Settings and Quit
            HStack {
                Button {
                    openSettings()
                    NSApp.activate()
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
    }
}

#Preview {
    MenuBarView(
        appState: AppState(),
        onPauseResume: {},
        onSkipToBreak: {},
        onSkipBreak: {},
        onQuit: {}
    )
}
