//
//  SettingsView.swift
//  Glimpse
//
//  Settings panel for configuring app preferences
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    
    var body: some View {
        TabView {
            // Appearance Tab
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            // Behavior Tab
            BehaviorSettingsView()
                .tabItem {
                    Label("Behavior", systemImage: "gearshape")
                }
            
            // General Tab
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "switch.2")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section("Overlay Appearance") {
                Picker("Mode:", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                if settings.appearanceMode == .custom {
                    ColorPicker("Overlay Color:", selection: $settings.overlayColor)
                }
                
                VStack(alignment: .leading) {
                    Text("Overlay Opacity: \(Int(settings.overlayOpacity * 100))%")
                    Slider(value: $settings.overlayOpacity, in: 0.5...0.9)
                }
            }
        }
        .padding(20)
    }
}

// MARK: - Behavior Settings
struct BehaviorSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section("Break Style") {
                Picker("Style:", selection: $settings.breakStyle) {
                    ForEach(BreakStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Text("Overlay: Full-screen break reminder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Notification: System notification only")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Skip Friction") {
                Toggle("Enable skip confirmation", isOn: $settings.skipFrictionEnabled)
                
                Text("Shows \"Are you sure?\" dialog after 2 consecutive skips")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                
                Text("Automatically start Glimpse when you log in")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("About") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glimpse")
                        .font(.headline)
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Protect your eyes with the 20-20-20 rule")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
    }
}

#Preview {
    SettingsView()
}
