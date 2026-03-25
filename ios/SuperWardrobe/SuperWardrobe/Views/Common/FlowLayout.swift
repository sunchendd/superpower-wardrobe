import SwiftUI

/// A layout that arranges children in a left-to-right flow, wrapping to the next
/// line when horizontal space runs out.
struct FlowLayout<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        _FlowLayout(spacing: spacing, content: content)
    }
}

// MARK: - Layout Implementation

private struct _FlowLayout<Content: View>: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var currentX: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needsNewRow = (currentX + size.width > maxWidth) && index > 0

            if needsNewRow {
                totalHeight += currentRowHeight + spacing
                currentX = 0
                currentRowHeight = 0
            }

            currentRowHeight = max(currentRowHeight, size.height)
            currentX += size.width + spacing
        }

        totalHeight += currentRowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentRowHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needsNewRow = (currentX + size.width > bounds.maxX) && index > 0

            if needsNewRow {
                currentY += currentRowHeight + spacing
                currentX = bounds.minX
                currentRowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )
            currentRowHeight = max(currentRowHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

// MARK: - Preview

#Preview {
    FlowLayout(spacing: 8) {
        ForEach(["休闲", "商务", "运动", "日系", "欧美", "简约", "复古", "街头"], id: \.self) { tag in
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.indigo.opacity(0.1))
                .clipShape(Capsule())
        }
    }
    .padding()
}
