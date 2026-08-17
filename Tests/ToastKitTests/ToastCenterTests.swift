import Foundation
import Observation
import Testing
@testable import ToastKit

@MainActor
struct ToastCenterTests {

    @Test func showAppendsItemWithGivenContent() {
        let center = ToastCenter()

        center.show(title: "Saved", subtitle: "3 records", style: .success, duration: 60)

        #expect(center.toasts.count == 1)
        let item = try? #require(center.toasts.first)
        #expect(item?.title == "Saved")
        #expect(item?.subtitle == "3 records")
        #expect(item?.style == .success)
        #expect(item?.duration == 60)
    }

    @Test func emptySubtitleIsNormalizedToNil() {
        let center = ToastCenter()

        center.show(title: "Saved", subtitle: "", duration: 60)

        #expect(center.toasts.first?.subtitle == nil)
    }

    @Test func defaultDurationIsTheHouseStandardTwoSeconds() {
        let center = ToastCenter()

        center.show(title: "Saved")

        #expect(center.toasts.first?.duration == 2.0)
        #expect(ToastCenter.defaultDuration == 2.0)
    }

    @Test(arguments: [
        (ToastStyle.success, "success"),
        (ToastStyle.error, "error"),
        (ToastStyle.warning, "warning"),
        (ToastStyle.info, "info"),
    ])
    func convenienceMethodsMapToTheirStyles(style: ToastStyle, name: String) {
        let center = ToastCenter()

        switch style {
        case .success: center.showSuccess(title: name)
        case .error: center.showError(title: name)
        case .warning: center.showWarning(title: name)
        case .info: center.showInfo(title: name)
        }

        #expect(center.toasts.map(\.style) == [style])
        #expect(center.toasts.map(\.title) == [name])
    }

    @Test func toastsStackInPresentationOrder() {
        let center = ToastCenter()

        center.show(title: "first", duration: 60)
        center.show(title: "second", duration: 60)

        #expect(center.toasts.map(\.title) == ["first", "second"])
    }

    @Test func toastAutoDismissesAfterItsDuration() async throws {
        let center = ToastCenter()

        center.show(title: "Saved", duration: 0.05)
        #expect(center.toasts.count == 1)

        // Generous ceiling; the toast should be gone long before this.
        for _ in 0..<200 where !center.toasts.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(center.toasts.isEmpty)
    }

    @Test func burstIsCappedAndOldestYieldsFirst() {
        let center = ToastCenter()

        for index in 1...5 {
            center.show(title: "toast-\(index)", duration: 60)
        }

        #expect(center.toasts.map(\.title) == ["toast-3", "toast-4", "toast-5"])
    }

    @Test func evictedToastTimerCannotSweepLaterToasts() async throws {
        let center = ToastCenter()

        // The first toast's short timer is cancelled when it is evicted by
        // the burst; it must not fire later and remove anything.
        center.show(title: "short-lived", duration: 0.05)
        for index in 1...3 {
            center.show(title: "toast-\(index)", duration: 60)
        }
        try await Task.sleep(for: .milliseconds(200))

        #expect(center.toasts.map(\.title) == ["toast-1", "toast-2", "toast-3"])
    }

    @Test func dismissAllRemovesEverythingImmediately() {
        let center = ToastCenter()
        center.show(title: "a", duration: 60)
        center.show(title: "b", duration: 60)

        center.dismissAll()

        #expect(center.toasts.isEmpty)
    }

    @Test func dismissAllCancelsPendingAutoDismissWork() async throws {
        let center = ToastCenter()
        center.show(title: "a", duration: 0.05)
        center.dismissAll()

        // A toast shown after dismissAll must not be swept away by the
        // earlier toast's stale timer.
        center.show(title: "b", duration: 60)
        try await Task.sleep(for: .milliseconds(200))

        #expect(center.toasts.map(\.title) == ["b"])
    }

    /// Guards the Observation notification itself, not just the value:
    /// per the house #316 lesson, a correct value with a swallowed
    /// notification renders stale UI.
    @Test func showNotifiesObservers() async {
        let center = ToastCenter()

        await confirmation { fired in
            withObservationTracking {
                _ = center.toasts
            } onChange: {
                fired()
            }
            center.show(title: "Saved", duration: 60)
        }
    }
}
