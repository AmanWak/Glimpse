//
//  AppWatcherPersistenceTests.swift
//  GlimpseTests
//
//  Tests for AppWatcher persisted watched app configuration.
//

import Foundation
import Testing
@testable import Glimpse

@Suite(.serialized)
struct AppWatcherPersistenceTests {
    private func resetWatchedApps() {
        UserDefaults.standard.removeObject(forKey: Constants.Keys.watchedBundleIDs)
    }

    @Test func loadWatchedBundleIDsReturnsEmptySetWhenUnset() {
        resetWatchedApps()

        #expect(AppWatcher.loadWatchedBundleIDs().isEmpty)

        resetWatchedApps()
    }

    @Test func saveAndLoadWatchedBundleIDsRoundTrips() {
        resetWatchedApps()
        let original: Set<String> = [
            "us.zoom.xos",
            "com.microsoft.teams2",
            "com.custom.meetingapp",
        ]

        AppWatcher.saveWatchedBundleIDs(original)

        #expect(AppWatcher.loadWatchedBundleIDs() == original)

        resetWatchedApps()
    }

    @Test func loadWatchedBundleIDsReturnsEmptySetForCorruptedData() {
        resetWatchedApps()
        UserDefaults.standard.set(Data("not-json".utf8), forKey: Constants.Keys.watchedBundleIDs)

        #expect(AppWatcher.loadWatchedBundleIDs().isEmpty)

        resetWatchedApps()
    }
}
