//
//  OverlayView.swift
//  Glimpse
//
//  Full-screen break overlay with blur, timer, message, and skip button.
//  Completely stateless: receives all values as plain properties, owns no
//  timers or @State for countdown. OverlayManager drives the countdown by
//  updating rootView each tick, and invalidates the timer before teardown —
//  making dangling-timer crashes structurally impossible.
//

import SwiftUI

struct OverlayView: View {
    let seconds: Int
    let overlayColor: Color
    let overlayOpacity: Double
    let message: String
    let requireSkipConfirmation: Bool
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            // Background blur
            VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow)

            // Color overlay
            overlayColor
                .opacity(overlayOpacity)

            // Content
            VStack(spacing: 40) {
                Spacer()

                CountdownTimerView(seconds: seconds)

                MessageView(message: message)

                Spacer()

                SkipButton(requireConfirmation: requireSkipConfirmation, onSkip: onSkip)

                Spacer()
                    .frame(height: 60)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OverlayView(
        seconds: 20,
        overlayColor: .blue,
        overlayOpacity: 0.8,
        message: "Look at something 20 feet away.",
        requireSkipConfirmation: false,
        onSkip: {}
    )
}
