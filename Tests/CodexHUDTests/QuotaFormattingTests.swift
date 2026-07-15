import Foundation
import Testing
@testable import CodexHUD

struct QuotaFormattingTests {
    @Test func percentageIsClampedAndRounded() {
        #expect(QuotaFormatting.percent(-0.2) == "0%")
        #expect(QuotaFormatting.percent(0.994) == "99%")
        #expect(QuotaFormatting.percent(1.4) == "100%")
    }

    @Test func ringValueDropsPercentSign() {
        #expect(QuotaFormatting.ringValue(0.984) == "98")
        #expect(QuotaFormatting.ringValue(1.4) == "100")
    }

    @Test func compactResetDateUsesShortNumericFormat() {
        let calendar = utcCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))!
        let sameYear = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20))!
        let nextYear = calendar.date(from: DateComponents(year: 2027, month: 1, day: 2))!
        #expect(QuotaFormatting.compactResetDate(sameYear, now: now, calendar: calendar) == "7/20")
        #expect(QuotaFormatting.compactResetDate(nextYear, now: now, calendar: calendar) == "27/1/2")
    }

    @Test func resetCreditsDistinguishZeroFromMissing() {
        #expect(QuotaFormatting.credits(3) == "重置 ×3")
        #expect(QuotaFormatting.credits(0) == "重置 ×0")
        #expect(QuotaFormatting.credits(nil) == "重置 --")
    }

    @Test func compactCreditsOmitUnknownValueInsteadOfShowingPlaceholder() {
        #expect(QuotaFormatting.compactCredits(nil) == nil)
        #expect(QuotaFormatting.compactCredits(3) == "×3")
        #expect(QuotaFormatting.compactCredits(0) == "×0")
    }

    @Test func accessibilitySummaryOmitsUnknownResetCreditPlaceholder() {
        let calendar = utcCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))!
        let reset = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20))!

        let summary = QuotaFormatting.accessibilitySummary(
            remainingFraction: 0.97,
            resetCredits: nil,
            resetsAt: reset,
            now: now,
            calendar: calendar
        )

        #expect(summary.contains("本周剩余 97%"))
        #expect(summary.contains("7月20日"))
        #expect(!summary.contains("--"))
        #expect(!summary.contains("重置 ×"))
    }

    @Test func accessibilitySummaryKeepsKnownResetCreditCounts() {
        let calendar = utcCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))!
        let reset = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20))!

        let zero = QuotaFormatting.accessibilitySummary(
            remainingFraction: 0.97,
            resetCredits: 0,
            resetsAt: reset,
            now: now,
            calendar: calendar
        )
        let two = QuotaFormatting.accessibilitySummary(
            remainingFraction: 0.97,
            resetCredits: 2,
            resetsAt: reset,
            now: now,
            calendar: calendar
        )

        #expect(zero.contains("重置 ×0"))
        #expect(two.contains("重置 ×2"))
    }

    @Test func resetDateUsesRelativeHoursWithinOneDay() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let reset = now.addingTimeInterval(18 * 3600 + 20 * 60)
        #expect(QuotaFormatting.resetDate(reset, now: now, calendar: utcCalendar) == "18小时后")
    }

    @Test func resetDateUsesMonthAndDayBeyondOneDay() {
        let calendar = utcCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))!
        let reset = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20))!
        #expect(QuotaFormatting.resetDate(reset, now: now, calendar: calendar) == "7月20日")
    }

    @Test func resetDateIncludesYearWhenCrossingYear() {
        let calendar = utcCalendar
        let now = calendar.date(from: DateComponents(year: 2026, month: 12, day: 30))!
        let reset = calendar.date(from: DateComponents(year: 2027, month: 1, day: 2))!
        #expect(QuotaFormatting.resetDate(reset, now: now, calendar: calendar) == "2027年1月2日")
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
