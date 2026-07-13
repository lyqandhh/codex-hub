import Foundation

protocol QuotaProvider: Sendable {
    func fetchQuota() async throws -> QuotaSnapshot
}

struct CodexQuotaProvider: QuotaProvider {
    let client: CodexAppServerClient

    init(client: CodexAppServerClient = CodexAppServerClient()) {
        self.client = client
    }

    func fetchQuota() async throws -> QuotaSnapshot {
        try RateLimitResponseParser.parse(data: await client.requestRateLimits())
    }
}
