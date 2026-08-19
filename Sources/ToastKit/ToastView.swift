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

private func previewToast(
    _ title: String,
    subtitle: String? = nil,
    style: ToastStyle
) -> ToastItem {
    ToastItem(
        title: title,
        subtitle: subtitle,
        style: style,
        duration: 2,
        sceneStamp: nil
    )
}

private struct ToastPreviewScreen: View {
    let items: [ToastItem]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(items) { item in
                ToastView(item: item)
            }
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            #if canImport(UIKit)
            Color(uiColor: .systemGroupedBackground)
            #else
            Color(nsColor: .windowBackgroundColor)
            #endif
        }
    }
}

#Preview("Success") {
    ToastPreviewScreen(items: [
        previewToast("Saved", style: .success),
    ])
}

#Preview("Error") {
    ToastPreviewScreen(items: [
        previewToast(
            "Export failed",
            subtitle: "Check storage space",
            style: .error
        ),
    ])
}

#Preview("Warning") {
    ToastPreviewScreen(items: [
        previewToast(
            "免费 AI 识别额度已用完",
            subtitle: "升级后可无限使用",
            style: .warning
        ),
    ])
}

#Preview("Info") {
    ToastPreviewScreen(items: [
        previewToast(
            "Signed in",
            subtitle: "Syncing your library",
            style: .info
        ),
    ])
}

#Preview("All styles") {
    ToastPreviewScreen(items: [
        previewToast("Saved", style: .success),
        previewToast(
            "Export failed",
            subtitle: "Check storage space",
            style: .error
        ),
        previewToast(
            "免费 AI 识别额度已用完",
            subtitle: "升级后可无限使用",
            style: .warning
        ),
        previewToast(
            "Signed in",
            subtitle: "Syncing your library",
            style: .info
        ),
    ])
}

#Preview("Title only") {
    ToastPreviewScreen(items: [
        previewToast("Saved", style: .success),
        previewToast("Export failed", style: .error),
        previewToast("Quota used up", style: .warning),
        previewToast("Copied", style: .info),
    ])
}

#Preview("Stack of 3") {
    ToastPreviewScreen(items: [
        previewToast("Saved", style: .success),
        previewToast(
            "Export failed",
            subtitle: "Check storage space",
            style: .error
        ),
        previewToast(
            "免费 AI 识别额度已用完",
            subtitle: "升级后可无限使用",
            style: .warning
        ),
    ])
}
