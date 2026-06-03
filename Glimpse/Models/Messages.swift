//
//  Messages.swift
//  Glimpse
//
//  Break reminder messages across five categories.
//

import Foundation

enum Messages {
    /// Standard eye care break messages
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
        "Relax your vision.",
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
        "Evolution didn't prepare you for 10 hours of backlit text. Look away.",
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

    /// Eye exercise messages
    static let exercises: [String] = [
        "Close your eyes. Count to 10. Open.",
        "Trace a figure-8 with your eyes. Slowly.",
        "Look left, right, up, down. Repeat twice.",
        "Palm your eyes — cover them gently, no pressure.",
        "Blink rapidly 10 times. Your eyes are dry.",
        "Focus on your thumb at arm's length. Then something far. Repeat.",
        "Roll your eyes in a slow circle. Both directions.",
        "Look at the tip of your nose, then the farthest wall. Three times.",
        "Close one eye, then the other. Alternate 5 times.",
        "Look at each corner of the room. Clockwise.",
        "Squeeze your eyes shut for 3 seconds. Release.",
        "Focus on something green. It's the easiest color for your eyes.",
        "Cup your palms over your eyes. Enjoy the darkness.",
        "Look at a near object. Then far. Near. Far. Five times.",
        "Widen your eyes, then squint. Repeat 5 times.",
        "Follow your finger slowly from left to right without moving your head.",
        "Stare at a single point for 10 seconds. Let everything else blur.",
        "Massage your temples in small circles. 10 seconds.",
        "Press gently on your closed eyelids. Hold 5 seconds.",
        "Warm your palms by rubbing them together. Place over your eyes.",
    ]

    /// Posture messages
    static let posture: [String] = [
        "Roll your shoulders back 3 times.",
        "Drop your shoulders away from your ears.",
        "Straighten your back. You're slouching.",
        "Tilt your head side to side. Gently.",
        "Stretch your arms overhead. Hold for 5 seconds.",
        "Unclench your jaw. Relax your tongue from the roof of your mouth.",
        "Open and close your hands. Stretch those fingers.",
        "Rotate your wrists. Both directions.",
        "Touch your chin to your chest. Hold. Slowly look up.",
        "Pull your shoulders back like you're holding a pencil between your shoulder blades.",
        "Stand up. Sit back down. You just exercised.",
        "Shake out your hands like you're flicking water off them.",
        "Twist your torso left, then right. Gently.",
        "Press your palms together in front of you. Hold for 5 seconds.",
        "Reach behind your back with both hands. Clasp and stretch.",
        "Place your hand on the opposite shoulder. Pull gently. Switch.",
        "Lift your feet off the ground. Hold for 5 seconds.",
        "Wiggle your toes. When's the last time you thought about them?",
        "Push your chair back. Stretch your legs under the desk.",
        "Interlace your fingers and push your palms toward the ceiling.",
    ]

    /// Breathing messages
    static let breathing: [String] = [
        "Breathe in for 4. Hold for 4. Out for 4.",
        "Take 3 slow, deep breaths.",
        "Exhale longer than you inhale. It calms you down.",
        "Breathe in through your nose, out through your mouth.",
        "One long breath. Fill your lungs completely.",
        "Notice your breathing. Don't change it. Just notice.",
        "Sigh it out. Loudly. Nobody's judging.",
        "Breathe deeply. Your brain needs the oxygen.",
        "Breathe in for 4, hold for 7, out for 8. The 4-7-8 method.",
        "Place one hand on your chest, one on your belly. Breathe into the belly.",
        "Inhale slowly. Pause at the top. Let it all go.",
        "Three breaths. Make each one slower than the last.",
        "Breathe in calm. Breathe out tension.",
        "Hum as you exhale. Feel the vibration.",
        "Imagine breathing in cool air and breathing out warm air.",
        "Take the deepest breath you've taken all day. Right now.",
        "Breathe like you're trying to fog up a cold window.",
        "Slow everything down. Just for 20 seconds.",
        "Your shoulders dropped when you read this. Keep breathing.",
        "Fill your lungs. Hold. Release slowly through pursed lips.",
    ]

    /// Walk/movement messages (used by dedicated walk reminder notifications)
    static let walk: [String] = [
        "Stand up and walk for 2 minutes.",
        "Take a short walk. Your brain will thank you.",
        "Step away from your desk. Move around.",
        "Walk to the kitchen and back. Hydrate while you're there.",
        "Get up. Stretch your legs. Sit back down refreshed.",
        "A short walk resets your focus better than coffee.",
        "Stand up. Your body wasn't designed to sit this long.",
        "Walk to a window. Look outside. Come back.",
        "Take the long way to the bathroom.",
        "Two minutes on your feet. That's all it takes.",
        "Go refill your water. Your brain is probably dehydrated.",
        "Stand up and do 10 calf raises. Nobody will notice.",
        "Walk around your space. Notice something you haven't before.",
        "Movement is medicine. Take a small dose.",
        "Step outside for 60 seconds of fresh air.",
        "Walk and think. Some problems solve themselves when you move.",
        "Your chair will be here when you get back. Go.",
        "Pace while you think about your next task.",
        "A 2-minute walk boosts creativity for the next hour.",
        "Get up. Move. Sit back down. Repeat every hour.",
    ]

    /// Rare/fun messages (10% chance)
    static let rare: [String] = [
        "Don't blink. Blink and you're dead.",
        "The eyes are the window to the soul. Clean your windows.",
        "Play eye spy.",
        "Your optometrist would be proud.",
        "Achievement unlocked: Self Care.",
        "Your screen misses you already. Let it.",
        "The pixels will still be there in 20 seconds.",
        "If you're reading this, you can see.",
        "This message will self-destruct in 20 seconds.",
        "Stare into the void. The void is chill about it.",
        "You've been staring at a glowing rectangle. That's wild.",
        "If eyes had a Yelp page, they'd leave you 5 stars right now.",
        "Looking away from the screen? Groundbreaking.",
        "Your future self just high-fived you.",
        "Brief intermission. Popcorn not included.",
    ]

    /// Internal counter for deterministic category cycling
    private static var breakCounter: Int = 0

    /// Get the next break message, cycling through all categories.
    /// Guarantees posture, exercise, breathing, and walk messages appear regularly.
    /// Cycle: standard → exercises → posture → standard → breathing → walk (8% rare override)
    static func next() -> String {
        breakCounter += 1

        // 8% chance of a rare/fun message regardless of cycle position
        if Int.random(in: 1...100) <= 8 {
            return rare.randomElement() ?? standard[0]
        }

        let cycle = breakCounter % 6
        let pool: [String]
        switch cycle {
        case 1: pool = standard
        case 2: pool = exercises
        case 3: pool = posture
        case 4: pool = standard
        case 5: pool = breathing
        case 0: pool = walk
        default: pool = standard
        }
        return pool.randomElement() ?? standard[0]
    }

    /// Get a random message weighted by category.
    /// 8% rare, 30% standard, 20% exercises, 16% posture, 14% breathing, 12% walk
    static func random() -> String {
        let roll = Int.random(in: 1...100)
        let pool: [String]
        switch roll {
        case 1...8:
            pool = rare
        case 9...38:
            pool = standard
        case 39...58:
            pool = exercises
        case 59...74:
            pool = posture
        case 75...88:
            pool = breathing
        default:
            pool = walk
        }
        return pool.randomElement() ?? standard[0]
    }
}
