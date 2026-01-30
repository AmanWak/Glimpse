//
//  MessageProvider.swift
//  Glimpse
//
//  Provides random motivational messages for break overlays
//

import Foundation

struct MessageProvider {
    // Standard messages (98% probability total)
    static let standardMessages = [
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
    
    // Rare messages (~2% probability each)
    static let rareMessages = [
        "Don't blink. Blink and you're dead.",
        "The eyes are the window to the soul. Clean your windows.",
        "Plot twist: the 20 feet was inside you all along.",
        "Your optometrist would be proud.",
        "Achievement unlocked: Self Care."
    ]
    
    /// Returns a random message with weighted probability
    /// - 98% chance: standard message
    /// - 2% chance: rare message
    static func randomMessage() -> String {
        let randomValue = Double.random(in: 0...1)
        
        // 2% chance for rare message
        if randomValue < 0.02 {
            return rareMessages.randomElement() ?? standardMessages.randomElement()!
        } else {
            return standardMessages.randomElement()!
        }
    }
}
