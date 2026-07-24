import SwiftUI
import SwiftData

struct SearchView: View {
    @Query(sort: \Transaction.createdAt, order: .reverse)
    private var transactions: [Transaction]

    @State private var searchText = ""
    @State private var selectedTransactionForEdit: Transaction?

    private var matchedTransactions: [Transaction] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return transactions }

        let normalizedKeyword = normalizedSearchToken(keyword)

        return transactions.filter { transaction in
            let formattedAmount = MoneyFormat.currencyString(for: transaction.amount)
            let rawAmount = NSDecimalNumber(decimal: transaction.amount).stringValue

            return transaction.title.localizedCaseInsensitiveContains(keyword) ||
                transaction.category.rawValue.localizedCaseInsensitiveContains(keyword) ||
                formattedAmount.localizedCaseInsensitiveContains(keyword) ||
                normalizedSearchToken(formattedAmount).contains(normalizedKeyword) ||
                normalizedSearchToken(rawAmount).contains(normalizedKeyword)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if matchedTransactions.isEmpty {
                    Section {
                        Text(searchText.isEmpty ? "输入关键词搜索记账条目" : "没有匹配到相关记账条目")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(matchedTransactions) { transaction in
                            Button {
                                selectedTransactionForEdit = transaction
                            } label: {
                                SearchTransactionRow(transaction: transaction)
                            }
                        }
                    } header: {
                        Text("共 \(matchedTransactions.count) 条")
                    }
                }
            }
            .navigationTitle("搜索")
            .searchable(text: $searchText, prompt: "搜索名称、分类或金额")
            .sheet(item: $selectedTransactionForEdit) { transaction in
                EditTransactionView(transaction: transaction)
            }
            .listStyle(.plain)
        }
    }
}

private func normalizedSearchToken(_ text: String) -> String {
    text
        .lowercased()
        .replacingOccurrences(of: "¥", with: "")
        .replacingOccurrences(of: "￥", with: "")
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: " ", with: "")
}

private struct SearchTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(transaction.category.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay {
                        Capsule().stroke(Color.secondary.opacity(0.25))
                    }

                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(transaction.title)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(MoneyFormat.currencyString(for: transaction.amount))
                    .font(.body.monospacedDigit())
            }

            Text(transaction.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
