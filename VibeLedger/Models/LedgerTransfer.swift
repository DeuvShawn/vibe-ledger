import Foundation

struct LedgerTransfer: Codable {
    let transactions: [TransactionRecord]

    init(transactions: [TransactionRecord]) {
        self.transactions = transactions
    }
}

struct TransactionRecord: Codable {
    let id: UUID
    let title: String
    let amount: Decimal
    let createdAt: Date
    let category: TransactionCategory

    init(id: UUID, title: String, amount: Decimal, createdAt: Date, category: TransactionCategory) {
        self.id = id
        self.title = title
        self.amount = amount
        self.createdAt = createdAt
        self.category = category
    }

    init(transaction: Transaction) {
        self.id = transaction.id
        self.title = transaction.title
        self.amount = transaction.amount
        self.createdAt = transaction.createdAt
        self.category = transaction.category
    }

    var transaction: Transaction {
        Transaction(id: id, title: title, amount: amount, createdAt: createdAt, category: category)
    }
}

