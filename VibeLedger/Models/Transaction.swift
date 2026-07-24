import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Decimal
    var createdAt: Date
    var category: TransactionCategory

    init(id: UUID = UUID(), title: String, amount: Decimal, createdAt: Date, category: TransactionCategory) {
        self.id = id
        self.title = title
        self.amount = amount
        self.createdAt = createdAt
        self.category = category
    }
}

