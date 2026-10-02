//
//  GameModeMonitorTests.swift
//  GlimpseTests
//
//  Tests for pausing while a game is frontmost, and game-category detection.
//

import Testing
import Foundation
@testable import Glimpse

struct GameModeMonitorTests {

    /// Helper: a monitor with fully injected config (no UserDefaults, no NSWorkspace).
    /// `frontmost` is read on every evaluate, so tests can change it between calls.
    private final class Frontmost {
        var game: String?
        init(_ game: String?) { self.game = game }
    }

    private func makeMonitor(
        frontmost: Frontmost,
        enabled: @escaping () -> Bool = { true }
    ) -> GameModeMonitor {
        let monitor = GameModeMonitor(skipObservers: true)
        monitor.configEnabled = enabled
        monitor.frontmostGameName = { frontmost.game }
        return monitor
    }

    // MARK: - Pause / resume

    @Test func pausesWithGameNameWhenGameIsFrontmost() {
        let monitor = makeMonitor(frontmost: Frontmost("Celeste"))
        var pausedFor: String?
        monitor.onShouldPause = { pausedFor = $0 }

        monitor.evaluate()

        #expect(pausedFor == "Celeste")
        #expect(monitor.isPausing)
    }

    @Test func doesNothingWhenNoGameIsFrontmost() {
        let monitor = makeMonitor(frontmost: Frontmost(nil))
        var pauseCalled = false
        var resumeCalled = false
        monitor.onShouldPause = { _ in pauseCalled = true }
        monitor.onShouldResume = { resumeCalled = true }

        monitor.evaluate()

        #expect(!pauseCalled)
        #expect(!resumeCalled)
        #expect(!monitor.isPausing)
    }

    @Test func resumesWhenGameLeavesForeground() {
        let frontmost = Frontmost("Celeste")
        let monitor = makeMonitor(frontmost: frontmost)
        var resumeCount = 0
        monitor.onShouldResume = { resumeCount += 1 }

        monitor.evaluate()
        frontmost.game = nil
        monitor.evaluate()

        #expect(resumeCount == 1)
        #expect(!monitor.isPausing)
    }

    @Test func repeatedEvaluateDoesNotPauseTwice() {
        let monitor = makeMonitor(frontmost: Frontmost("Celeste"))
        var pauseCount = 0
        monitor.onShouldPause = { _ in pauseCount += 1 }

        monitor.evaluate()
        monitor.evaluate()
        monitor.evaluate()

        #expect(pauseCount == 1)
    }

    @Test func switchingBetweenGamesStaysPausedWithoutResuming() {
        let frontmost = Frontmost("Celeste")
        let monitor = makeMonitor(frontmost: frontmost)
        var pauseCount = 0
        var resumeCount = 0
        monitor.onShouldPause = { _ in pauseCount += 1 }
        monitor.onShouldResume = { resumeCount += 1 }

        monitor.evaluate()
        frontmost.game = "Hades"
        monitor.evaluate()

        #expect(pauseCount == 1)
        #expect(resumeCount == 0)
        #expect(monitor.isPausing)
    }

    // MARK: - Enabled setting

    @Test func doesNothingWhenFeatureDisabled() {
        let monitor = makeMonitor(frontmost: Frontmost("Celeste"), enabled: { false })
        var pauseCalled = false
        monitor.onShouldPause = { _ in pauseCalled = true }

        monitor.evaluate()

        #expect(!pauseCalled)
        #expect(!monitor.isPausing)
    }

    @Test func disablingWhilePausedResumesImmediately() {
        var enabled = true
        let monitor = makeMonitor(frontmost: Frontmost("Celeste"), enabled: { enabled })
        var resumeCount = 0
        monitor.onShouldResume = { resumeCount += 1 }

        monitor.evaluate()
        enabled = false
        monitor.evaluate()

        #expect(resumeCount == 1)
        #expect(!monitor.isPausing)
    }

    @Test func disabledWhileNotPausingDoesNotFireResume() {
        let monitor = makeMonitor(frontmost: Frontmost(nil), enabled: { false })
        var resumeCalled = false
        monitor.onShouldResume = { resumeCalled = true }

        monitor.evaluate()

        #expect(!resumeCalled)
    }

    // MARK: - Suppress until clear (manual resume)

    @Test func suppressUntilClearIgnoresTheCurrentGame() {
        let monitor = makeMonitor(frontmost: Frontmost("Celeste"))
        var pauseCount = 0
        monitor.onShouldPause = { _ in pauseCount += 1 }

        monitor.evaluate()
        monitor.suppressUntilClear()
        monitor.evaluate()

        #expect(pauseCount == 1)
        #expect(!monitor.isPausing)
        #expect(monitor.suppressedUntilClear)
    }

    @Test func suppressionClearsOnceANonGameIsFrontmost() {
        let frontmost = Frontmost("Celeste")
        let monitor = makeMonitor(frontmost: frontmost)
        var pauseCount = 0
        monitor.onShouldPause = { _ in pauseCount += 1 }

        monitor.suppressUntilClear()
        monitor.evaluate()          // still in game: suppressed
        frontmost.game = nil
        monitor.evaluate()          // left the game: suppression lifts
        frontmost.game = "Celeste"
        monitor.evaluate()          // back in a game: pauses again

        #expect(!monitor.suppressedUntilClear)
        #expect(pauseCount == 1)
        #expect(monitor.isPausing)
    }

    @Test func leavingGameWhileSuppressedDoesNotFireResume() {
        let frontmost = Frontmost("Celeste")
        let monitor = makeMonitor(frontmost: frontmost)
        var resumeCalled = false
        monitor.onShouldResume = { resumeCalled = true }

        monitor.evaluate()
        monitor.suppressUntilClear()
        frontmost.game = nil
        monitor.evaluate()

        #expect(!resumeCalled)
    }

    // MARK: - Category detection

    @Test(arguments: [
        "public.app-category.games",
        "public.app-category.action-games",
        "public.app-category.arcade-games",
        "public.app-category.role-playing-games",
        "public.app-category.strategy-games",
    ])
    func gameCategoriesAreDetected(_ category: String) {
        #expect(GameModeMonitor.isGameCategory(category))
    }

    @Test(arguments: [
        "public.app-category.developer-tools",
        "public.app-category.productivity",
        "public.app-category.entertainment",
        "public.app-category.video",
        "",
    ])
    func nonGameCategoriesAreNotDetected(_ category: String) {
        #expect(!GameModeMonitor.isGameCategory(category))
    }
}
