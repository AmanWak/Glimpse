//
//  SettingsView.swift
//  Glimpse
//
//  Settings window container — one tab per settings area.
//

import SwiftUI

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

            AppsSettingsView()
                .tabItem {
                    Label("Apps", systemImage: "app.badge.checkmark")
                }

            NotesSettingsView(appState: appState)
                .tabItem {
                    Label("Notes", systemImage: "list.bullet.rectangle")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "questionmark.circle")
                }
        }
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        .frame(width: 400, height: 430)
    }
}

#Preview {
    SettingsView(appState: AppState())
}
