//
//  SettingsView.swift
//  Glimpse
//
//  Settings window with General and Appearance tabs.
//

import SwiftUI
import ServiceManagement
import UserNotifications

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView(appState: appState)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "questionmark.circle")
                }
        }
        .frame(width: 400, height: 280)
    }
}

// MARK: - General Settings

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

                Toggle("Confirm before skipping", isOn: $appState.skipConfirmation)
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

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @Bindable var appState: AppState

    /// Curated overlay colors ordered light to dark
    static let colorPresets: [(name: String, hex: String)] = [
        ("Buttercream", "F6E6B4"),
        ("Peach", "FFDAB9"),
        ("Blush", "F4C2C2"),
        ("Cloud", "D6D6D6"),
        ("Lilac", "D5B8F0"),
        ("Mauve", "C9A9D4"),
        ("Fog", "C8CDD0"),
        ("Lavender", "C3B1E1"),
        ("Sage", "B7C9A8"),
        ("Powder", "B6D0E2"),
        ("Aquamarine", "5BDDAF"),
        ("Periwinkle", "A6B1E1"),
        ("Sand", "E2D4B7"),
        ("Rose", "E8A0BF"),
        ("Seafoam", "A0D2DB"),
        ("Sky", "A0C4FF"),
        ("Graphite", "3A3A3C"),
        ("Slate", "2F3640"),
        ("Ember", "3B1A0B"),
        ("Wine", "3B1529"),
        ("Plum", "2D1B3D"),
        ("Espresso", "2C1A0E"),
        ("Charcoal", "2B2B2B"),
        ("Storm", "1C2526"),
        ("Eclipse", "1A1A40"),
        ("Midnight", "1A1A2E"),
        ("Indigo", "1B1464"),
        ("Deep Navy", "0F1B2D"),
        ("Forest", "0B2B1F"),
        ("Obsidian", "0B0B0F"),
        ("Deep Teal", "0A2F2F"),
        ("Ocean", "0A1628"),
    ]

    /// Index of the currently selected color (or nearest match)
    private var selectedIndex: Int {
        let hex = appState.overlayColorHex.uppercased()
        return Self.colorPresets.firstIndex(where: { $0.hex.uppercased() == hex }) ?? 0
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overlay color: \(Self.colorPresets[selectedIndex].name)")
                    ColorSlider(
                        colors: Self.colorPresets.map { Color(hex: $0.hex) },
                        selectedIndex: selectedIndex,
                        onSelect: { index in
                            appState.overlayColorHex = Self.colorPresets[index].hex
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Overlay opacity: \(Int(appState.overlayOpacity * 100))%")
                    Slider(
                        value: $appState.overlayOpacity,
                        in: Constants.minOverlayOpacity...Constants.maxOverlayOpacity,
                        step: 0.05
                    )
                }

                Button("Reset to Defaults") {
                    appState.overlayColorHex = Constants.defaultOverlayColorHex
                    appState.overlayOpacity = Constants.defaultOverlayOpacity
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Color Slider

/// A discrete slider that displays color swatches in a squircle track.
struct ColorSlider: View {
    let colors: [Color]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let count = colors.count
            let segmentWidth = geo.size.width / CGFloat(count)

            ZStack(alignment: .leading) {
                // Gradient track — squircle shape
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { i in
                        colors[i]
                    }
                }
                .frame(height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Selection indicator
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(.white, lineWidth: 2.5)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .frame(width: max(segmentWidth + 4, 16), height: 32)
                    .offset(x: CGFloat(selectedIndex) * segmentWidth + segmentWidth / 2 - max(segmentWidth + 4, 16) / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let index = Int(value.location.x / segmentWidth)
                        let clamped = max(0, min(count - 1, index))
                        if clamped != selectedIndex {
                            onSelect(clamped)
                        }
                    }
            )
        }
        .frame(height: 32)
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Glimpse")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Glimpse follows the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds. It's a simple habit recommended by eye care professionals to reduce digital eye strain.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .padding()
    }
}

#Preview {
    SettingsView(appState: AppState())
}
