import Foundation
import Testing
@testable import CodexHUD

@MainActor
struct QuotaStoreTests {
    @Test func firstSuccessfulRefreshPublishesLiveSnapshot() async {
        let snapshot = sampleSnapshot(remaining: 0.99)
        let store = QuotaStore(provider: SequenceQuotaProvider([.success(snapshot)]))

        await store.refresh()

        #expect(store.state == .live(snapshot))
    }

    @Test func failedRefreshKeepsLastSnapshotAsStale() async {
        let snapshot = sampleSnapshot(remaining: 0.42)
        let provider = SequenceQuotaProvider([.success(snapshot), .failure(TestError.failed)])
        let store = QuotaStore(provider: provider)

        await store.refresh()
        await store.refresh()

        guard case .stale(let staleSnapshot, _) = store.state else {
            Issue.record("Expected stale state")
            return
        }
        #expect(staleSnapshot == snapshot)
    }

    @Test func firstFailurePublishesUnavailable() async {
        let store = QuotaStore(provider: SequenceQuotaProvider([.failure(TestError.failed)]))
        await store.refresh()
        #expect(store.state == .unavailable)
    }

    @Test func concurrentRefreshesAreCoalesced() async {
        let provider = BlockingQuotaProvider(snapshot: sampleSnapshot(remaining: 0.8))
        let store = QuotaStore(provider: provider)

        async let first: Void = store.refresh()
        async let second: Void = store.refresh()
        _ = await (first, second)

        #expect(await provider.fetchCount == 1)
    }

    private func sampleSnapshot(remaining: Double) -> QuotaSnapshot {
        QuotaSnapshot(remainingFraction: remaining, resetsAt: Date(timeIntervalSince1970: 2_000), resetCredits: 3)
    }
}

private enum TestError: Error { case failed }

private actor SequenceQuotaProvider: QuotaProvider {
    private var results: [Result<QuotaSnapshot, Error>]
    init(_ results: [Result<QuotaSnapshot, Error>]) { self.results = results }

    func fetchQuota() async throws -> QuotaSnapshot {
        guard !results.isEmpty else { throw TestError.failed }
        return try results.removeFirst().get()
    }
}

private actor BlockingQuotaProvider: QuotaProvider {
    private(set) var fetchCount = 0
    private let snapshot: QuotaSnapshot
    init(snapshot: QuotaSnapshot) { self.snapshot = snapshot }

    func fetchQuota() async throws -> QuotaSnapshot {
        fetchCount += 1
        try? await Task.sleep(for: .milliseconds(30))
        return snapshot
    }
}
