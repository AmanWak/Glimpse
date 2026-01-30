//
//  GlimpseApp.swift
//  Glimpse
//
//  Created by Aman Wakankar on 1/30/26.
//

import SwiftUI

@main
struct GlimpseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - app is menu bar only
        Settings {
            EmptyView()
        }
    }
}
