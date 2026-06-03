//
//  AppWatcherTests.swift
//  GlimpseTests
//
//  Tests for app-aware pausing logic.
//

import Testing
import Foundation
@testable import Glimpse

struct AppWatcherTests {

    /// Helper: create an AppWatcher with fully injected config (no UserDefaults)
    private func makeWatcher(
        running: Set<String> = [],
        watched: Set<String> = [],
        enabled: Bool = true
    ) -> AppWatcher {
        let watcher = AppWatcher(skipObservers: true)
        watcher.configEnabled = { enabled }
        watcher.configWatchedIDs = { watched }
        watcher.runningBundleIDs = { running }
        watcher.appNameForBundleID = { bundleID in
            let presets: [(String, String)] = [
                ("Zoom", "us.zoom.xos"),
                ("Microsoft Teams", "com.microsoft.teams2"),
                ("FaceTime", "com.apple.FaceTime"),
            ]
            if let match = presets.first(where: { $0.1 == bundleID }) {
                return match.0
            }
            return bundleID
        }
        return watcher
    }

    // MARK: - Basic evaluate

    @Test func doesNothingWhenFeatureDisabled() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos"],
            watched: ["us.zoom.xos"],
            enabled: false
        )
        var pauseCalled = false
        watcher.onShouldPause = { _ in pauseCalled = true }

        watcher.evaluate()

        #expect(!pauseCalled)
        #expect(!watcher.isPausingForApp)
    }

    @Test func doesNothingWhenNoWatchedApps() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos"],
            watched: [],
            enabled: true
        )
        var pauseCalled = false
        watcher.onShouldPause = { _ in pauseCalled = true }

        watcher.evaluate()

        #expect(!pauseCalled)
        #expect(!watcher.isPausingForApp)
    }

    @Test func doesNothingWhenWatchedAppNotRunning() {
        let watcher = makeWatcher(
            running: ["com.apple.Safari"],
            watched: ["us.zoom.xos"]
        )
        var pauseCalled = false
        watcher.onShouldPause = { _ in pauseCalled = true }

        watcher.evaluate()

        #expect(!pauseCalled)
        #expect(!watcher.isPausingForApp)
    }

    @Test func pausesWhenWatchedAppIsRunning() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos", "com.apple.Safari"],
            watched: ["us.zoom.xos"]
        )
        var pausedWithNames: [String]?
        watcher.onShouldPause = { names in pausedWithNames = names }

        watcher.evaluate()

        #expect(pausedWithNames == ["Zoom"])
        #expect(watcher.isPausingForApp)
    }

    @Test func resumesWhenWatchedAppQuits() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos"],
            watched: ["us.zoom.xos"]
        )
        var resumed = false
        watcher.onShouldPause = { _ in }
        watcher.onShouldResume = { resumed = true }

        watcher.evaluate()
        #expect(watcher.isPausingForApp)

        watcher.runningBundleIDs = { [] }
        watcher.evaluate()

        #expect(resumed)
        #expect(!watcher.isPausingForApp)
    }

    @Test func doesNotFirePauseTwice() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos"],
            watched: ["us.zoom.xos"]
        )
        var pauseCount = 0
        watcher.onShouldPause = { _ in pauseCount += 1 }

        watcher.evaluate()
        watcher.evaluate()
        watcher.evaluate()

        #expect(pauseCount == 1)
    }

    @Test func providesAppNameFromPresets() {
        let watcher = makeWatcher(
            running: ["com.microsoft.teams2"],
            watched: ["com.microsoft.teams2"]
        )
        var detectedNames: [String]?
        watcher.onShouldPause = { names in detectedNames = names }

        watcher.evaluate()

        #expect(detectedNames == ["Microsoft Teams"])
    }

    @Test func providesCustomBundleIDAsName() {
        let watcher = makeWatcher(
            running: ["com.custom.meetingapp"],
            watched: ["com.custom.meetingapp"]
        )
        var detectedNames: [String]?
        watcher.onShouldPause = { names in detectedNames = names }

        watcher.evaluate()

        #expect(detectedNames == ["com.custom.meetingapp"])
    }

    @Test func detectsMultipleAppsAtOnce() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos", "com.microsoft.teams2", "com.apple.Safari"],
            watched: ["us.zoom.xos", "com.microsoft.teams2"]
        )
        var detectedNames: [String]?
        watcher.onShouldPause = { names in detectedNames = names }

        watcher.evaluate()

        #expect(detectedNames == ["Microsoft Teams", "Zoom"])
        #expect(watcher.isPausingForApp)
    }

    // MARK: - Suppress until clear

    @Test func manualResumeSuppressesRepause() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos"],
            watched: ["us.zoom.xos"]
        )
        var pauseCount = 0
        watcher.onShouldPause = { _ in pauseCount += 1 }

        watcher.evaluate()
        #expect(pauseCount == 1)

        watcher.suppressUntilClear()
        #expect(!watcher.isPausingForApp)
        #expect(watcher.suppressedUntilClear)

        watcher.evaluate()
        #expect(pauseCount == 1)
    }

    @Test func suppressionClearsWhenAllWatchedAppsQuit() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos"],
            watched: ["us.zoom.xos"]
        )
        watcher.onShouldPause = { _ in }

        watcher.evaluate()
        watcher.suppressUntilClear()

        watcher.runningBundleIDs = { [] }
        watcher.evaluate()

        #expect(!watcher.suppressedUntilClear)
    }

    @Test func rePausesAfterSuppressionCleared() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos"],
            watched: ["us.zoom.xos"]
        )
        var pauseCount = 0
        watcher.onShouldPause = { _ in pauseCount += 1 }

        watcher.evaluate()
        #expect(pauseCount == 1)
        watcher.suppressUntilClear()

        watcher.runningBundleIDs = { [] }
        watcher.evaluate()
        #expect(!watcher.suppressedUntilClear)

        watcher.runningBundleIDs = { ["us.zoom.xos"] }
        watcher.evaluate()
        #expect(pauseCount == 2)
        #expect(watcher.isPausingForApp)
    }

    @Test func suppressionSurvivesMultipleEvaluations() {
        let watcher = makeWatcher(
            running: ["us.zoom.xos"],
            watched: ["us.zoom.xos"]
        )
        var pauseCount = 0
        watcher.onShouldPause = { _ in pauseCount += 1 }

        watcher.evaluate()
        watcher.suppressUntilClear()

        for _ in 0..<10 {
            watcher.evaluate()
        }

        #expect(pauseCount == 1)
        #expect(watcher.suppressedUntilClear)
    }

    // MARK: - Feature toggle edge cases

    @Test func disablingFeatureWhilePausedResumes() {
        var enabled = true
        let watcher = AppWatcher(skipObservers: true)
        watcher.configEnabled = { enabled }
        watcher.configWatchedIDs = { ["us.zoom.xos"] }
        watcher.runningBundleIDs = { ["us.zoom.xos"] }
        watcher.appNameForBundleID = { $0 }

        var resumed = false
        watcher.onShouldPause = { _ in }
        watcher.onShouldResume = { resumed = true }

        watcher.evaluate()
        #expect(watcher.isPausingForApp)

        enabled = false
        watcher.evaluate()

        #expect(resumed)
        #expect(!watcher.isPausingForApp)
    }

    @Test func removingAllWatchedIDsWhilePausedResumes() {
        var watched: Set<String> = ["us.zoom.xos"]
        let watcher = AppWatcher(skipObservers: true)
        watcher.configEnabled = { true }
        watcher.configWatchedIDs = { watched }
        watcher.runningBundleIDs = { ["us.zoom.xos"] }
        watcher.appNameForBundleID = { $0 }

        var resumed = false
        watcher.onShouldPause = { _ in }
        watcher.onShouldResume = { resumed = true }

        watcher.evaluate()
        #expect(watcher.isPausingForApp)

        watched = []
        watcher.evaluate()

        #expect(resumed)
        #expect(!watcher.isPausingForApp)
    }

    @Test func disablingFeatureClearsSuppression() {
        var enabled = true
        let watcher = AppWatcher(skipObservers: true)
        watcher.configEnabled = { enabled }
        watcher.configWatchedIDs = { ["us.zoom.xos"] }
        watcher.runningBundleIDs = { ["us.zoom.xos"] }
        watcher.appNameForBundleID = { $0 }
        watcher.onShouldPause = { _ in }

        watcher.evaluate()
        watcher.suppressUntilClear()
        #expect(watcher.suppressedUntilClear)

        enabled = false
        watcher.evaluate()

        #expect(!watcher.suppressedUntilClear)
    }
}
