//
//  GeneralSettingsView.swift
//  Glimpse
//
//  General tab: launch at login, timing, break style, and behavior toggles.
//

import SwiftUI
import ServiceManagement
import UserNotifications

struct GeneralSettingsView: View {
    @Bindable var appState: AppState
    @State private var notificationStatus: UNAuthorizationStatus?

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { appState.launchAtLogin },
                    set: { newValue in
                        appState.launchAtLogin = newValue
                        updateLaunchAtLogin(newValue)
                    }
                ))
            }

            Section("Timing") {
                Picker("Work interval", selection: Binding(
                    get: { appState.workDuration },
                    set: { appState.workDuration = $0 }
                )) {
                    ForEach(Constants.workDurationPresets, id: \.self) { duration in
                        Text(formatDuration(duration)).tag(duration)
                    }
                }

                Picker("Break duration", selection: Binding(
                    get: { appState.breakDuration },
                    set: { appState.breakDuration = $0 }
                )) {
                    ForEach(Constants.breakDurationPresets, id: \.self) { duration in
                        Text(formatBreakDuration(duration)).tag(duration)
                    }
                }
            }

            Section {
                Picker("Break style", selection: Binding(
                    get: { appState.breakStyle },
                    set: { newValue in
                        appState.breakStyle = newValue
                        if newValue == .notification {
                            NotificationManager.shared.requestPermission()
                            // Re-check status after a brief delay for the dialog
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                refreshNotificationStatus()
                            }
                        }
                    }
                )) {
                    ForEach(BreakStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }

                if appState.breakStyle == .notification, let status = notificationStatus, status == .denied {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Notifications are disabled.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Open Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .font(.caption)
                    }
                }

                Toggle("Heads-up notification before break", isOn: $appState.headsUpNotification)

                Toggle("Hold break while typing", isOn: $appState.holdBreakWhileTyping)
                    .help("Waits up to a minute for a pause in typing before starting a break")

                Toggle("Confirm before skipping", isOn: $appState.skipConfirmation)

                Toggle("Play sound on break completion", isOn: $appState.playSoundOnBreakEnd)

                Toggle("Show countdown in menu bar", isOn: $appState.showMenuBarTimer)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            refreshNotificationStatus()
        }
    }

    private func refreshNotificationStatus() {
        NotificationManager.shared.checkAuthorizationStatus { status in
            notificationStatus = status
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        return "\(minutes) min"
    }

    private func formatBreakDuration(_ seconds: TimeInterval) -> String {
        let secs = Int(seconds)
        if secs >= 60 {
            let mins = secs / 60
            let remainder = secs % 60
            return remainder > 0 ? "\(mins) min \(remainder) sec" : "\(mins) min"
        }
        return "\(secs) sec"
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            DebugLog.log("Failed to update launch at login: \(error)")
        }
    }
}

#Preview {
    GeneralSettingsView(appState: AppState())
}
