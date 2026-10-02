//
//  Color+Hex.swift
//  Glimpse
//
//  Color extension for hex string conversion.
//

import SwiftUI

extension Color {
    /// Initialize a Color from a hex string (e.g., "1A1A2E" or "#1A1A2E")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    /// A version of this color bright enough to read as a foreground accent on a dark
    /// surface.
    ///
    /// `overlayColorHex` is picked as a full-screen *background*, and users often choose a
    /// near-black one (e.g. #0B2B1F). Reusing that directly as an icon tint on the dark notch
    /// pill makes the icon effectively invisible. This lifts brightness while preserving the hue
    /// the user chose. Colors that are already bright are returned untouched, and greys stay
    /// grey rather than acquiring a hue out of nowhere.
    var legibleAccent: Color {
        guard let base = NSColor(self).usingColorSpace(.sRGB) else { return self }
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        base.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        guard brightness < 0.7 else { return self }
        return Color(
            hue: Double(hue),
            saturation: saturation < 0.08 ? 0 : Double(max(saturation, 0.45)),
            brightness: 0.82,
            opacity: Double(alpha)
        )
    }

    /// Convert Color to hex string (without # prefix)
    var hexString: String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else {
            return "000000"
        }

        let r = Int(round(components.redComponent * 255))
        let g = Int(round(components.greenComponent * 255))
        let b = Int(round(components.blueComponent * 255))

        return String(format: "%02X%02X%02X", r, g, b)
    }
}
