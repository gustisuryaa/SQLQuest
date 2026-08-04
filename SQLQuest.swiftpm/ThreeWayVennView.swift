import SwiftUI

// MARK: - ThreeWayVennView
// Fully responsive Canvas-based 3-circle Venn diagram.
// Uses GeometryReader so the radius scales with available width —
// no hardcoded sizes, works from iPhone to Mac Catalyst fullscreen.

struct ThreeWayVennView: View {
    let joinAB: JoinType    // Students <-> Enrollments
    let joinBC: JoinType    // Enrollments <-> Courses

    var studentsActive : Bool { joinAB == .left  || joinAB == .inner }
    var enrollActive   : Bool { true }
    var coursesActive  : Bool { joinBC == .right || joinBC == .inner }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let cx = size.width  / 2
            let cy = size.height / 2
            // Radius scales with shortest edge, capped for very wide containers
            let r  = min(size.width * 0.26, size.height * 0.38, 160)

            // Font sizes scale with radius
            let labelPt      : CGFloat = max(r * 0.145, 13)
            let intersectPt  : CGFloat = max(r * 0.095,  9)

            // Triangle layout
            let centerA = CGPoint(x: cx - r * 0.60, y: cy - r * 0.38)
            let centerB = CGPoint(x: cx + r * 0.60, y: cy - r * 0.38)
            let centerC = CGPoint(x: cx,             y: cy + r * 0.58)

            let tables: [(center: CGPoint, color: Color, label: String, active: Bool)] = [
                (centerA, .blue,   "Students",    studentsActive),
                (centerB, .teal,   "Enrollments", enrollActive),
                (centerC, .orange, "Courses",     coursesActive)
            ]

            Canvas { ctx, _ in
                // Fills
                for (center, color, _, active) in tables {
                    let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                    ctx.fill(Circle().path(in: rect),
                             with: .color(color.opacity(active ? 0.40 : 0.09)))
                }
                // Strokes
                for (center, color, _, active) in tables {
                    let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                    ctx.stroke(Circle().path(in: rect),
                               with: .color(color.opacity(active ? 0.75 : 0.18)),
                               lineWidth: active ? 2.5 : 1)
                }
                // Table name labels (outer edge of each circle)
                let labelOffsets: [CGPoint] = [
                    CGPoint(x: centerA.x - r * 0.30, y: centerA.y - r * 0.62),
                    CGPoint(x: centerB.x + r * 0.30, y: centerB.y - r * 0.62),
                    CGPoint(x: centerC.x,             y: centerC.y + r * 0.68)
                ]
                for (i, (_, color, label, active)) in tables.enumerated() {
                    ctx.draw(
                        Text(label)
                            .font(.system(size: labelPt, weight: .bold, design: .rounded))
                            .foregroundColor(active ? color : .gray.opacity(0.5)),
                        at: labelOffsets[i]
                    )
                }
                // Junction labels in the overlap zones
                drawJunctionLabel(ctx, between: centerA, and: centerB,
                    label: joinAB.rawValue, color: joinAB.color,
                    offset: CGPoint(x: 0, y: -r * 0.20), size: intersectPt)
                drawJunctionLabel(ctx, between: centerB, and: centerC,
                    label: joinBC.rawValue, color: joinBC.color,
                    offset: CGPoint(x: r * 0.18, y: r * 0.14), size: intersectPt)
            }
            .drawingGroup()
        }
        // Panoramic aspect ratio — tall enough for three circles, never collapses
        .aspectRatio(1.7, contentMode: .fit)
        .padding(DS.Space.md)
        .accessibilityLabel(
            "3-table Venn Diagram: Students \(joinAB.rawValue) Enrollments \(joinBC.rawValue) Courses"
        )
    }

    private func drawJunctionLabel(
        _ ctx: GraphicsContext,
        between a: CGPoint, and b: CGPoint,
        label: String, color: Color,
        offset: CGPoint, size: CGFloat
    ) {
        let mid = CGPoint(x: (a.x + b.x) / 2 + offset.x,
                          y: (a.y + b.y) / 2 + offset.y)
        ctx.draw(
            Text(label)
                .font(.system(size: size, weight: .semibold, design: .monospaced))
                .foregroundColor(color),
            at: mid
        )
    }
}
