//
//  BannerView.swift
//  Glimpse
//
//  Compact floating banner shown during breaks as a cursor-following pill.
//

import SwiftUI

struct BannerView: View {
    let seconds: Int
    let overlayColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("\(seconds)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text("Look 20 feet away")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                Capsule()
                    .fill(overlayColor.opacity(0.35))
            }
        )
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BannerView(seconds: 15, overlayColor: .teal)
        .padding()
        .background(.black)
}
