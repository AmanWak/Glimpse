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
}
