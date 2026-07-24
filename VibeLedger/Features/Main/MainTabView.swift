import SwiftUI

struct MainTabView: View {
    @State private var filterStart: Date?
    @State private var filterEnd: Date?
    @State private var selectedCategories: Set<TransactionCategory> = []

    var body: some View {
        TabView {
            LedgerListView(
                filterStart: $filterStart,
                filterEnd: $filterEnd,
                selectedCategories: $selectedCategories
            )
            .tabItem {
                Label("主页", systemImage: "house.fill")
            }

            StatisticsView(
                filterStart: $filterStart,
                filterEnd: $filterEnd,
                selectedCategories: $selectedCategories
            )
            .tabItem {
                Label("统计", systemImage: "chart.bar.fill")
            }

            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
        }
    }
}

