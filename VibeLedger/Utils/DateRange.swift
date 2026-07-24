import Foundation

enum DateRange {
    static func startOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func endOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar.date(from: components) ?? date
    }

    static func contains(_ date: Date, start: Date?, end: Date?) -> Bool {
        if let start {
            if date < start { return false }
        }
        if let end {
            if date > end { return false }
        }
        return true
    }

    static func label(start: Date?, end: Date?) -> String {
        guard let start, let end else { return "全部" }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy/MM/dd"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

