import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var titleText = ""
    @State private var amountText = ""
    @State private var category: TransactionCategory = .food

    @State private var isShowingError = false
    @State private var errorMessage = ""

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
                }
            }
            .navigationTitle("新增")
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

        let transaction = Transaction(title: title, amount: amount, createdAt: .now, category: category)
        modelContext.insert(transaction)

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
