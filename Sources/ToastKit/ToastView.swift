import SwiftUI

/// The house-standard toast capsule. Internal: presentation is a kit-level
/// decision, hosts never compose this directly.
struct ToastView: View {
    let item: ToastItem

    private var backgroundColor: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: item.style.iconName)
                .font(.system(.title2, weight: .medium))
                .foregroundStyle(.primary)
                .frame(height: 32)

            VStack(alignment: .center, spacing: 1) {
                Text(item.title)
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(backgroundColor)
                .shadow(radius: 8, y: 2)
        )
        // No `.fixedSize(horizontal: true)` here: it would let long localized
        // text adopt its ideal width and blow straight past the cap (the
        // outer frame only reports a smaller size, it does not clip). Without
        // it the capsule still hugs short content, and long single-line text
        // truncates with an ellipsis inside the cap.
        .frame(maxWidth: 300)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .accessibilityElement(children: .combine)
    }
}
