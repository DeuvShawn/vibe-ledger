import SwiftUI

struct DateRangeFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var filterStart: Date?
    @Binding private var filterEnd: Date?
    @Binding private var selectedCategories: Set<TransactionCategory>

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var categories: Set<TransactionCategory>

    init(
        filterStart: Binding<Date?>,
        filterEnd: Binding<Date?>,
        selectedCategories: Binding<Set<TransactionCategory>>
    ) {
        _filterStart = filterStart
        _filterEnd = filterEnd
        _selectedCategories = selectedCategories

        let now = Date()
        let initialStart = filterStart.wrappedValue ?? now
        let initialEnd = filterEnd.wrappedValue ?? now

        _startDate = State(initialValue: initialStart)
        _endDate = State(initialValue: initialEnd)
        _categories = State(initialValue: selectedCategories.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("时间") {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                }

                Section("分类") {
                    HStack(spacing: 8) {
                        ForEach(TransactionCategory.allCases) { category in
                            CategoryFilterButton(
                                title: category.rawValue,
                                isSelected: categories.contains(category)
                            ) {
                                toggle(category)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                Section {
                    Button("清除筛选") {
                        filterStart = nil
                        filterEnd = nil
                        selectedCategories = []
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("应用") {
                        apply()
                    }
                }
            }
            .onChange(of: startDate) {
                if endDate < startDate {
                    endDate = startDate
                }
            }
            .onChange(of: endDate) {
                if endDate < startDate {
                    endDate = startDate
                }
            }
        }
    }

    private func apply() {
        let start = DateRange.startOfDay(for: startDate)
        let end = DateRange.endOfDay(for: endDate)

        filterStart = start
        filterEnd = end
        selectedCategories = categories

        dismiss()
    }

    private func toggle(_ category: TransactionCategory) {
        if categories.contains(category) {
            categories.remove(category)
        } else {
            categories.insert(category)
        }
    }
}

private struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

