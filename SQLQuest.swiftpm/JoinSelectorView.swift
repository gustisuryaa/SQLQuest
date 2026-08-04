import SwiftUI

// MARK: - JoinSelectorView
// Larger text & icons than the previous version.
// Uses DS typography tokens so all sizes are consistent across the app.

struct JoinSelectorView: View {
    @Binding var selectedJoin: JoinType

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            ForEach(JoinType.allCases, id: \.self) { type in
                JoinOptionButton(
                    type: type,
                    isSelected: selectedJoin == type,
                    action: {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.65)) {
                            selectedJoin = type
                        }
                    }
                )
            }
        }
        .padding(DS.Space.sm)
        .background(Color(.systemGray6))
        .cornerRadius(DS.Radius.lg)
        .padding(.horizontal, DS.Space.xl)
    }
}

// MARK: - JoinOptionButton

struct JoinOptionButton: View {
    let type      : JoinType
    let isSelected: Bool
    let action    : () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Space.xs + 2) {
                Image(systemName: type.icon)
                    .font(.title)                        // was .title2 — bigger
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? type.color : .secondary)

                Text(type.rawValue)
                    .font(DS.Font.label)                 // callout weight semibold
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundColor(isSelected ? type.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.md - 4)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(isSelected ? type.color.opacity(0.14) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .shadow(color: isSelected ? type.color.opacity(0.22) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.30, dampingFraction: 0.65), value: isSelected)
        .accessibilityLabel(type.rawValue)
        .accessibilityHint("Select \(type.rawValue) to visualize its behavior")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - MiniJoinSelector  (3-Table tab)

struct MiniJoinSelector: View {
    let label    : String
    @Binding var selected: JoinType

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs + 2) {
            Text(label)
                .font(DS.Font.captionBold)
                .foregroundColor(.secondary)

            HStack(spacing: DS.Space.xs + 2) {
                ForEach(JoinType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.70)) {
                            selected = type
                        }
                    } label: {
                        Text(type.rawValue)
                            .font(DS.Font.codeXs)
                            .foregroundColor(selected == type ? type.color : .secondary)
                            .padding(.horizontal, DS.Space.sm + 2)
                            .padding(.vertical, DS.Space.xs + 2)
                            .background(selected == type ? type.color.opacity(0.14) : Color(.systemGray6))
                            .cornerRadius(DS.Radius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .stroke(selected == type ? type.color : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.28), value: selected)
                }
            }
        }
    }
}
