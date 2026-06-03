//
//  NotesPanelView.swift
//  Glimpse
//
//  Displays user-customizable reminder notes on the overlay during breaks.
//

import SwiftUI

struct NotesPanelView: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Remember to...")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .frame(width: 5, height: 5)
                            .foregroundStyle(.white.opacity(0.5))
                        Text(note)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
        }
        .padding(24)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: 340)
    }
}

#Preview {
    ZStack {
        Color(hex: "1A1A2E")
        NotesPanelView(notes: [
            "Sit up straight",
            "Drink some water",
            "Relax your shoulders",
            "Unclench your jaw",
            "Take a deep breath",
        ])
    }
}
