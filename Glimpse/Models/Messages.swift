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
        // Classic reminders
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
        "Blink. Breathe. Look away.",
        // Positive / encouraging
        "You're doing great. Rest your eyes.",
        "Small breaks, big difference.",
        "This is you taking care of yourself.",
        "Future you appreciates this break.",
        "Healthy eyes, happy life.",
        "You deserve this pause.",
        "Progress doesn't mean no breaks.",
        "Taking breaks is a superpower.",
        "Even your eyes need a vacation.",
        "20 seconds of kindness to yourself.",
        // Mindfulness
        "Notice three things far away.",
        "What's the farthest thing you can see?",
        "Scan the room. Then look further.",
        "Relax your jaw. Relax your eyes.",
        "Unclench. Unfocus. Breathe.",
        "Let your gaze go soft.",
        "Feel the space beyond the screen.",
        "Where does the sky meet the ground?",
        "Let your eyes wander freely.",
        "No screens. Just space.",
    ]

    /// Rare/fun messages (10% chance)
    static let rare: [String] = [
        "Don't blink. Blink and you're dead.",
        "The eyes are the window to the soul. Clean your windows.",
        "Plot twist: the 20 feet was inside you all along.",
        "Your optometrist would be proud.",
        "Achievement unlocked: Self Care.",
        "Your screen misses you already.",
        "The pixels will still be there in 20 seconds.",
        "Fun fact: your eyes have over 2 million working parts.",
        "This message will self-destruct in 20 seconds.",
        "Stare into the void. The void is chill about it.",
        "You've been staring at a glowing rectangle. That's wild.",
        "If eyes had a Yelp page, they'd leave you 5 stars right now.",
        "Looking away from the screen? Groundbreaking.",
        "Your future self just high-fived you.",
        "Brief intermission. Popcorn not included.",
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
