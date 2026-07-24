import SwiftUI
import SwiftData

struct EditTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let transaction: Transaction

    @State private var titleText: String
    @State private var amountText: String
    @State private var category: TransactionCategory
    @State private var createdAt: Date

    @State private var isShowingError = false
    @State private var errorMessage = ""

    init(transaction: Transaction) {
        self.transaction = transaction

        _titleText = State(initialValue: transaction.title)
        _amountText = State(initialValue: "\(transaction.amount)")
        _category = State(initialValue: transaction.category)
        _createdAt = State(initialValue: transaction.createdAt)
    }

    private var trimmedTitle: String {
        titleText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedAmount: Decimal? {
        MoneyFormat.parseDecimal(amountText)
    }

    private var canSave: Bool {
        guard !trimmedTitle.isEmpty else { return false }
        guard let amount = parsedAmount, amount > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("分类", selection: $category) {
                        ForEach(TransactionCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    TextField("消费名称", text: $titleText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("金额", text: $amountText)
                        .keyboardType(.decimalPad)

                    DatePicker("时间", selection: $createdAt, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("无法保存", isPresented: $isShowingError) {
                Button("好的") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func save() {
        let title = trimmedTitle
        guard !title.isEmpty else {
            showError("请输入消费名称")
            return
        }

        guard let amount = parsedAmount, amount > 0 else {
            showError("请输入有效金额")
            return
        }

        transaction.title = title
        transaction.amount = amount
        transaction.createdAt = createdAt
        transaction.category = category

        do {
            try modelContext.save()
            dismiss()
        } catch {
            showError("保存失败，请重试")
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}

