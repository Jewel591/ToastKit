import SwiftUI
import Testing
@testable import ToastKit

/// Issue #8: a single-line, fixed-width toast cut real guidance into half
/// sentences. These render the shared `ToastView` and fail if long copy stops
/// wrapping or the width cap stops holding.
@MainActor
struct ToastLayoutTests {
    private static let longSubtitle =
        "Your data is safe on this device. Check the sync status in Settings."

    @Test func longCopyWrapsInsteadOfTruncating() throws {
        let single = try renderedSize(subtitle: "Saved")
        let wrapped = try renderedSize(subtitle: Self.longSubtitle)

        // A second subtitle line adds roughly one caption line of height.
        #expect(wrapped.height > single.height + 8)
    }

    @Test func longCopyStaysWithinTheWidthCap() throws {
        let wrapped = try renderedSize(subtitle: Self.longSubtitle, proposedWidth: 1_000)

        #expect(wrapped.width <= 300.5)
    }

    @Test func longTitleWrapsToo() throws {
        // Without the icon, so the 22pt glyph does not mask the added line.
        let single = try renderedSize(title: "Saved", subtitle: nil, showsIcon: false)
        let wrapped = try renderedSize(title: Self.longSubtitle, subtitle: nil, showsIcon: false)

        #expect(wrapped.height > single.height + 8)
    }

    private func renderedSize(
        title: String = "iCloud sync needs attention",
        subtitle: String?,
        showsIcon: Bool = true,
        proposedWidth: CGFloat = 400
    ) throws -> CGSize {
        let item = ToastItem(title: title, subtitle: subtitle, style: .error, duration: 5, showsIcon: showsIcon, sceneStamp: nil)
        let renderer = ImageRenderer(
            content: ToastView(item: item).environment(\.dynamicTypeSize, .large)
        )
        renderer.proposedSize = ProposedViewSize(width: proposedWidth, height: nil)
        let image = try #require(renderer.cgImage)
        return CGSize(
            width: CGFloat(image.width) / renderer.scale,
            height: CGFloat(image.height) / renderer.scale
        )
    }
}
