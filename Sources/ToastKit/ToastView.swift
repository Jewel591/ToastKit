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
            if item.showsIcon {
                ToastStyleIcon(style: item.style)
            }

            VStack(alignment: .center, spacing: 1) {
                Text(item.title)
                    .font(.subheadline)
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
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
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

/// Hugeicons Stroke Rounded glyphs (MIT, `@hugeicons/core-free-icons` 4.2.3).
///
/// 24×24 design grid. Stroke is 2 (library default is 1.5) so the outline
/// holds up at toast size. Drawn only when the call site passes `showsIcon`.
private struct ToastStyleIcon: View {
    let style: ToastStyle

    @ScaledMetric(relativeTo: .title2) private var iconSize: CGFloat = 22

    var body: some View {
        ToastHugeiconsShape(style: style)
            .stroke(
                style: StrokeStyle(
                    lineWidth: 2 * iconSize / ToastHugeiconsShape.gridSide,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .foregroundStyle(.primary)
            .frame(width: iconSize, height: iconSize)
            .accessibilityHidden(true)
    }
}

/// Hugeicons 24×24 paths, scaled into the offered rect.
private struct ToastHugeiconsShape: Shape {
    var style: ToastStyle

    static let gridSide: CGFloat = 24

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / Self.gridSide
        let drawn = Self.gridSide * scale
        let transform = CGAffineTransform(
            translationX: rect.midX - drawn / 2,
            y: rect.midY - drawn / 2
        )
        .scaledBy(x: scale, y: scale)
        return Self.gridPath(for: style).applying(transform)
    }

    private static func gridPath(for style: ToastStyle) -> Path {
        var path = badge(for: style)
        path.addPath(mark(for: style))
        path.addPath(dots(for: style))
        return path
    }

    private static func badge(for style: ToastStyle) -> Path {
        switch style {
        case .success, .error, .info: circleBadge
        case .warning: alertBadge
        }
    }

    private static func mark(for style: ToastStyle) -> Path {
        switch style {
        case .success: checkMark
        case .error: cancelMark
        case .warning: alertStem
        case .info: infoStem
        }
    }

    private static func dots(for style: ToastStyle) -> Path {
        switch style {
        case .warning: dot(at: CGPoint(x: 12, y: 16.75))
        case .info: dot(at: CGPoint(x: 12, y: 8.25))
        case .success, .error: Path()
        }
    }

    private static var circleBadge: Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: 2, y: 2, width: 20, height: 20))
        return path
    }

    /// Outer path of `Alert02Icon`.
    private static var alertBadge: Path {
        var path = Path()
        path.move(to: CGPoint(x: 13.9248, y: 21))
        path.addLine(to: CGPoint(x: 10.0752, y: 21))
        path.addCurve(
            to: CGPoint(x: 2.27636, y: 19.4939),
            control1: CGPoint(x: 5.44476, y: 21),
            control2: CGPoint(x: 3.12955, y: 21)
        )
        path.addCurve(
            to: CGPoint(x: 4.97574, y: 11.9985),
            control1: CGPoint(x: 1.42317, y: 17.9879),
            control2: CGPoint(x: 2.60736, y: 15.9914)
        )
        path.addLine(to: CGPoint(x: 6.90057, y: 8.75333))
        path.addCurve(
            to: CGPoint(x: 12, y: 3),
            control1: CGPoint(x: 9.17559, y: 4.91778),
            control2: CGPoint(x: 10.3131, y: 3)
        )
        path.addCurve(
            to: CGPoint(x: 17.0994, y: 8.75332),
            control1: CGPoint(x: 13.6869, y: 3),
            control2: CGPoint(x: 14.8244, y: 4.91777)
        )
        path.addLine(to: CGPoint(x: 19.0243, y: 11.9985))
        path.addCurve(
            to: CGPoint(x: 21.7236, y: 19.4939),
            control1: CGPoint(x: 21.3926, y: 15.9914),
            control2: CGPoint(x: 22.5768, y: 17.9879)
        )
        path.addCurve(
            to: CGPoint(x: 13.9248, y: 21),
            control1: CGPoint(x: 20.8704, y: 21),
            control2: CGPoint(x: 18.5552, y: 21)
        )
        path.closeSubpath()
        return path
    }

    /// Inner path of `CheckmarkCircle02Icon`.
    private static var checkMark: Path {
        var path = Path()
        path.move(to: CGPoint(x: 8, y: 12.5))
        path.addLine(to: CGPoint(x: 10.5, y: 15))
        path.addLine(to: CGPoint(x: 16, y: 9))
        return path
    }

    /// Inner path of `CancelCircleIcon`.
    private static var cancelMark: Path {
        var path = Path()
        path.move(to: CGPoint(x: 14.9994, y: 15))
        path.addLine(to: CGPoint(x: 9, y: 9))
        path.move(to: CGPoint(x: 9.00064, y: 15))
        path.addLine(to: CGPoint(x: 15, y: 9))
        return path
    }

    private static var alertStem: Path {
        var path = Path()
        path.move(to: CGPoint(x: 12, y: 9))
        path.addLine(to: CGPoint(x: 12, y: 13))
        return path
    }

    private static var infoStem: Path {
        var path = Path()
        path.move(to: CGPoint(x: 12, y: 16))
        path.addLine(to: CGPoint(x: 12, y: 12))
        return path
    }

    private static func dot(at center: CGPoint) -> Path {
        Path(ellipseIn: CGRect(
            x: center.x - 0.25,
            y: center.y - 0.25,
            width: 0.5,
            height: 0.5
        ))
    }
}

private func previewToast(
    _ title: String,
    subtitle: String? = nil,
    style: ToastStyle,
    showsIcon: Bool = false
) -> ToastItem {
    ToastItem(
        title: title,
        subtitle: subtitle,
        style: style,
        duration: 2,
        showsIcon: showsIcon,
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
        .padding(24)
        .frame(minWidth: 360)
        .background {
            #if canImport(UIKit)
            Color(uiColor: .systemGroupedBackground)
            #else
            Color(nsColor: .windowBackgroundColor)
            #endif
        }
    }
}

#Preview("Text only", traits: .sizeThatFitsLayout) {
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

#Preview("With icon", traits: .sizeThatFitsLayout) {
    ToastPreviewScreen(items: [
        previewToast("Saved", style: .success, showsIcon: true),
        previewToast(
            "Export failed",
            subtitle: "Check storage space",
            style: .error,
            showsIcon: true
        ),
        previewToast(
            "免费 AI 识别额度已用完",
            subtitle: "升级后可无限使用",
            style: .warning,
            showsIcon: true
        ),
        previewToast(
            "Signed in",
            subtitle: "Syncing your library",
            style: .info,
            showsIcon: true
        ),
    ])
}
