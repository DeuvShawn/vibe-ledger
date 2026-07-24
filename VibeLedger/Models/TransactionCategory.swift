import Foundation

enum TransactionCategory: String, CaseIterable, Codable, Identifiable {
    case food = "餐饮"
    case transport = "交通"
    case lodging = "住宿"
    case shopping = "购物"
    case entertainment = "娱乐"

    var id: String { rawValue }
}

