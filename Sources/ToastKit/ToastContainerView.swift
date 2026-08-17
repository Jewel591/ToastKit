import SwiftUI

/// Stacks the currently visible toasts. Internal: installed exclusively by
/// `.toastHost()`.
struct ToastContainerView: View {
    private let center = ToastCenter.shared

    var body: some View {
        VStack(spacing: 8) {
            ForEach(center.toasts) { toast in
                ToastView(item: toast)
            }
        }
        .animation(ToastCenter.houseAnimation, value: center.toasts)
    }
}
