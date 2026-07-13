import Foundation

enum RateLimitParsingError: Error, Equatable {
    case missingWindow
    case missingResetTime
    case invalidResponse
}

enum RateLimitResponseParser {
    static func parse(data: Data) throws -> QuotaSnapshot {
        let envelope: Envelope
        do {
            envelope = try JSONDecoder().decode(Envelope.self, from: data)
        } catch {
            throw RateLimitParsingError.invalidResponse
        }

        let windows = [envelope.result.rateLimits.primary, envelope.result.rateLimits.secondary].compactMap { $0 }
        guard let window = windows.max(by: { ($0.windowDurationMins ?? 0) < ($1.windowDurationMins ?? 0) }) else {
            throw RateLimitParsingError.missingWindow
        }
        guard let resetsAt = window.resetsAt else {
            throw RateLimitParsingError.missingResetTime
        }

        let remaining = 1 - min(max(Double(window.usedPercent) / 100, 0), 1)
        return QuotaSnapshot(
            remainingFraction: remaining,
            resetsAt: Date(timeIntervalSince1970: TimeInterval(resetsAt)),
            resetCredits: envelope.result.rateLimitResetCredits?.availableCount
        )
    }
}

private struct Envelope: Decodable {
    let result: ResultPayload
}

private struct ResultPayload: Decodable {
    let rateLimits: RateLimits
    let rateLimitResetCredits: ResetCredits?
}

private struct RateLimits: Decodable {
    let primary: Window?
    let secondary: Window?
}

private struct Window: Decodable {
    let usedPercent: Int
    let windowDurationMins: Int64?
    let resetsAt: Int64?
}

private struct ResetCredits: Decodable {
    let availableCount: Int
}
