//
//  SettingsView.swift
//  Glimpse
//
//  Settings window with General and Appearance tabs.
//

import SwiftUI
import ServiceManagement
import UserNotifications

// MARK: - Tab Enum

private enum Tab: Int, CaseIterable {
    case general, appearance, apps, notes, about

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .apps: "Apps"
        case .notes: "Notes"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .general: "gear"
        case .appearance: "paintbrush"
        case .apps: "app.badge.checkmark"
        case .notes: "list.bullet.rectangle"
        case .about: "questionmark.circle"
        }
    }
}

struct SettingsView: View {
    @Bindable var appState: AppState

    @State private var selectedTab: Tab = .general

    var body: some View {
        let overlayColor = Color(hex: appState.overlayColorHex)

        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                            Text(tab.title)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .foregroundStyle(selectedTab == tab ? overlayColor : .secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedTab == tab ? overlayColor : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(.bar)

            Divider()

            Group {
                switch selectedTab {
                case .general:    GeneralSettingsView(appState: appState)
                case .appearance: AppearanceSettingsView(appState: appState)
                case .apps:       AppsSettingsView()
                case .notes:      NotesSettingsView(appState: appState)
                case .about:      AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .tint(overlayColor)
        .background(overlayColor.opacity(0.07))
        .frame(width: 400, height: 430)
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

                // Selection indicator — bulges out around the selected swatch
                let indicatorWidth = segmentWidth + 10
                ZStack {
                    colors[selectedIndex]
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.white, lineWidth: 2.5)
                    RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                        .strokeBorder(.black.opacity(0.5), lineWidth: 0.5)
                        .padding(2.5)
                }
                .frame(width: indicatorWidth, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)
                .offset(x: CGFloat(selectedIndex) * segmentWidth + segmentWidth / 2 - indicatorWidth / 2)
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

// MARK: - Apps Settings

struct AppsSettingsView: View {
    @State private var enabled = UserDefaults.standard.bool(forKey: Constants.Keys.appAwarePauseEnabled)
    @State private var watchedIDs = AppWatcher.loadWatchedBundleIDs()

    private var presetBundleIDs: Set<String> {
        Set(Constants.watchableAppPresets.map(\.bundleID))
    }

    /// Custom apps added by the user (not in the preset list)
    private var customApps: [(name: String, bundleID: String)] {
        watchedIDs
            .filter { !presetBundleIDs.contains($0) }
            .sorted()
            .map { id in
                let name = NSWorkspace.shared.runningApplications
                    .first(where: { $0.bundleIdentifier == id })?
                    .localizedName ?? id
                return (name: name, bundleID: id)
            }
    }

    /// Running apps available to add (regular GUI apps, not already watched, not Glimpse)
    private var availableRunningApps: [(name: String, bundleID: String)] {
        NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular
                    && app.bundleIdentifier != nil
                    && app.bundleIdentifier != Bundle.main.bundleIdentifier
                    && !watchedIDs.contains(app.bundleIdentifier!)
                    && !presetBundleIDs.contains(app.bundleIdentifier!)
            }
            .compactMap { app in
                guard let id = app.bundleIdentifier else { return nil }
                return (name: app.localizedName ?? id, bundleID: id)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Form {
            Section {
                Toggle("Pause during meetings", isOn: $enabled)
                    .onChange(of: enabled) {
                        UserDefaults.standard.set(enabled, forKey: Constants.Keys.appAwarePauseEnabled)
                    }
            }

            if enabled {
                Section("Common apps") {
                    ForEach(Constants.watchableAppPresets, id: \.bundleID) { preset in
                        Toggle(preset.name, isOn: Binding(
                            get: { watchedIDs.contains(preset.bundleID) },
                            set: { isOn in
                                if isOn {
                                    watchedIDs.insert(preset.bundleID)
                                } else {
                                    watchedIDs.remove(preset.bundleID)
                                }
                                AppWatcher.saveWatchedBundleIDs(watchedIDs)
                            }
                        ))
                    }
                }

                if !customApps.isEmpty {
                    Section("Other apps") {
                        ForEach(customApps, id: \.bundleID) { app in
                            HStack {
                                Text(app.name)
                                Spacer()
                                Button {
                                    watchedIDs.remove(app.bundleID)
                                    AppWatcher.saveWatchedBundleIDs(watchedIDs)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section {
                    let apps = availableRunningApps
                    if apps.isEmpty {
                        Text("No other apps running to add")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        Menu("Add from running apps...") {
                            ForEach(apps, id: \.bundleID) { app in
                                Button(app.name) {
                                    watchedIDs.insert(app.bundleID)
                                    AppWatcher.saveWatchedBundleIDs(watchedIDs)
                                }
                            }
                        }
                    }

                    Text("Browser-based meetings (Google Meet) cannot be auto-detected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Notes Settings

struct NotesSettingsView: View {
    @Bindable var appState: AppState
    @State private var newNote: String = ""

    var body: some View {
        Form {
            Section {
                Toggle("Show notes during breaks", isOn: $appState.breakNotesEnabled)

                Text("Short reminders shown on the right side of the overlay during breaks.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if appState.breakNotesEnabled {
                Section("Your notes") {
                    ForEach(Array(appState.breakNotes.enumerated()), id: \.offset) { index, note in
                        HStack {
                            Text(note)
                            Spacer()
                            Button {
                                var notes = appState.breakNotes
                                notes.remove(at: index)
                                appState.breakNotes = notes
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        TextField("Add a note...", text: $newNote)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addNote()
                            }
                        Button {
                            addNote()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                        .disabled(newNote.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    Button("Reset to Defaults") {
                        appState.breakNotes = Constants.defaultBreakNotes
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func addNote() {
        let trimmed = newNote.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var notes = appState.breakNotes
        notes.append(trimmed)
        appState.breakNotes = notes
        newNote = ""
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

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
