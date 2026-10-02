//
//  NotchManagerTests.swift
//  GlimpseTests
//
//  Tests for notch pill geometry.
//

import Testing
import AppKit
@testable import Glimpse

struct NotchManagerTests {

    /// A 14" MacBook Pro-shaped screen whose notch sits 1.5pt right of screen center,
    /// which is what real hardware reports.
    private let screen = NSRect(x: 0, y: 0, width: 1512, height: 982)
    private let inset: CGFloat = 32
    private let notchMinX: CGFloat = 665
    private let notchMaxX: CGFloat = 850

    private var auxLeft: NSRect { NSRect(x: 0, y: 950, width: notchMinX, height: 32) }
    private var auxRight: NSRect { NSRect(x: notchMaxX, y: 950, width: 1512 - notchMaxX, height: 32) }

    private var notchedFrame: NSRect {
        NotchManager.pillFrame(screenFrame: screen, topInset: inset, auxTopLeft: auxLeft, auxTopRight: auxRight)
    }

    // MARK: - Notched screen

    @Test func centersOnTheNotchNotTheScreen() {
        let frame = notchedFrame
        #expect(frame.midX == (notchMinX + notchMaxX) / 2)
        #expect(frame.midX != screen.midX)
    }

    @Test func widthWrapsNotchWithOverhangAndCoves() {
        let notchWidth = notchMaxX - notchMinX
        let expected = notchWidth
            + Constants.notchBodyOverhang * 2
            + Constants.notchTopCornerRadius * 2
        #expect(notchedFrame.width == expected)
    }

    @Test func heightCoversNotchPlusBody() {
        #expect(notchedFrame.height == inset + Constants.notchBodyHeight)
    }

    @Test func sitsFlushWithTopOfScreen() {
        #expect(notchedFrame.maxY == screen.maxY)
    }

    @Test func fullyCoversTheNotch() {
        let frame = notchedFrame
        #expect(frame.minX < notchMinX)
        #expect(frame.maxX > notchMaxX)
    }

    // MARK: - No notch

    @Test func fallsBackToScreenCenterWithoutNotch() {
        let frame = NotchManager.pillFrame(screenFrame: screen, topInset: 0, auxTopLeft: nil, auxTopRight: nil)
        #expect(frame.midX == screen.midX)
        #expect(frame.maxY == screen.maxY)
        #expect(frame.width == 260 + Constants.notchTopCornerRadius * 2)
        #expect(frame.height == 64)
    }

    @Test func fallsBackWhenInsetPresentButAuxAreasMissing() {
        let frame = NotchManager.pillFrame(screenFrame: screen, topInset: inset, auxTopLeft: nil, auxTopRight: nil)
        #expect(frame.midX == screen.midX)
        #expect(frame.height == 64)
    }

    @Test func ignoresAuxAreasWhenThereIsNoInset() {
        let frame = NotchManager.pillFrame(screenFrame: screen, topInset: 0, auxTopLeft: auxLeft, auxTopRight: auxRight)
        #expect(frame.midX == screen.midX)
    }

    // MARK: - Secondary displays

    @Test func usesScreenOriginOnOffsetDisplay() {
        // An external display placed to the right of and above the built-in one.
        let external = NSRect(x: 1512, y: 200, width: 2560, height: 1440)
        let frame = NotchManager.pillFrame(screenFrame: external, topInset: 0, auxTopLeft: nil, auxTopRight: nil)
        #expect(frame.midX == external.midX)
        #expect(frame.maxY == external.maxY)
    }

    // MARK: - Geometry constants

    @Test func geometryConstantsArePositive() {
        #expect(Constants.notchTopCornerRadius > 0)
        #expect(Constants.notchBottomRadius > 0)
        #expect(Constants.notchBodyOverhang > 0)
        #expect(Constants.notchBodyHeight > 0)
    }

    @Test func bottomCornersFitInsideBody() {
        #expect(Constants.notchBottomRadius * 2 <= Constants.notchBodyHeight)
    }
}
