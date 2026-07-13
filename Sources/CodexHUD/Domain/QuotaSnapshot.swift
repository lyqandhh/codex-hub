import Foundation

struct QuotaSnapshot: Equatable, Sendable, Codable {
    let remainingFraction: Double
    let resetsAt: Date
    let resetCredits: Int?

    init(remainingFraction: Double, resetsAt: Date, resetCredits: Int?) {
        self.remainingFraction = min(max(remainingFraction, 0), 1)
        self.resetsAt = resetsAt
        self.resetCredits = resetCredits.map { max($0, 0) }
    }
}
