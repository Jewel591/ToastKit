import SwiftUI

/// Stacks the toasts owned by one presentation surface. Internal: installed
/// exclusively by `.toastHost()`.
struct ToastContainerView: View {
    /// The scene this surface belongs to; `nil` renders every toast
    /// (macOS overlay, or ownership unknown).
    let sceneStamp: ObjectIdentifier?

    private let center = ToastCenter.shared

    private var visibleToasts: [ToastItem] {
        ToastCenter.visibleToasts(center.toasts, in: sceneStamp)
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(visibleToasts) { toast in
                ToastView(item: toast)
            }
        }
        .animation(ToastCenter.houseAnimation, value: visibleToasts)
        .allowsHitTesting(false)
    }
}
