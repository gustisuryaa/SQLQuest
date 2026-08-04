import SwiftUI

// MARK: - VennCircle
// Draws a single Venn circle.  The diameter is passed in from VennDiagramView
// so every size decision is made at the container level via GeometryReader.

struct VennCircle: View {
    let title     : String
    let color     : Color
    let isSelected: Bool
    let diameter  : CGFloat
    let labelSize : CGFloat

    var accessibilityDesc: String {
        isSelected
            ? "\(title): active and included in the current query result"
            : "\(title): inactive — not included in the current query result"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(isSelected ? 0.70 : 0.15))
                .frame(width: diameter, height: diameter)
                .shadow(color: color.opacity(isSelected ? 0.55 : 0), radius: diameter * 0.15)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.60), color.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 2.5 : 1
                )
                .frame(width: diameter, height: diameter)

            Text(title)
                .font(.system(size: labelSize, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : .primary.opacity(0.30))
        }
        .animation(.spring(response: 0.50, dampingFraction: 0.68), value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDesc)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Use the JOIN selector above to change the active query type")
    }
}

// MARK: - VennDiagramView
// Uses GeometryReader so the diagram fills whatever width its parent gives it.

struct VennDiagramView: View {
    let selectedJoin: JoinType

    var leftActive : Bool { selectedJoin == .left  || selectedJoin == .inner }
    var rightActive: Bool { selectedJoin == .right || selectedJoin == .inner }

    var body: some View {
        GeometryReader { geo in
            let m = VennMetrics.from(containerWidth: geo.size.width)

            HStack(spacing: -m.overlap) {
                VennCircle(
                    title: "Students", color: .blue,
                    isSelected: leftActive,
                    diameter: m.diameter, labelSize: m.labelSize
                )
                .zIndex(1)

                VennCircle(
                    title: "Clubs", color: .orange,
                    isSelected: rightActive,
                    diameter: m.diameter, labelSize: m.labelSize
                )
                .zIndex(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(m.padding)
            .drawingGroup()
            .blendMode(.multiply)
        }
        .aspectRatio(2.4, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Venn Diagram showing the active SQL JOIN type")
    }
}
