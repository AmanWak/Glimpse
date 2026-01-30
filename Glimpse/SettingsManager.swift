//
//  SettingsManager.swift
//  Glimpse
//
//  Manages user preferences and settings persistence
//

import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let userDefaults = UserDefaults.standard
    
    // Keys
    private let appearanceModeKey = "appearanceMode"
    private let overlayColorKey = "overlayColor"
    private let overlayOpacityKey = "overlayOpacity"
    private let breakStyleKey = "breakStyle"
    private let skipFrictionKey = "skipFriction"
    private let launchAtLoginKey = "launchAtLogin"
    
    // Published properties
    @Published var appearanceMode: AppearanceMode {
        didSet { userDefaults.set(appearanceMode.rawValue, forKey: appearanceModeKey) }
    }
    
    @Published var overlayColor: Color {
        didSet { saveColor(overlayColor, key: overlayColorKey) }
    }
    
    @Published var overlayOpacity: Double {
        didSet { userDefaults.set(overlayOpacity, forKey: overlayOpacityKey) }
    }
    
    @Published var breakStyle: BreakStyle {
        didSet { userDefaults.set(breakStyle.rawValue, forKey: breakStyleKey) }
    }
    
    @Published var skipFrictionEnabled: Bool {
        didSet { userDefaults.set(skipFrictionEnabled, forKey: skipFrictionKey) }
    }
    
    @Published var launchAtLogin: Bool {
        didSet { 
            userDefaults.set(launchAtLogin, forKey: launchAtLoginKey)
            configureLaunchAtLogin(launchAtLogin)
        }
    }
    
    private init() {
        // Load saved values or use defaults
        let savedMode = userDefaults.string(forKey: appearanceModeKey) ?? AppearanceMode.system.rawValue
        self.appearanceMode = AppearanceMode(rawValue: savedMode) ?? .system
        
        self.overlayColor = loadColor(key: overlayColorKey) ?? Color.purple
        self.overlayOpacity = userDefaults.double(forKey: overlayOpacityKey)
        if self.overlayOpacity == 0 {
            self.overlayOpacity = 0.75 // Default
        }
        
        let savedStyle = userDefaults.string(forKey: breakStyleKey) ?? BreakStyle.overlay.rawValue
        self.breakStyle = BreakStyle(rawValue: savedStyle) ?? .overlay
        
        self.skipFrictionEnabled = userDefaults.bool(forKey: skipFrictionKey)
        self.launchAtLogin = userDefaults.bool(forKey: launchAtLoginKey)
    }
    
    // MARK: - Color persistence
    private func saveColor(_ color: Color, key: String) {
        #if canImport(AppKit)
        if let nsColor = NSColor(color) {
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
                userDefaults.set(colorData, forKey: key)
            }
        }
        #endif
    }
    
    private func loadColor(key: String) -> Color? {
        #if canImport(AppKit)
        guard let colorData = userDefaults.data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
            return nil
        }
        return Color(nsColor)
        #else
        return nil
        #endif
    }
    
    private func configureLaunchAtLogin(_ enabled: Bool) {
        // TODO: Implement launch at login using SMLoginItemSetEnabled or LaunchAtLogin framework
        // For now, this is a placeholder
        print("Launch at login: \(enabled)")
    }
}

// MARK: - Supporting Types
enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case dark = "Dark"
    case light = "Light"
    case custom = "Custom"
}

enum BreakStyle: String, CaseIterable {
    case overlay = "Overlay"
    case notification = "Notification"
}
