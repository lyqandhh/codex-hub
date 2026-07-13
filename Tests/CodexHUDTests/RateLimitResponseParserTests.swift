import Foundation
import Testing
@testable import CodexHUD

struct RateLimitResponseParserTests {
    @Test func parsesWeeklyWindowAndResetCredits() throws {
        let reset: Int64 = 1_784_483_200
        let data = json("""
        {"id":2,"result":{"rateLimits":{"primary":{"usedPercent":1,"windowDurationMins":10080,"resetsAt":\(reset)},"secondary":null},"rateLimitResetCredits":{"availableCount":3,"credits":null}}}
        """)

        let snapshot = try RateLimitResponseParser.parse(data: data)

        #expect(snapshot.remainingFraction == 0.99)
        #expect(snapshot.resetsAt == Date(timeIntervalSince1970: TimeInterval(reset)))
        #expect(snapshot.resetCredits == 3)
    }

    @Test func selectsLongestWindowWhenPrimaryAndSecondaryExist() throws {
        let data = json("""
        {"result":{"rateLimits":{"primary":{"usedPercent":80,"windowDurationMins":300,"resetsAt":1000},"secondary":{"usedPercent":40,"windowDurationMins":10080,"resetsAt":2000}},"rateLimitResetCredits":{"availableCount":0}}}
        """)

        let snapshot = try RateLimitResponseParser.parse(data: data)

        #expect(snapshot.remainingFraction == 0.60)
        #expect(snapshot.resetsAt == Date(timeIntervalSince1970: 2000))
        #expect(snapshot.resetCredits == 0)
    }

    @Test func missingResetCreditsRemainUnknown() throws {
        let data = json("""
        {"result":{"rateLimits":{"primary":{"usedPercent":25,"windowDurationMins":10080,"resetsAt":2000}}}}
        """)

        #expect(try RateLimitResponseParser.parse(data: data).resetCredits == nil)
    }

    @Test func invalidUsedPercentageIsClamped() throws {
        let high = json(#"{"result":{"rateLimits":{"primary":{"usedPercent":130,"resetsAt":2000}}}}"#)
        let low = json(#"{"result":{"rateLimits":{"primary":{"usedPercent":-10,"resetsAt":2000}}}}"#)
        #expect(try RateLimitResponseParser.parse(data: high).remainingFraction == 0)
        #expect(try RateLimitResponseParser.parse(data: low).remainingFraction == 1)
    }

    @Test func missingUsableWindowThrows() {
        let data = json(#"{"result":{"rateLimits":{"primary":null,"secondary":null}}}"#)
        #expect(throws: RateLimitParsingError.self) {
            try RateLimitResponseParser.parse(data: data)
        }
    }

    private func json(_ value: String) -> Data { Data(value.utf8) }
}
