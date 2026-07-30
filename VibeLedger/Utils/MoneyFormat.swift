import Foundation

enum MoneyFormat {
    static func parseDecimal(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var normalized = trimmed
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "．", with: ".")
            .replacingOccurrences(of: "。", with: ".")

        if normalized.contains(",") && normalized.contains(".") {
            normalized = normalized.replacingOccurrences(of: ",", with: "")
        } else if normalized.contains(",") {
            normalized = normalized.replacingOccurrences(of: ",", with: ".")
        }

        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func currencyString(for value: Decimal, currencyCode: String = "CNY") -> String {
        let symbol: String
        let localeID: String

        switch currencyCode {
        case "USD":
            symbol = "$"
            localeID = "en_US"
        default:
            symbol = "¥"
            localeID = "zh_CN"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: localeID)
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = symbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
