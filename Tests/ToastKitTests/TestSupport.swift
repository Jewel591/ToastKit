import Foundation
@testable import ToastKit

/// A sleep primitive that never returns on its own and records every
/// cancellation. Proves that eviction and `dismissAll()` really cancel the
/// pending auto-dismiss work — with the real clock, an un-cancelled timer is
/// invisible to value assertions (it fires later against an id that no
/// longer exists).
final class CancellationRecordingSleeper: @unchecked Sendable {
    private let lock = NSLock()
    private var _cancellations = 0
    private var _receivedDurations: [TimeInterval] = []

    var cancellations: Int { lock.withLock { _cancellations } }

    /// The durations production code actually asked for — guards against a
    /// regression that sleeps the wrong amount (e.g. hardcoding 2s and
    /// ignoring a call site's 10s reading time).
    var receivedDurations: [TimeInterval] { lock.withLock { _receivedDurations } }

    func sleep(_ duration: TimeInterval) async throws {
        lock.withLock { _receivedDurations.append(duration) }
        do {
            // Effectively forever; only task cancellation ends it.
            try await Task.sleep(for: .seconds(3600))
        } catch {
            lock.withLock { _cancellations += 1 }
            throw error
        }
    }
}

/// A sleep primitive released manually by the test. Proves the "stays
/// visible until the duration elapses, dismisses right after" contract
/// without racing wall-clock timers.
final class ManualSleeper: @unchecked Sendable {
    private let lock = NSLock()
    private var _receivedDurations: [TimeInterval] = []
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream()
    }

    var receivedDurations: [TimeInterval] { lock.withLock { _receivedDurations } }

    func sleep(_ duration: TimeInterval) async throws {
        lock.withLock { _receivedDurations.append(duration) }
        var iterator = stream.makeAsyncIterator()
        _ = await iterator.next()
        try Task.checkCancellation()
    }

    func release() {
        continuation.yield()
    }
}

/// Polls a main-actor condition until it holds or the ceiling is reached.
@MainActor
func waitUntil(
    _ condition: @MainActor () -> Bool,
    attempts: Int = 200
) async throws {
    for _ in 0..<attempts where !condition() {
        try await Task.sleep(for: .milliseconds(10))
    }
}
