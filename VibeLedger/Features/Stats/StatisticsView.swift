import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: \Transaction.createdAt, order: .reverse)
    private var transactions: [Transaction]

    @Binding private var filterStart: Date?
    @Binding private var filterEnd: Date?
    @Binding private var selectedCategories: Set<TransactionCategory>

    @State private var isPresentingFilter = false

    @AppStorage("currencyCode") private var currencyCode = "CNY"

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

    private var displayedCategories: [TransactionCategory] {
        if selectedCategories.isEmpty {
            return TransactionCategory.allCases
        }
        return TransactionCategory.allCases.filter { selectedCategories.contains($0) }
    }

    private var totalsByCategory: [(TransactionCategory, Decimal)] {
        let grouped = Dictionary(grouping: filteredTransactions, by: { $0.category })
        return displayedCategories.map { category in
            let total = grouped[category, default: []].reduce(.zero) { $0 + $1.amount }
            return (category, total)
        }
    }

    private var topFive: [Transaction] {
        filteredTransactions.sorted { $0.amount > $1.amount }.prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("时间范围")
                        Spacer()
                        Text(DateRange.label(start: filterStart, end: filterEnd))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("总支出")
                        Spacer()
                        Text(MoneyFormat.currencyString(for: totalAmount, currencyCode: currencyCode))
                            .font(.body.monospacedDigit())
                    }
                }

                Section("分类支出") {
                    ForEach(totalsByCategory, id: \.0) { category, total in
                        HStack {
                            Text(category.rawValue)
                            Spacer()
                            Text(MoneyFormat.currencyString(for: total, currencyCode: currencyCode))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(total == 0 ? .secondary : .primary)
                        }
                    }
                }

                Section("金额最大的 5 项") {
                    if topFive.isEmpty {
                        Text("暂无数据")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(topFive) { transaction in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(transaction.title)
                                        .lineLimit(1)
                                    Spacer(minLength: 12)
                                    Text(MoneyFormat.currencyString(for: transaction.amount, currencyCode: currencyCode))
                                        .font(.body.monospacedDigit())
                                }

                                HStack {
                                    Text(transaction.category.rawValue)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(transaction.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("统计")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingFilter = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $isPresentingFilter) {
                DateRangeFilterView(
                    filterStart: $filterStart,
                    filterEnd: $filterEnd,
                    selectedCategories: $selectedCategories
                )
            }
            .listStyle(.insetGrouped)
        }
    }
}
