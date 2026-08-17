#if canImport(UIKit)
import SwiftUI
import UIKit

/// Hosts the toast layer in a dedicated pass-through window (iOS).
///
/// Toasts must render above sheets and full-screen covers; an overlay on the
/// root view sits below any modal presentation layer, so the kit owns a
/// separate `UIWindow` above the alert level instead.
@MainActor
final class ToastWindowManager {
    static let shared = ToastWindowManager()

    /// One window per `UIWindowScene`: iPad multi-window / Stage Manager
    /// scenes each get their own toast layer and never cover each other.
    private struct Entry {
        let window: PassthroughWindow
        let hostingController: UIHostingController<ToastWindowRoot>
    }

    private var entries: [ObjectIdentifier: Entry] = [:]
    private var disconnectObserver: (any NSObjectProtocol)?

    private init() {}

    func install(in scene: UIWindowScene, colorScheme: ColorScheme) {
        startObservingSceneDisconnectIfNeeded()

        let key = ObjectIdentifier(scene)
        if let entry = entries[key] {
            // theme-policy-exempt: force — The separate toast window must mirror the host app's already-resolved user appearance
            entry.window.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
            return
        }

        let host = UIHostingController(rootView: ToastWindowRoot())
        host.view.backgroundColor = .clear

        let window = PassthroughWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.rootViewController = host
        // A standalone window only follows the system appearance by default;
        // it must mirror the host app's effective scheme (including a manual
        // preferredColorScheme override) or toasts render in the wrong theme.
        // theme-policy-exempt: force — The separate toast window must mirror the host app's already-resolved user appearance
        window.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        window.isHidden = false

        entries[key] = Entry(window: window, hostingController: host)
    }

    /// Releases the window when its scene disconnects so the manager never
    /// holds stale references to dead scenes.
    private func startObservingSceneDisconnectIfNeeded() {
        guard disconnectObserver == nil else { return }
        disconnectObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let scene = notification.object as? UIWindowScene else { return }
            let key = ObjectIdentifier(scene)
            MainActor.assumeIsolated {
                ToastWindowManager.shared.remove(forKey: key)
            }
        }
    }

    private func remove(forKey key: ObjectIdentifier) {
        guard let entry = entries.removeValue(forKey: key) else { return }
        entry.window.isHidden = true
        entry.window.rootViewController = nil
    }
}

private struct ToastWindowRoot: View {
    var body: some View {
        ToastContainerView()
            .padding(.top, ToastLayout.topPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

/// Fully touch-transparent window: toasts are non-interactive, every tap
/// falls through to the windows below.
private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
}

/// A zero-size probe attached to the host view; once it can reach the
/// `UIWindowScene` it installs the toast window, and re-syncs the effective
/// color scheme whenever the environment changes.
struct ToastWindowInstaller: UIViewRepresentable {
    let colorScheme: ColorScheme

    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.colorScheme = colorScheme
        return view
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {
        uiView.colorScheme = colorScheme
        uiView.installIfPossible()
    }

    final class InstallerView: UIView {
        var colorScheme: ColorScheme = .light

        override func didMoveToWindow() {
            super.didMoveToWindow()
            installIfPossible()
        }

        func installIfPossible() {
            guard let scene = window?.windowScene else { return }
            ToastWindowManager.shared.install(in: scene, colorScheme: colorScheme)
        }
    }
}
#endif
