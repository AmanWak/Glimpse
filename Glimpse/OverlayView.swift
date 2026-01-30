//
//  OverlayView.swift
//  Glimpse
//
//  SwiftUI view for the full-screen break overlay
//

import SwiftUI

struct OverlayView: View {
    let countdown: Int
    let message: String
    let onSkip: () -> Void
    
    @ObservedObject private var settings = SettingsManager.shared
    
    var body: some View {
        ZStack {
            // Background with blur effect
            Color.black.opacity(0.3)
            
            // Colored overlay
            overlayColor
                .opacity(settings.overlayOpacity)
            
            // Content
            VStack(spacing: 60) {
                Spacer()
                
                // Message
                Text(message)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Countdown timer
                Text("\(countdown)")
                    .font(.system(size: 200, weight: .ultraLight))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Skip button
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
    }
    
    private var overlayColor: Color {
        switch settings.appearanceMode {
        case .dark, .system:
            return Color.purple
        case .light:
            return Color.white
        case .custom:
            return settings.overlayColor
        }
    }
}

#Preview {
    OverlayView(countdown: 15, message: "Look at something far away.") {
        print("Skip tapped")
    }
}
