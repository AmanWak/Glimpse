//
//  Messages.swift
//  Glimpse
//
//  Break reminder messages with 10% chance for rare messages.
//

import Foundation

enum Messages {
    /// Standard break messages (90% chance)
    static let standard: [String] = [
        "Look at something far away.",
        "Find a window. Look outside.",
        "Rest your eyes for a moment.",
        "Look at the horizon.",
        "Give your eyes a break.",
        "Focus on something distant.",
        "Let your eyes relax.",
        "Gaze into the distance.",
        "Look away from the screen.",
        "Your eyes will thank you.",
        "20 seconds of rest.",
        "Find the farthest point you can see.",
        "Breathe. Look away.",
        "A small break for healthier eyes.",
        "Stretch your vision.",
        "Look up from the screen.",
        "Take a visual break.",
        "Rest. Refocus. Return.",
        "Look at something 20 feet away.",
        "Pause and look around.",
        "Soft eyes. Deep breath.",
        "Give your focus a rest.",
        "Look beyond your screen.",
        "A moment for your eyes.",
        "Blink. Breathe. Look away."
    ]

    /// Rare/fun messages (10% chance)
    static let rare: [String] = [
        "Don't blink. Blink and you're dead.",
        "The eyes are the window to the soul. Clean your windows.",
        "Plot twist: the 20 feet was inside you all along.",
        "Your optometrist would be proud.",
        "Achievement unlocked: Self Care."
    ]

    /// Get a random message with 10% chance for rare
    static func random() -> String {
        let isRare = Int.random(in: 1...10) == 1
        if isRare {
            return rare.randomElement() ?? standard[0]
        }
        return standard.randomElement() ?? standard[0]
    }
}
