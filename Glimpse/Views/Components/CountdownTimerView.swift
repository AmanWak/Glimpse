//
//  CountdownTimerView.swift
//  Glimpse
//
//  Large countdown timer display for the break overlay.
//

import SwiftUI

struct CountdownTimerView: View {
    var seconds: Int

    var body: some View {
        Text("\(seconds)")
            .font(.system(size: 200, weight: .ultraLight, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
    }
}

#Preview {
    ZStack {
        Color.black
        CountdownTimerView(seconds: 20)
    }
}
