import SwiftUI

/// Shared layout constants for the toast layer.
enum ToastLayout {
    /// House-standard distance from the top safe area to the first toast.
    /// Mirrors the system's own transient indicators (AirPods, silent mode),
    /// which sit directly below the status bar.
    static let topPadding: CGFloat = 8
}

/// Installs the toast presentation surface.
///
/// Attach exactly once, on the root view of the scene:
///
/// ```swift
/// WindowGroup {
///     RootView()
///         .toastHost()
/// }
/// ```
///
/// On iOS the toasts render in a dedicated pass-through window above sheets
/// and full-screen covers (see `ToastWindow.swift`); macOS has no competing
/// modal window layer, so a plain overlay is sufficient there.
public struct ToastHostModifier: ViewModifier {
    #if canImport(UIKit)
    @Environment(\.colorScheme) private var colorScheme

    public func body(content: Content) -> some View {
        content
            .background(
                ToastWindowInstaller(colorScheme: colorScheme)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            )
    }
    #else
    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                // Non-interactive by contract: the overlay must never steal
                // clicks from the content beneath it.
                ToastContainerView(sceneStamp: nil)
                    .padding(.top, ToastLayout.topPadding)
                    .allowsHitTesting(false)
            }
    }
    #endif
}

public extension View {
    /// Installs the toast presentation surface on this view's scene.
    func toastHost() -> some View {
        modifier(ToastHostModifier())
    }
}
