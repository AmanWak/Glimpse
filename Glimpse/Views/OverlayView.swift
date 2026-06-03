//
//  OverlayView.swift
//  Glimpse
//
//  Full-screen break overlay with blur, timer, message, and skip button.
//  Completely stateless: receives all values as plain properties, owns no
//  timers or @State. OverlayManager drives the countdown and skip-confirmation
//  state by updating rootView each tick, and invalidates the timer before
//  teardown — making dangling-timer and dangling-animation crashes
//  structurally impossible.
//

import SwiftUI

struct OverlayView: View {
    let seconds: Int
    let overlayColor: Color
    let overlayOpacity: Double
    let message: String
    let notes: [String]
    let showingSkipConfirmation: Bool
    let onSkip: () -> Void
    let onCancelSkip: () -> Void

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

                SkipButton(
                    showingConfirmation: showingSkipConfirmation,
                    onSkip: onSkip,
                    onCancelSkip: onCancelSkip
                )

                Text("Press esc to skip")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.3))

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, notes.isEmpty ? 0 : 400)

            // Notes panel (right side)
            if !notes.isEmpty {
                HStack {
                    Spacer()
                    NotesPanelView(notes: notes)
                        .padding(.trailing, 60)
                }
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
        notes: Constants.defaultBreakNotes,
        showingSkipConfirmation: false,
        onSkip: {},
        onCancelSkip: {}
    )
}
