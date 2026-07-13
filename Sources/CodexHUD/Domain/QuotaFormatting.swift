import Foundation

enum QuotaFormatting {
    static func percent(_ fraction: Double) -> String {
        let clamped = min(max(fraction, 0), 1)
        return "\(Int((clamped * 100).rounded()))%"
    }

    static func credits(_ count: Int?) -> String {
        guard let count else { return "重置 --" }
        return "重置 ×\(max(count, 0))"
    }

    static func resetDate(
        _ date: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let interval = date.timeIntervalSince(now)
        if interval >= 0, interval < 24 * 3600 {
            return "\(max(0, Int(interval / 3600)))小时后"
        }

        let resetYear = calendar.component(.year, from: date)
        let currentYear = calendar.component(.year, from: now)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = resetYear == currentYear ? "M月d日" : "yyyy年M月d日"
        return formatter.string(from: date)
    }
}
