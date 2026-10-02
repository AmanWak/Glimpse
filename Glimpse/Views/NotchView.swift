//
//  NotchView.swift
//  Glimpse
//
//  Live-Activity-style break pill that hugs the MacBook notch (or the top-center of any
//  screen). Stateless: receives all values as plain properties, owns no timers or @State.
//

import SwiftUI

/// The pill silhouette: concave quadratic curves at the top that sweep the black out into
/// the menu bar line, convex rounded corners at the bottom.
///
/// Path math follows Kai Azim's `NotchShape` in DynamicNotchKit (MIT), the implementation
/// behind NotchNook-style notch UI. The critical detail is the top control point: it sits on
/// the **top edge** (`minY`), which makes the curve leave the edge *horizontally* so the
/// shape flows out of the menu bar. Putting the control point on the side instead makes the
/// curve leave *vertically*, which flares the black across the whole band and reads as two
/// stray bumps — that mistake is the whole reason this comment exists.
///
/// The shape is `topCornerRadius` wider than its body on each side; that extra width is the
/// cove, so the window must be sized `body + topCornerRadius * 2`.
struct NotchShape: Shape {
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let tcr = topCornerRadius
        let bcr = bottomCornerRadius
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Concave top-left — control point on the top edge keeps the tangent horizontal.
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + tcr, y: rect.minY + tcr),
            control: CGPoint(x: rect.minX + tcr, y: rect.minY)
        )

        path.addLine(to: CGPoint(x: rect.minX + tcr, y: rect.maxY - bcr))

        // Convex bottom-left.
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + tcr + bcr, y: rect.maxY),
            control: CGPoint(x: rect.minX + tcr, y: rect.maxY)
        )

        path.addLine(to: CGPoint(x: rect.maxX - tcr - bcr, y: rect.maxY))

        // Convex bottom-right.
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - tcr, y: rect.maxY - bcr),
            control: CGPoint(x: rect.maxX - tcr, y: rect.maxY)
        )

        path.addLine(to: CGPoint(x: rect.maxX - tcr, y: rect.minY + tcr))

        // Concave top-right.
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - tcr, y: rect.minY)
        )

        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        return path
    }
}

struct NotchView: View {
    let seconds: Int
    let overlayColor: Color
    /// Height of the physical notch on this screen (0 when there is none). Content is
    /// pushed below it so the countdown never hides behind the camera housing.
    let topInset: CGFloat

    private var pillShape: NotchShape {
        NotchShape(topCornerRadius: Constants.notchTopCornerRadius,
                   bottomCornerRadius: Constants.notchBottomRadius)
    }

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "eye")
                .font(.system(size: 14, weight: .semibold))
                // Not overlayColor directly — it is a near-black *background* color and
                // vanishes when used as a foreground on the black pill.
                .foregroundStyle(overlayColor.legibleAccent)

            Text("\(seconds)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text("Look away")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.top, topInset)
        // Clear the cove so content sits inside the body, not under the curve.
        .padding(.horizontal, Constants.notchTopCornerRadius + 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            pillShape.fill(.black)
        )
    }
}
