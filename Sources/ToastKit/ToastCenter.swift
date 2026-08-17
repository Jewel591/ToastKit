import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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

    /// The suspension primitive behind auto-dismissal. Injectable so tests
    /// can prove the real contract — "stays visible until the duration
    /// elapses, and eviction / dismissAll actually cancel the pending work" —
    /// instead of racing wall-clock sleeps.
    private let sleep: @Sendable (TimeInterval) async throws -> Void

    // Internal so tests can build isolated instances; production code goes
    // through `shared` only.
    init(
        sleep: @escaping @Sendable (TimeInterval) async throws -> Void = {
            try await Task.sleep(for: .seconds($0))
        }
    ) {
        self.sleep = sleep
    }

    // MARK: - Showing

    /// Shows a toast with an already-resolved string.
    public func show(
        title: String,
        subtitle: String? = nil,
        style: ToastStyle = .info,
        duration: TimeInterval = ToastCenter.defaultDuration
    ) {
        insert(ToastItem(
            title: title,
            subtitle: normalized(subtitle),
            style: style,
            duration: duration,
            sceneStamp: Self.currentSceneStamp()
        ))
    }

    /// Internal seam so tests can exercise eviction with explicit scene
    /// stamps; the public `show` family always stamps with the current scene.
    func insert(_ item: ToastItem) {
        withAnimation(Self.houseAnimation) {
            evictUntilEverySurfaceHasRoom(for: item)
            toasts.append(item)
        }
        announceForAccessibility(item)
        scheduleDismiss(of: item)
    }

    /// The cap is a per-screen invariant: a screen renders its own scene's
    /// toasts plus every broadcast (`sceneStamp == nil`) toast, so eviction
    /// must count that visible union — not just the exact-stamp group —
    /// while still never touching a screen the new item does not appear on.
    ///
    /// Victim selection is deterministic and minimal: the toast visible on
    /// the most overloaded screens yields first (a shared broadcast can free
    /// several screens in one step), ties broken by queue order (oldest
    /// first). No step of it depends on `Set` iteration order.
    private func evictUntilEverySurfaceHasRoom(for item: ToastItem) {
        while true {
            let overloaded = overloadedSurfaces(for: item)
            guard !overloaded.isEmpty else { return }
            var coverage: [UUID: Int] = [:]
            for surface in overloaded {
                for toast in surface {
                    coverage[toast.id, default: 0] += 1
                }
            }
            let widestCoverage = coverage.values.max() ?? 0
            guard let victim = toasts.first(where: {
                coverage[$0.id] == widestCoverage
            }) else { return }
            toasts.removeAll { $0.id == victim.id }
            dismissTasks.removeValue(forKey: victim.id)?.cancel()
        }
    }

    /// The visible sets, among the screens the new item will land on, that
    /// are already at the cap.
    private func overloadedSurfaces(for item: ToastItem) -> [[ToastItem]] {
        let surfaces: [[ToastItem]]
        if let stamp = item.sceneStamp {
            surfaces = [toasts.filter {
                $0.sceneStamp == stamp || $0.sceneStamp == nil
            }]
        } else {
            // A broadcast lands on every screen: each known scene group
            // (plus a screen with no scene-owned toasts) must have room.
            var seen = Set<ObjectIdentifier>()
            var groups: [ObjectIdentifier] = []
            for stamp in toasts.compactMap(\.sceneStamp)
            where seen.insert(stamp).inserted {
                groups.append(stamp)
            }
            if groups.isEmpty {
                surfaces = [toasts.filter { $0.sceneStamp == nil }]
            } else {
                surfaces = groups.map { group in
                    toasts.filter {
                        $0.sceneStamp == group || $0.sceneStamp == nil
                    }
                }
            }
        }
        return surfaces.filter { $0.count >= Self.maximumVisibleToasts }
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
        dismissTasks[item.id] = Task { [weak self, sleep] in
            try? await sleep(item.duration)
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

    // MARK: - Scene ownership

    /// Which toasts a given presentation surface should render. A stamped
    /// toast shows only in its owning scene; an unstamped toast (ownership
    /// unknown, or macOS overlay) shows everywhere.
    static func visibleToasts(
        _ toasts: [ToastItem],
        in sceneStamp: ObjectIdentifier?
    ) -> [ToastItem] {
        guard let sceneStamp else { return toasts }
        return toasts.filter { $0.sceneStamp == nil || $0.sceneStamp == sceneStamp }
    }

    /// Stamps a new toast with the scene the user is acting in.
    ///
    /// Ownership is only claimed when it is unambiguous: exactly one
    /// foreground-active scene. With several foreground scenes (iPad
    /// side-by-side / Stage Manager) there is no reliable app-level signal
    /// for "which scene triggered this call" — each scene has its own key
    /// window — so guessing would misattribute feedback. Failing open
    /// (`nil` = show everywhere) duplicates a toast at worst; guessing wrong
    /// shows it only in the wrong window.
    private static func currentSceneStamp() -> ObjectIdentifier? {
        #if canImport(UIKit)
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        if scenes.count == 1 { return ObjectIdentifier(scenes[0]) }
        return nil
        #else
        return nil
        #endif
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
