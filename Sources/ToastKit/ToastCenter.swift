import Observation
import SwiftUI

/// The single entry point for showing transient feedback.
///
/// Zero-config by design: presentation style, placement, animation, and the
/// default duration are house-standard constants baked into the kit. Hosts
/// install the presentation surface once with `.toastHost()` and call the
/// `show` family from anywhere on the main actor.
@Observable
@MainActor
public final class ToastCenter {

    public static let shared = ToastCenter()

    /// The currently visible toasts, oldest first.
    ///
    /// `ToastItem` is an `Equatable` value type and every mutation changes
    /// the array value itself, so plain `@Observable` publishing is safe here
    /// (the "identity-equal SwiftData model array" suppression trap does not
    /// apply).
    public private(set) var toasts: [ToastItem] = []

    /// House-standard display duration. Call sites may pass a longer value
    /// for messages that need more reading time; they never configure this
    /// globally.
    public static let defaultDuration: TimeInterval = 2.0

    /// At most this many toasts are visible at once; when a new one arrives
    /// at the cap, the oldest yields immediately. Bursts (e.g. a batch import
    /// failing item by item) must never wallpaper the screen.
    static let maximumVisibleToasts = 3

    static let houseAnimation = Animation.spring(response: 0.5, dampingFraction: 0.8)

    private var dismissTasks: [UUID: Task<Void, Never>] = [:]

    // Internal so tests can build isolated instances; production code goes
    // through `shared` only.
    init() {}

    // MARK: - Showing

    /// Shows a toast with an already-resolved string.
    public func show(
        title: String,
        subtitle: String? = nil,
        style: ToastStyle = .info,
        duration: TimeInterval = ToastCenter.defaultDuration
    ) {
        let item = ToastItem(
            title: title,
            subtitle: normalized(subtitle),
            style: style,
            duration: duration
        )
        withAnimation(Self.houseAnimation) {
            while toasts.count >= Self.maximumVisibleToasts {
                let oldest = toasts.removeFirst()
                dismissTasks.removeValue(forKey: oldest.id)?.cancel()
            }
            toasts.append(item)
        }
        announceForAccessibility(item)
        scheduleDismiss(of: item)
    }

    /// Shows a toast with strings localized in the host's catalog.
    public func show(
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource? = nil,
        style: ToastStyle = .info,
        duration: TimeInterval = ToastCenter.defaultDuration
    ) {
        show(
            title: String(localized: title),
            subtitle: subtitle.map { String(localized: $0) },
            style: style,
            duration: duration
        )
    }

    // MARK: - Convenience styles

    public func showSuccess(title: String, subtitle: String? = nil) {
        show(title: title, subtitle: subtitle, style: .success)
    }

    public func showSuccess(title: LocalizedStringResource, subtitle: LocalizedStringResource? = nil) {
        show(title: title, subtitle: subtitle, style: .success)
    }

    public func showError(title: String, subtitle: String? = nil) {
        show(title: title, subtitle: subtitle, style: .error)
    }

    public func showError(title: LocalizedStringResource, subtitle: LocalizedStringResource? = nil) {
        show(title: title, subtitle: subtitle, style: .error)
    }

    public func showWarning(title: String, subtitle: String? = nil) {
        show(title: title, subtitle: subtitle, style: .warning)
    }

    public func showWarning(title: LocalizedStringResource, subtitle: LocalizedStringResource? = nil) {
        show(title: title, subtitle: subtitle, style: .warning)
    }

    public func showInfo(title: String, subtitle: String? = nil) {
        show(title: title, subtitle: subtitle, style: .info)
    }

    public func showInfo(title: LocalizedStringResource, subtitle: LocalizedStringResource? = nil) {
        show(title: title, subtitle: subtitle, style: .info)
    }

    // MARK: - Dismissal

    /// Removes every visible toast immediately.
    public func dismissAll() {
        for task in dismissTasks.values {
            task.cancel()
        }
        dismissTasks.removeAll()
        withAnimation(Self.houseAnimation) {
            toasts.removeAll()
        }
    }

    private func scheduleDismiss(of item: ToastItem) {
        dismissTasks[item.id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(item.duration))
            guard !Task.isCancelled else { return }
            self?.dismiss(id: item.id)
        }
    }

    private func dismiss(id: UUID) {
        dismissTasks[id] = nil
        withAnimation(Self.houseAnimation) {
            toasts.removeAll { $0.id == id }
        }
    }

    // MARK: - Helpers

    private func normalized(_ subtitle: String?) -> String? {
        guard let subtitle, !subtitle.isEmpty else { return nil }
        return subtitle
    }

    /// Toasts are transient and non-interactive; VoiceOver users would miss
    /// them entirely without an announcement.
    private func announceForAccessibility(_ item: ToastItem) {
        var announcement = item.title
        if let subtitle = item.subtitle {
            announcement += ", " + subtitle
        }
        AccessibilityNotification.Announcement(announcement).post()
    }
}
