//
//  AppsSettingsView.swift
//  Glimpse
//
//  Apps tab: one watched-app list for auto-pause (meetings, games, anything),
//  plus the game controller toggle.
//

import SwiftUI

struct AppsSettingsView: View {
    @State private var autoPauseEnabled = UserDefaults.standard.bool(forKey: Constants.Keys.appAwarePauseEnabled)
    @State private var watchedIDs = AppWatcher.loadWatchedBundleIDs()
    @State private var controllerEnabled = UserDefaults.standard.bool(forKey: Constants.Keys.controllerPauseEnabled)
    @State private var gameModeEnabled: Bool = {
        let key = Constants.Keys.gameModePauseEnabled
        if UserDefaults.standard.object(forKey: key) == nil { return true }  // default ON
        return UserDefaults.standard.bool(forKey: key)
    }()

    /// Watched apps resolved to display names, sorted alphabetically
    private var watchedApps: [(name: String, bundleID: String)] {
        watchedIDs
            .map { (name: displayName(for: $0), bundleID: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Preset apps not yet on the watched list
    private func unwatched(_ presets: [(name: String, bundleID: String)]) -> [(name: String, bundleID: String)] {
        presets.filter { !watchedIDs.contains($0.bundleID) }
    }

    /// Running foreground apps not already watched or in a preset list (never Glimpse itself)
    private var runningAppsToAdd: [(name: String, bundleID: String)] {
        let presetIDs = Set(Constants.allWatchablePresets.map(\.bundleID))
        return NSWorkspace.shared.runningApplications
            .compactMap { app -> (name: String, bundleID: String)? in
                guard app.activationPolicy == .regular,
                      let id = app.bundleIdentifier,
                      id != Bundle.main.bundleIdentifier,
                      !watchedIDs.contains(id),
                      !presetIDs.contains(id) else { return nil }
                return (name: app.localizedName ?? id, bundleID: id)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Form {
            Section {
                Toggle("Pause automatically for these apps", isOn: $autoPauseEnabled)
                    .onChange(of: autoPauseEnabled) {
                        UserDefaults.standard.set(autoPauseEnabled, forKey: Constants.Keys.appAwarePauseEnabled)
                    }

                Text("Breaks hold off while a watched app is running — a meeting, a game, a presentation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if autoPauseEnabled {
                Section("Watched apps") {
                    if watchedApps.isEmpty {
                        Text("Nothing watched yet — add an app below.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }

                    ForEach(watchedApps, id: \.bundleID) { app in
                        HStack {
                            Text(app.name)
                            Spacer()
                            Button {
                                remove(app.bundleID)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Menu("Add App...") {
                        addSubmenu("Meeting Apps", apps: unwatched(Constants.watchableAppPresets))
                        addSubmenu("Game Launchers", apps: unwatched(Constants.watchableGamePresets))
                        addSubmenu("Running Apps", apps: runningAppsToAdd)
                    }

                    Text("Browser-based meetings (Google Meet) cannot be auto-detected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle("Pause during games", isOn: $gameModeEnabled)
                    .onChange(of: gameModeEnabled) {
                        UserDefaults.standard.set(gameModeEnabled, forKey: Constants.Keys.gameModePauseEnabled)
                    }
                Text("Breaks hold off while a game is the active app — detected automatically, no setup needed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Pause when a controller is connected", isOn: $controllerEnabled)
                    .onChange(of: controllerEnabled) {
                        UserDefaults.standard.set(controllerEnabled, forKey: Constants.Keys.controllerPauseEnabled)
                    }
                Text("Pauses automatically while any game controller is connected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    @ViewBuilder
    private func addSubmenu(_ title: String, apps: [(name: String, bundleID: String)]) -> some View {
        if !apps.isEmpty {
            Menu(title) {
                ForEach(apps, id: \.bundleID) { app in
                    Button(app.name) {
                        add(app.bundleID)
                    }
                }
            }
        }
    }

    private func add(_ bundleID: String) {
        watchedIDs.insert(bundleID)
        AppWatcher.saveWatchedBundleIDs(watchedIDs)
    }

    private func remove(_ bundleID: String) {
        watchedIDs.remove(bundleID)
        AppWatcher.saveWatchedBundleIDs(watchedIDs)
    }

    private func displayName(for bundleID: String) -> String {
        if let preset = Constants.allWatchablePresets.first(where: { $0.bundleID == bundleID }) {
            return preset.name
        }
        return NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == bundleID })?
            .localizedName ?? bundleID
    }
}

#Preview {
    AppsSettingsView()
}
