import Combine
import Foundation

@MainActor
final class QuotaStore: ObservableObject {
    enum State: Equatable {
        case loading
        case live(QuotaSnapshot)
        case stale(QuotaSnapshot, Date)
        case unavailable

        var snapshot: QuotaSnapshot? {
            switch self {
            case .live(let snapshot), .stale(let snapshot, _): snapshot
            case .loading, .unavailable: nil
            }
        }
    }

    @Published private(set) var state: State = .loading

    private let provider: any QuotaProvider
    private var isRefreshing = false
    private var lastSuccessAt: Date?
    private var refreshTask: Task<Void, Never>?

    init(provider: any QuotaProvider = CodexQuotaProvider()) {
        self.provider = provider
    }

    func refresh(now: Date = .now) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let snapshot = try await provider.fetchQuota()
            lastSuccessAt = now
            state = .live(snapshot)
        } catch {
            if let snapshot = state.snapshot {
                state = .stale(snapshot, lastSuccessAt ?? now)
            } else {
                state = .unavailable
            }
        }
    }

    func startAutoRefresh(interval: Duration = .seconds(60)) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled else { break }
                await refresh()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
