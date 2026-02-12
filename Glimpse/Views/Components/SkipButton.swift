//
//  SkipButton.swift
//  Glimpse
//
//  Skip button with optional inline confirmation friction.
//

import SwiftUI

struct SkipButton: View {
    var requireConfirmation: Bool
    let onSkip: () -> Void

    @State private var showingConfirmation = false

    var body: some View {
        if showingConfirmation {
            // Inline confirmation (renders inside the overlay, not as a system alert)
            VStack(spacing: 12) {
                Text("Skip this break?")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Skipping breaks too often can strain your eyes.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingConfirmation = false
                        }
                    } label: {
                        Text("Continue Break")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        onSkip()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red.opacity(0.9))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .transition(.opacity)
        } else {
            Button {
                if requireConfirmation {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingConfirmation = true
                    }
                } else {
                    onSkip()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "forward.fill")
                    Text("Skip")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        SkipButton(requireConfirmation: false) {
            print("Skipped")
        }
    }
}
