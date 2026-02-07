//
//  OverlayView.swift
//  Glimpse
//
//  Full-screen break overlay with blur, timer, message, and skip button.
//

import SwiftUI

struct OverlayView: View {
    var appState: AppState
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            // Background blur
            VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow)

            // Color overlay
            Color(hex: appState.overlayColorHex)
                .opacity(appState.overlayOpacity)

            // Content
            VStack(spacing: 40) {
                Spacer()

                // Countdown timer
                CountdownTimerView(seconds: Int(appState.secondsRemaining))

                // Message
                MessageView(message: appState.currentMessage)

                Spacer()

                // Skip button
                SkipButton(
                    requireConfirmation: appState.skipConfirmation && appState.streak.consecutiveSkips >= 2,
                    onSkip: onSkip
                )

                Spacer()
                    .frame(height: 60)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OverlayView(
        appState: AppState(),
        onSkip: {}
    )
}
