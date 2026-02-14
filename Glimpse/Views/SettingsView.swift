//
//  SettingsView.swift
//  Glimpse
//
//  Settings window with General and Appearance tabs.
//

import SwiftUI
import ServiceManagement

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
        }
        .frame(width: 400, height: 250)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @Bindable var appState: AppState

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
                Picker("Break style", selection: $appState.breakStyle) {
                    ForEach(BreakStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }

                Toggle("Confirm before skipping", isOn: $appState.skipConfirmation)
            }
        }
        .formStyle(.grouped)
        .padding()
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
    @State private var selectedColor: Color

    init(appState: AppState) {
        self.appState = appState
        _selectedColor = State(initialValue: Color(hex: appState.overlayColorHex))
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Overlay color")
                    Spacer()
                    ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                        .labelsHidden()
                        .onChange(of: selectedColor) { _, newValue in
                            appState.overlayColorHex = newValue.hexString
                        }
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
                    selectedColor = Color(hex: Constants.defaultOverlayColorHex)
                }
            }

//            Section {
//                // Preview
//                ZStack {
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(selectedColor.opacity(appState.overlayOpacity))
//                        .frame(height: 60)
//
//                    Text("")
//                        .foregroundStyle(.white)
//                        .font(.headline)
//                }
//            } header: {
//                Text("")
//            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    SettingsView(appState: AppState())
}
