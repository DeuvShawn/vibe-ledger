import SwiftUI
import SwiftData

struct LedgerListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.createdAt, order: .reverse)
    private var transactions: [Transaction]

    @State private var isPresentingAdd = false
    @State private var isPresentingFilter = false
    @State private var selectedTransactionForEdit: Transaction?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument = LedgerTransferDocument(transfer: .init(transactions: []))
    @State private var exportFileName = "ledger-export.json"
    @State private var alertMessage: String?
    @State private var isShowingAlert = false
    @State private var isShowingDeleteAllConfirmation = false

    @AppStorage("currencyCode") private var currencyCode = "CNY"

    @Binding private var filterStart: Date?
    @Binding private var filterEnd: Date?
    @Binding private var selectedCategories: Set<TransactionCategory>

    init(
        filterStart: Binding<Date?>,
        filterEnd: Binding<Date?>,
        selectedCategories: Binding<Set<TransactionCategory>>
    ) {
        _filterStart = filterStart
        _filterEnd = filterEnd
        _selectedCategories = selectedCategories
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            DateRange.contains(transaction.createdAt, start: filterStart, end: filterEnd)
                && (selectedCategories.isEmpty || selectedCategories.contains(transaction.category))
        }
    }

    private var totalAmount: Decimal {
        filteredTransactions.reduce(.zero) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredTransactions) { transaction in
                        Button {
                            selectedTransactionForEdit = transaction
                        } label: {
                            TransactionRow(transaction: transaction)
                        }
                    }
                    .onDelete(perform: delete)
                } header: {
                    SummaryHeader(
                        rangeLabel: DateRange.label(start: filterStart, end: filterEnd),
                        count: filteredTransactions.count,
                        total: MoneyFormat.currencyString(for: totalAmount, currencyCode: currencyCode)
                    )
                }
            }
            .listStyle(.plain)
            .navigationTitle("小记账")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isPresentingFilter = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }

                    Menu {
                        Button {
                            prepareExport()
                        } label: {
                            Label("导出账本", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            isImporting = true
                        } label: {
                            Label("导入账本", systemImage: "square.and.arrow.down")
                        }

                        Button {
                            currencyCode = (currencyCode == "CNY" ? "USD" : "CNY")
                        } label: {
                            Label("货币符号：\(currencyCode == "CNY" ? "¥" : "$")", systemImage: "dollarsign.circle")
                        }

                        Divider()

                        Button(role: .destructive) {
                            isShowingDeleteAllConfirmation = true
                        } label: {
                            Label("删除所有数据", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddTransactionView()
            }
            .sheet(isPresented: $isPresentingFilter) {
                DateRangeFilterView(
                    filterStart: $filterStart,
                    filterEnd: $filterEnd,
                    selectedCategories: $selectedCategories
                )
            }
            .sheet(item: $selectedTransactionForEdit) { transaction in
                EditTransactionView(transaction: transaction)
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: exportFileName
            ) { result in
                if case .failure = result {
                    showAlert("导出失败，请重试")
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert("提示", isPresented: $isShowingAlert, actions: {
                Button("好的") {
                    alertMessage = nil
                }
            }, message: {
                Text(alertMessage ?? "")
            })
            .alert("删除所有数据？", isPresented: $isShowingDeleteAllConfirmation, actions: {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    deleteAllTransactions()
                }
            }, message: {
                Text("此操作会清空当前账本中的全部数据，且无法撤销。")
            })
        }
    }

    private func delete(_ indexSet: IndexSet) {
        let deleting = indexSet.compactMap { index in
            filteredTransactions.indices.contains(index) ? filteredTransactions[index] : nil
        }
        for transaction in deleting {
            modelContext.delete(transaction)
        }
        do {
            try modelContext.save()
        } catch {
            showAlert("删除失败，请重试")
        }
    }

    private func prepareExport() {
        let records = transactions.map(TransactionRecord.init(transaction:))
        exportDocument = LedgerTransferDocument(transfer: LedgerTransfer(transactions: records))

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        exportFileName = "ledger-\(formatter.string(from: .now)).json"
        isExporting = true
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let document = try LedgerTransferDocument(data: data)
            let importResult = try importTransactions(document.transfer.transactions)
            showAlert("导入 \(importResult.importedCount) 条，跳过 \(importResult.skippedCount) 条")
        } catch {
            showAlert("导入失败，请确认文件格式正确")
        }
    }

    private func importTransactions(_ records: [TransactionRecord]) throws -> ImportResult {
        let existingIDs = Set(transactions.map(\.id))
        var seenIDs = existingIDs
        var importedCount = 0
        var skippedCount = 0

        for record in records {
            guard !seenIDs.contains(record.id) else {
                skippedCount += 1
                continue
            }

            let transaction = record.transaction
            modelContext.insert(transaction)
            seenIDs.insert(record.id)
            importedCount += 1
        }

        try modelContext.save()
        return ImportResult(importedCount: importedCount, skippedCount: skippedCount)
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        isShowingAlert = true
    }

    private func deleteAllTransactions() {
        do {
            for transaction in transactions {
                modelContext.delete(transaction)
            }
            try modelContext.save()
            showAlert("已清空所有数据")
        } catch {
            showAlert("删除失败，请重试")
        }
    }
}

private struct ImportResult {
    let importedCount: Int
    let skippedCount: Int
}

private struct TransactionRow: View {
    let transaction: Transaction

    @AppStorage("currencyCode") private var currencyCode = "CNY"

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
                    .font(.body)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(MoneyFormat.currencyString(for: transaction.amount, currencyCode: currencyCode))
                    .font(.body.monospacedDigit())
            }

            Text(transaction.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct SummaryHeader: View {
    let rangeLabel: String
    let count: Int
    let total: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(rangeLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text("\(count) 笔")
                    .font(.headline)

                Spacer()

                Text(total)
                    .font(.headline.monospacedDigit())
            }
            .textCase(nil)
        }
        .padding(.vertical, 8)
    }
}
