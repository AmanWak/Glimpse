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
        UserDefaults.standard.removeObject(forKey: Constants.Keys.appAwarePauseEnabled)
        UserDefaults.standard.removeObject(forKey: Constants.Keys.watchedGameBundleIDs)
        UserDefaults.standard.removeObject(forKey: Constants.Keys.gamePauseEnabled)
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

    // MARK: - Legacy game settings migration

    @Test func migrationIsNoOpWhenNoLegacyKeysExist() {
        resetWatchedApps()
        AppWatcher.saveWatchedBundleIDs(["us.zoom.xos"])

        AppWatcher.migrateLegacyGameSettings()

        #expect(AppWatcher.loadWatchedBundleIDs() == ["us.zoom.xos"])
        #expect(UserDefaults.standard.object(forKey: Constants.Keys.appAwarePauseEnabled) == nil)

        resetWatchedApps()
    }

    @Test func migrationMergesGameIDsIntoUnifiedList() {
        resetWatchedApps()
        AppWatcher.saveWatchedBundleIDs(["us.zoom.xos"])
        let gameIDs: Set<String> = ["com.valvesoftware.steam", "net.battle.app"]
        UserDefaults.standard.set(try? JSONEncoder().encode(gameIDs), forKey: Constants.Keys.watchedGameBundleIDs)

        AppWatcher.migrateLegacyGameSettings()

        #expect(AppWatcher.loadWatchedBundleIDs() == ["us.zoom.xos", "com.valvesoftware.steam", "net.battle.app"])
        #expect(UserDefaults.standard.object(forKey: Constants.Keys.watchedGameBundleIDs) == nil)

        resetWatchedApps()
    }

    @Test func migrationEnablesUnifiedFlagWhenGamePauseWasEnabled() {
        resetWatchedApps()
        UserDefaults.standard.set(true, forKey: Constants.Keys.gamePauseEnabled)

        AppWatcher.migrateLegacyGameSettings()

        #expect(UserDefaults.standard.bool(forKey: Constants.Keys.appAwarePauseEnabled))
        #expect(UserDefaults.standard.object(forKey: Constants.Keys.gamePauseEnabled) == nil)

        resetWatchedApps()
    }

    @Test func migrationDoesNotDisableUnifiedFlagWhenGamePauseWasOff() {
        resetWatchedApps()
        UserDefaults.standard.set(true, forKey: Constants.Keys.appAwarePauseEnabled)
        UserDefaults.standard.set(false, forKey: Constants.Keys.gamePauseEnabled)

        AppWatcher.migrateLegacyGameSettings()

        #expect(UserDefaults.standard.bool(forKey: Constants.Keys.appAwarePauseEnabled))
        #expect(UserDefaults.standard.object(forKey: Constants.Keys.gamePauseEnabled) == nil)

        resetWatchedApps()
    }
}
