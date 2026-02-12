//
//  MessageView.swift
//  Glimpse
//
//  Displays the break reminder message.
//

import SwiftUI

struct MessageView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 24, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }
}

#Preview {
    ZStack {
        Color.black
        MessageView(message: "Look at something 20 feet away")
    }
}
