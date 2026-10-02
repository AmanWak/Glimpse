//
//  ColorHexTests.swift
//  GlimpseTests
//
//  Tests for Color hex string conversion.
//

import Testing
import SwiftUI
@testable import Glimpse

struct ColorHexTests {

    @Test func parsesSixDigitHex() {
        let color = Color(hex: "FF0000")
        // Red should produce "FF0000"
        #expect(color.hexString.uppercased() == "FF0000")
    }

    @Test func parsesHexWithHash() {
        let color = Color(hex: "#00FF00")
        #expect(color.hexString.uppercased() == "00FF00")
    }

    @Test func parsesThreeDigitHex() {
        let color = Color(hex: "F00")
        // Should expand to FF0000 (red)
        #expect(color.hexString.uppercased() == "FF0000")
    }

    @Test func roundTripConversion() {
        let originalHex = "1A1A2E"
        let color = Color(hex: originalHex)
        let resultHex = color.hexString
        #expect(resultHex.uppercased() == originalHex)
    }

    @Test func handlesBlack() {
        let color = Color(hex: "000000")
        #expect(color.hexString.uppercased() == "000000")
    }

    @Test func handlesWhite() {
        let color = Color(hex: "FFFFFF")
        #expect(color.hexString.uppercased() == "FFFFFF")
    }

    @Test func handlesInvalidHexGracefully() {
        // Invalid hex should default to black
        let color = Color(hex: "ZZZZZZ")
        #expect(color.hexString.uppercased() == "000000")
    }

    @Test func handlesEmptyString() {
        let color = Color(hex: "")
        #expect(color.hexString.uppercased() == "000000")
    }

    // MARK: - legibleAccent

    /// Hue, saturation, brightness of a Color in sRGB.
    private func hsb(_ color: Color) -> (h: CGFloat, s: CGFloat, b: CGFloat) {
        let ns = NSColor(color).usingColorSpace(.sRGB)!
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b)
    }

    @Test func legibleAccentBrightensDarkColors() {
        let dark = Color(hex: "0B2B1F")
        let lifted = hsb(dark.legibleAccent)
        #expect(hsb(dark).b < 0.7)
        #expect(abs(lifted.b - 0.82) < 0.01)
    }

    @Test func legibleAccentLeavesDefaultOverlayColorUntouched() {
        // The default (bright mint) is already readable on the dark notch pill.
        let hex = Constants.defaultOverlayColorHex.uppercased()
        #expect(Color(hex: hex).legibleAccent.hexString.uppercased() == hex)
    }

    @Test func legibleAccentPreservesHue() {
        let dark = Color(hex: "0B2B1F")
        #expect(abs(hsb(dark).h - hsb(dark.legibleAccent).h) < 0.01)
    }

    @Test func legibleAccentLeavesBrightColorsUntouched() {
        let bright = Color(hex: "FFCC00")
        #expect(bright.legibleAccent.hexString.uppercased() == "FFCC00")
    }

    @Test func legibleAccentKeepsGreysGrey() {
        let lifted = Color(hex: "333333").legibleAccent
        #expect(hsb(lifted).s < 0.01)
        #expect(hsb(lifted).b > 0.7)
    }

    @Test func legibleAccentGivesMutedDarkColorsEnoughSaturation() {
        // Dark and only slightly tinted, but above the grey cutoff.
        let muted = Color(hex: "2A2622")
        #expect(hsb(muted.legibleAccent).s >= 0.45 - 0.01)
    }
}
