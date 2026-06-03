//
//  ConstantsTests.swift
//  GlimpseTests
//
//  Tests for product constants and preset invariants.
//

import Foundation
import Testing
@testable import Glimpse

struct ConstantsTests {
    @Test func defaultDurationsFollowTwentyTwentyTwentyRule() {
        #expect(Constants.defaultWorkDuration == 20 * 60)
        #expect(Constants.defaultBreakDuration == 20)
    }

    @Test func workDurationPresetsAreSortedAndWithinBounds() {
        #expect(Constants.workDurationPresets == Constants.workDurationPresets.sorted())
        #expect(Constants.workDurationPresets.contains(Constants.defaultWorkDuration))

        for duration in Constants.workDurationPresets {
            #expect(duration >= Constants.minWorkDuration)
            #expect(duration <= Constants.maxWorkDuration)
        }
    }

    @Test func breakDurationPresetsAreSortedAndWithinBounds() {
        #expect(Constants.breakDurationPresets == Constants.breakDurationPresets.sorted())
        #expect(Constants.breakDurationPresets.contains(Constants.defaultBreakDuration))

        for duration in Constants.breakDurationPresets {
            #expect(duration >= Constants.minBreakDuration)
            #expect(duration <= Constants.maxBreakDuration)
        }
    }

    @Test func overlayOpacityDefaultsAreWithinAllowedRange() {
        #expect(Constants.defaultOverlayOpacity >= Constants.minOverlayOpacity)
        #expect(Constants.defaultOverlayOpacity <= Constants.maxOverlayOpacity)
        #expect(Constants.minOverlayOpacity < Constants.maxOverlayOpacity)
    }

    @Test func appAwarePausePresetsHaveUniqueBundleIDs() {
        let bundleIDs = Constants.watchableAppPresets.map(\.bundleID)
        #expect(Set(bundleIDs).count == bundleIDs.count)
    }

    @Test func defaultBreakNotesAreShortAndUnique() {
        #expect(!Constants.defaultBreakNotes.isEmpty)
        #expect(Set(Constants.defaultBreakNotes).count == Constants.defaultBreakNotes.count)

        for note in Constants.defaultBreakNotes {
            #expect(!note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(note.count <= 40)
        }
    }
}
