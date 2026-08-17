import SwiftUI

/// A single transient feedback message.
///
/// Hosts never construct this directly; ``ToastCenter`` creates items from
/// its `show` family of methods. The type is public so the host can inspect
/// the queue (e.g. in tests), not so it can inject presentation variants.
public struct ToastItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let subtitle: String?
    public let style: ToastStyle
    public let duration: TimeInterval

    init(
        title: String,
        subtitle: String?,
        style: ToastStyle,
        duration: TimeInterval
    ) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.duration = duration
    }
}

/// The semantic category of a toast. Iconography is a kit-level decision;
/// hosts pick a style, never a symbol.
public enum ToastStyle: Equatable, Sendable {
    case success
    case error
    case warning
    case info

    var iconName: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .error: "xmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }
}
