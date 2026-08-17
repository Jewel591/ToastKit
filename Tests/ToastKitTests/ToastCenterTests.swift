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

    @Test func toastStaysVisibleUntilItsDurationElapses() async throws {
        let sleeper = CancellationRecordingSleeper()
        let center = ToastCenter(sleep: sleeper.sleep)

        center.show(title: "Saved", duration: 17)

        // The sleeper never returns, so if the toast disappears here the
        // production code stopped awaiting the duration at all.
        try await Task.sleep(for: .milliseconds(150))
        #expect(center.toasts.count == 1)
        // The requested duration must reach the suspension primitive intact.
        try await waitUntil { sleeper.receivedDurations == [17] }
        #expect(sleeper.receivedDurations == [17])

        center.dismissAll()
    }

    @Test func toastDismissesOnceItsDurationElapses() async throws {
        let sleeper = ManualSleeper()
        let center = ToastCenter(sleep: sleeper.sleep)

        center.show(title: "Saved", duration: 9)
        #expect(center.toasts.count == 1)

        sleeper.release()
        try await waitUntil { center.toasts.isEmpty }
        #expect(center.toasts.isEmpty)
        #expect(sleeper.receivedDurations == [9])
    }

    @Test func toastAutoDismissesWithTheRealClock() async throws {
        let center = ToastCenter()

        center.show(title: "Saved", duration: 0.05)
        #expect(center.toasts.count == 1)

        try await waitUntil { center.toasts.isEmpty }
        #expect(center.toasts.isEmpty)
    }

    @Test func burstIsCappedAndOldestYieldsFirst() {
        let center = ToastCenter()

        for index in 1...5 {
            center.show(title: "toast-\(index)", duration: 60)
        }

        #expect(center.toasts.map(\.title) == ["toast-3", "toast-4", "toast-5"])
    }

    @Test func evictionCancelsTheEvictedToastTimer() async throws {
        let sleeper = CancellationRecordingSleeper()
        let center = ToastCenter(sleep: sleeper.sleep)

        center.show(title: "evicted", duration: 60)
        for index in 1...3 {
            center.show(title: "toast-\(index)", duration: 60)
        }

        try await waitUntil { sleeper.cancellations == 1 }
        #expect(sleeper.cancellations == 1)
        #expect(center.toasts.map(\.title) == ["toast-1", "toast-2", "toast-3"])

        center.dismissAll()
    }

    @Test func dismissAllRemovesEverythingImmediately() {
        let center = ToastCenter()
        center.show(title: "a", duration: 60)
        center.show(title: "b", duration: 60)

        center.dismissAll()

        #expect(center.toasts.isEmpty)
    }

    @Test func dismissAllCancelsEveryPendingTimer() async throws {
        let sleeper = CancellationRecordingSleeper()
        let center = ToastCenter(sleep: sleeper.sleep)
        center.show(title: "a", duration: 60)
        center.show(title: "b", duration: 60)

        center.dismissAll()

        try await waitUntil { sleeper.cancellations == 2 }
        #expect(sleeper.cancellations == 2)
        #expect(center.toasts.isEmpty)
    }

    @Test func evictionIsScopedToTheOwningScene() {
        let anchorA = NSObject()
        let anchorB = NSObject()
        let sceneA = ObjectIdentifier(anchorA)
        let sceneB = ObjectIdentifier(anchorB)
        let center = ToastCenter()

        func item(_ title: String, stamp: ObjectIdentifier) -> ToastItem {
            ToastItem(title: title, subtitle: nil, style: .info,
                      duration: 60, sceneStamp: stamp)
        }

        for index in 1...3 {
            center.insert(item("a-\(index)", stamp: sceneA))
        }
        for index in 1...3 {
            center.insert(item("b-\(index)", stamp: sceneB))
        }
        // Scene B is at its cap; scene A's toasts must be untouched.
        #expect(center.toasts.count == 6)

        center.insert(item("b-4", stamp: sceneB))

        #expect(ToastCenter.visibleToasts(center.toasts, in: sceneA)
            .map(\.title) == ["a-1", "a-2", "a-3"])
        #expect(ToastCenter.visibleToasts(center.toasts, in: sceneB)
            .map(\.title) == ["b-2", "b-3", "b-4"])

        center.dismissAll()
    }

    @Test func broadcastToastEvictsToKeepEveryScreenAtTheCap() {
        let anchorA = NSObject()
        let sceneA = ObjectIdentifier(anchorA)
        let center = ToastCenter()

        for index in 1...3 {
            center.insert(ToastItem(
                title: "a-\(index)", subtitle: nil, style: .info,
                duration: 60, sceneStamp: sceneA
            ))
        }
        // Scene A's screen already shows 3; a broadcast toast lands there
        // too, so the oldest visible toast must yield first.
        center.insert(ToastItem(
            title: "broadcast", subtitle: nil, style: .info,
            duration: 60, sceneStamp: nil
        ))

        #expect(ToastCenter.visibleToasts(center.toasts, in: sceneA)
            .map(\.title) == ["a-2", "a-3", "broadcast"])

        center.dismissAll()
    }

    @Test func sharedBroadcastYieldsBeforeSceneSpecificToastsWhenBothScreensAreFull() {
        let anchorA = NSObject()
        let anchorB = NSObject()
        let sceneA = ObjectIdentifier(anchorA)
        let sceneB = ObjectIdentifier(anchorB)
        let center = ToastCenter()

        func insert(_ title: String, stamp: ObjectIdentifier?) {
            center.insert(ToastItem(
                title: title, subtitle: nil, style: .info,
                duration: 60, sceneStamp: stamp
            ))
        }

        // Both screens sit exactly at the cap, sharing one old broadcast:
        // A sees [broadcast-old, a-1, a-2], B sees [b-1, broadcast-old, b-2].
        insert("b-1", stamp: sceneB)
        insert("broadcast-old", stamp: nil)
        insert("a-1", stamp: sceneA)
        insert("a-2", stamp: sceneA)
        insert("b-2", stamp: sceneB)

        // A new broadcast overloads both screens. Evicting the shared old
        // broadcast frees both in one step; evicting any scene-specific
        // toast first would cost an extra, avoidable eviction. The outcome
        // must be this exact queue regardless of hash seed.
        insert("broadcast-new", stamp: nil)

        #expect(center.toasts.map(\.title)
            == ["b-1", "a-1", "a-2", "b-2", "broadcast-new"])

        center.dismissAll()
    }

    @Test func sceneScopedToastIsOnlyVisibleInItsOwningScene() {
        // Keep the anchor objects alive: a deallocated address can be reused
        // and would silently collapse the two identifiers into one.
        let anchorA = NSObject()
        let anchorB = NSObject()
        let sceneA = ObjectIdentifier(anchorA)
        let sceneB = ObjectIdentifier(anchorB)
        let owned = ToastItem(
            title: "owned", subtitle: nil, style: .info,
            duration: 2, sceneStamp: sceneA
        )
        let unowned = ToastItem(
            title: "unowned", subtitle: nil, style: .info,
            duration: 2, sceneStamp: nil
        )

        #expect(ToastCenter.visibleToasts([owned, unowned], in: sceneA)
            .map(\.title) == ["owned", "unowned"])
        #expect(ToastCenter.visibleToasts([owned, unowned], in: sceneB)
            .map(\.title) == ["unowned"])
        // A surface without a scene identity (macOS overlay) renders all.
        #expect(ToastCenter.visibleToasts([owned, unowned], in: nil)
            .map(\.title) == ["owned", "unowned"])
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
