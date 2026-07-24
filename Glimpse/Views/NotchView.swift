//
//  NotchView.swift
//  Glimpse
//
//  Live-Activity-style break pill that hugs the MacBook notch (or the top-center of any
//  screen). Stateless: receives all values as plain properties, owns no timers or @State.
//

import SwiftUI

struct NotchView: View {
    let seconds: Int
    let overlayColor: Color
    /// Height of the physical notch on this screen (0 when there is none). Content is
    /// pushed below it so the countdown never hides behind the camera housing.
    let topInset: CGFloat

    /// Square top corners sit flush against the bezel/notch; rounded bottom corners make
    /// the pill look like the notch dropping down.
    private var pillShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 22,
            bottomTrailingRadius: 22,
            topTrailingRadius: 0
        )
    }

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "eye")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(overlayColor)

            Text("\(seconds)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text("Look away")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.top, topInset)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                pillShape.fill(.black)
                pillShape.fill(overlayColor.opacity(0.16))
            }
        )
        .overlay(
            pillShape.strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    NotchView(seconds: 18, overlayColor: .teal, topInset: 0)
        .frame(width: 280, height: 64)
        .background(.gray)
}
