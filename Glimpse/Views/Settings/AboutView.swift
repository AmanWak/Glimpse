//
//  AboutView.swift
//  Glimpse
//
//  About tab: app icon and the 20-20-20 explanation.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text("Glimpse")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Glimpse follows the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds. It's a simple habit recommended by eye care professionals to reduce digital eye strain.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .padding()
    }
}

#Preview {
    AboutView()
}
