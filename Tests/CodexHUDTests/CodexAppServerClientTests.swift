import Foundation
import Testing
@testable import CodexHUD

struct CodexAppServerClientTests {
    @Test func requestsOnlyInitializationAndReadOnlyRateLimits() async throws {
        let response = Data(#"{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":1,"windowDurationMins":10080,"resetsAt":2000}},"rateLimitResetCredits":{"availableCount":3}}}"#.utf8)
        let transport = RecordingTransport(response: response)
        let client = CodexAppServerClient(transport: transport)

        _ = try await client.requestRateLimits()

        let methods = try transport.requests.map { data -> String in
            let object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            return object["method"] as! String
        }
        #expect(methods == ["initialize", "account/rateLimits/read"])
        #expect(methods.allSatisfy { !$0.contains("consume") })
    }

    @Test func quotaProviderParsesClientResponse() async throws {
        let response = Data(#"{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":1,"windowDurationMins":10080,"resetsAt":2000}},"rateLimitResetCredits":{"availableCount":3}}}"#.utf8)
        let provider = CodexQuotaProvider(client: CodexAppServerClient(transport: RecordingTransport(response: response)))

        let snapshot = try await provider.fetchQuota()

        #expect(snapshot.remainingFraction == 0.99)
        #expect(snapshot.resetCredits == 3)
    }

    @Test func clientRejectsUnexpectedResponse() async {
        let transport = RecordingTransport(response: Data(#"{"id":9,"result":{}}"#.utf8))
        let client = CodexAppServerClient(transport: transport)
        await #expect(throws: CodexAppServerError.self) {
            try await client.requestRateLimits()
        }
    }
}

private final class RecordingTransport: AppServerTransport, @unchecked Sendable {
    private(set) var requests: [Data] = []
    private let response: Data

    init(response: Data) { self.response = response }

    func exchange(requests: [Data], responseID: Int) throws -> Data {
        self.requests = requests
        return response
    }
}
