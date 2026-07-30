# VibeLedger 开发模板（可复用脚手架）

> 适用场景：任何「列表 + 增删改 + 统计 + 筛选 + 搜索 + 导入导出」类的本地数据 App（记账、库存、读书、习惯追踪、待办统计等）。
> 技术栈：**SwiftUI + SwiftData**，iOS 17+，XcodeGen 生成工程，**零第三方依赖**。

---

## 1. 何时用这个模板

| 特征 | 命中即用 |
|------|----------|
| 数据本地持久化（无需联网） | ✅ |
| 首页是「可滚动的条目列表」 | ✅ |
| 需要新增 / 编辑 / 删除 | ✅ |
| 需要一个或多个「汇总统计」页 | ✅ |
| 需要按时间 / 分类等维度筛选 | ✅ |
| 需要搜索 | ✅ |
| 需要导出 / 备份数据 | ✅ |

只要命中 3 条以上，就直接套本模板。

---

## 2. 目录结构（强制约定）

```
ProjectName/
├── project.yml                      # XcodeGen 配置（生成 .xcodeproj，不入库 .xcodeproj）
├── .gitignore                       # 忽略 .DS_Store / xcuserdata / 生成的 .xcodeproj
├── ProjectName/
│   ├── ProjectNameApp.swift         # @main 入口 + .modelContainer
│   ├── Info.plist
│   ├── Assets.xcassets/
│   ├── Models/
│   │   ├── <Entity>.swift           # @Model 持久化实体
│   │   ├── <Entity>Category.swift   # 分类枚举（rawValue = 中文显示名）
│   │   └── <Entity>Transfer.swift   # Codable 传输/DTO 模型（与持久化解耦）
│   ├── Features/
│   │   ├── Main/MainTabView.swift   # Tab 容器，持有共享状态
│   │   ├── Ledger/                  # 主页 + 新增/编辑/筛选 sheet
│   │   │   ├── LedgerListView.swift
│   │   │   ├── Add<Entity>View.swift
│   │   │   ├── Edit<Entity>View.swift
│   │   │   └── <Entity>FilterView.swift
│   │   ├── Stats/StatisticsView.swift
│   │   └── Search/SearchView.swift
│   └── Utils/
│       ├── DateRange.swift          # 日期区间计算（纯静态函数）
│       ├── MoneyFormat.swift        # 金额格式化 + 解析（集中处理货币）
│       └── <Entity>TransferDocument.swift  # FileDocument 导入导出封装
└── ProjectNameTests/
    └── ProjectNameTests.swift
```

**分组原则**：一个业务功能一个文件夹（`Features/<Feature>/`），模型归 `Models/`，跨功能纯函数归 `Utils/`。

---

## 3. 工程配置（project.yml）

```yaml
name: ProjectName
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "17.0"          # SwiftData 要求 17+
settings:
  base:
    SWIFT_VERSION: "5.0"
targets:
  ProjectName:
    type: application
    platform: iOS
    sources:
      - path: ProjectName
    resources:
      - path: ProjectName/Assets.xcassets
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.projectname
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0
    info:
      path: ProjectName/Info.plist
      properties:
        CFBundleDisplayName: ProjectName
        UILaunchScreen: {}
  ProjectNameTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: ProjectNameTests
    dependencies:
      - target: ProjectName
```

> 用 `xcodegen generate` 生成 `.xcodeproj`，不要手写 pbxproj。

---

## 4. 核心架构模式（六条铁律）

### 4.1 应用入口：@main + modelContainer

```swift
@main
struct ProjectNameApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: Transaction.self)   // 只声明根 @Model
    }
}
```

### 4.2 持久化实体：@Model + UUID 主键

```swift
import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID       // 唯一主键，导入去重用
    var title: String
    var amount: Decimal                     // 金额用 Decimal，不用 Double
    var createdAt: Date
    var category: TransactionCategory

    init(id: UUID = UUID(), title: String, amount: Decimal, createdAt: Date, category: TransactionCategory) {
        self.id = id; self.title = title; self.amount = amount
        self.createdAt = createdAt; self.category = category
    }
}
```

### 4.3 分类枚举：rawValue 即显示名

```swift
enum TransactionCategory: String, CaseIterable, Codable, Identifiable {
    case food = "餐饮"
    case transport = "交通"
    // ...
    var id: String { rawValue }            // id 用 rawValue，遍历/绑定直接用
}
```

> 关键约定：`rawValue` 同时充当「存储值」和「界面显示文字」，避免再维护一套映射。筛选多选用 `Set<Category>`。

### 4.4 DTO 与持久化解耦（导入导出必做）

SwiftData 的 `@Model` 不擅长直接 `Codable`，**永远**用一个 `Codable` 的 DTO 做序列化：

```swift
struct TransactionRecord: Codable {
    let id: UUID; let title: String; let amount: Decimal
    let createdAt: Date; let category: TransactionCategory

    init(transaction: Transaction) { /* 实体 -> DTO */ }
    var transaction: Transaction { /* DTO -> 实体 */ }
}
```

### 4.5 Tab 容器持有共享状态，@Binding 下发

```swift
struct MainTabView: View {
    @State private var filterStart: Date?
    @State private var filterEnd: Date?
    @State private var selectedCategories: Set<TransactionCategory> = []

    var body: some View {
        TabView {
            LedgerListView(filterStart: $filterStart, filterEnd: $filterEnd,
                           selectedCategories: $selectedCategories)
                .tabItem { Label("主页", systemImage: "house.fill") }
            StatisticsView(filterStart: $filterStart, filterEnd: $filterEnd,
                           selectedCategories: $selectedCategories)
                .tabItem { Label("统计", systemImage: "chart.bar.fill") }
        }
    }
}
```

> 筛选状态放在 Tab 容器层，切换 Tab 不丢失、两页天然同步。

### 4.6 列表页统一骨架

```swift
struct LedgerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.createdAt, order: .reverse) private var transactions: [Transaction]

    @State private var isPresentingAdd = false
    @State private var isPresentingFilter = false
    @State private var selectedForEdit: Transaction?

    @Binding private var filterStart: Date?
    @Binding private var filterEnd: Date?
    @Binding private var selectedCategories: Set<TransactionCategory>

    init(filterStart: Binding<Date?>, filterEnd: Binding<Date?>, selectedCategories: Binding<Set<TransactionCategory>>) {
        _filterStart = filterStart; _filterEnd = filterEnd; _selectedCategories = selectedCategories
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { t in
            DateRange.contains(t.createdAt, start: filterStart, end: filterEnd)
                && (selectedCategories.isEmpty || selectedCategories.contains(t.category))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filteredTransactions) { t in
                        Button { selectedForEdit = t } label: { Row(transaction: t) }
                    }
                    .onDelete(perform: delete)
                } header: { SummaryHeader(...) }
            }
            .navigationTitle("小记账")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { isPresentingFilter = true } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                    Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $isPresentingAdd) { AddTransactionView() }
            .sheet(item: $selectedForEdit) { t in EditTransactionView(transaction: t) }   // 用 item 绑定可识别对象
            .sheet(isPresented: $isPresentingFilter) {
                DateRangeFilterView(filterStart: $filterStart, filterEnd: $filterEnd, selectedCategories: $selectedCategories)
            }
        }
    }

    private func delete(_ indexSet: IndexSet) { /* modelContext.delete + save */ }
}
```

**要点**：
- 数据来自 `@Query`（自动监听 SwiftData 变化刷新）。
- 过滤逻辑抽成 `filteredTransactions` 计算属性，列表/统计/搜索共用同一套过滤语义。
- 增/改用 `.sheet`，改用 `.sheet(item:)` 绑定被编辑对象。
- 行视图、表头视图写成 `private struct`，文件私有，避免污染全局命名空间。

---

## 5. 表单（新增 / 编辑）标准写法

| 差异 | 新增 AddView | 编辑 EditView |
|------|--------------|---------------|
| 状态来源 | `@State` 空值 | `init` 里 `_x = State(initialValue: entity.x)` 预填 |
| 保存 | `modelContext.insert(new)` | 直接改 `entity.x = ...` |
| 校验 | `canSave` 计算属性，禁用保存按钮 | 同左 |

```swift
private var canSave: Bool {
    !trimmedTitle.isEmpty && (parsedAmount ?? 0) > 0
}

private func save() {
    guard let amount = parsedAmount, amount > 0 else { showError("请输入有效金额"); return }
    let item = Transaction(title: trimmedTitle, amount: amount, createdAt: .now, category: category)
    modelContext.insert(item)
    do { try modelContext.save(); dismiss() }
    catch { showError("保存失败，请重试") }
}
```

> 金额一律经 `MoneyFormat.parseDecimal` 解析（兼容中文逗号/句号），显示一律经 `MoneyFormat.currencyString(for:)`。

---

## 6. 筛选 Sheet：「暂存 + 应用」模式

```swift
struct DateRangeFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var filterStart: Date?
    @Binding private var filterEnd: Date?
    @Binding private var selectedCategories: Set<TransactionCategory>

    @State private var startDate: Date        // 本地暂存
    @State private var endDate: Date
    @State private var categories: Set<TransactionCategory>

    init(...) {
        _filterStart = filterStart; _filterEnd = filterEnd; _selectedCategories = selectedCategories
        _startDate = State(initialValue: filterStart.wrappedValue ?? Date())
        _endDate = State(initialValue: filterEnd.wrappedValue ?? Date())
        _categories = State(initialValue: selectedCategories.wrappedValue)
    }

    private func apply() {
        filterStart = DateRange.startOfDay(for: startDate)
        filterEnd = DateRange.endOfDay(for: endDate)
        selectedCategories = categories
        dismiss()
    }
}
```

**规则**：
- 编辑只改本地 `@State`，点「应用」才写回 `@Binding`，「取消」直接 `dismiss()` 不提交。
- `Section("时间")` / `Section("分类")` 标题统一格式。
- 多选分类按钮：`HStack` + 胶囊 `Button`，选中态 `Color.accentColor` 填充、白字；再点取消。
- `onChange` 守卫结束日期不早于开始日期。
- 「清除筛选」把时间和分类一起重置为 nil/空并 dismiss。

---

## 7. 统计页聚合写法

```swift
private var totalsByCategory: [(TransactionCategory, Decimal)] {
    let grouped = Dictionary(grouping: filteredTransactions, by: { $0.category })
    return TransactionCategory.allCases.map { c in
        (c, grouped[c, default: []].reduce(.zero) { $0 + $1.amount })
    }
}
private var topFive: [Transaction] {
    filteredTransactions.sorted { $0.amount > $1.amount }.prefix(5).map { $0 }
}
```

> 统计页与列表页共用同一个 `filteredTransactions`，保证口径一致。分类展示用 `displayedCategories`：选中为空显示全部，否则只显示选中项。

---

## 8. 搜索页

```swift
@Query(sort: \Transaction.createdAt, order: .reverse) private var transactions: [Transaction]
@State private var searchText = ""

private var matched: [Transaction] {
    let kw = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !kw.isEmpty else { return transactions }
    return transactions.filter { t in
        t.title.localizedCaseInsensitiveContains(kw)
        || t.category.rawValue.localizedCaseInsensitiveContains(kw)
        || MoneyFormat.currencyString(for: t.amount).contains(kw)
    }
}
// body 用 .searchable(text: $searchText, prompt: "搜索名称、分类或金额")
```

> 多字段检索时做归一化（去空格、去货币符号）以兼容「32.5」「¥32.5」等输入。

---

## 9. 工具类（跨功能复用，必须集中）

**DateRange.swift** — 纯静态日期工具：
- `startOfDay(for:)` / `endOfDay(for:)`
- `contains(_:start:end:)` —— 过滤核心，返回是否在区间内
- `label(start:end:)` —— 区间文案（无区间显示「全部」）

**MoneyFormat.swift** — 金额统一处理：
- `parseDecimal(_:)` —— 解析输入，兼容中文标点，用 `Locale(identifier: "en_US_POSIX")` 避免本地化污染
- `currencyString(for:currencyCode:)` —— 显示，`currencyCode` 默认 `"CNY"`（`zh_CN`/`¥`）；传 `"USD"` 则 `en_US`/`$`；固定两位小数。货币选择用 `@AppStorage("currencyCode")` 持久化，主页 `...` 菜单内可切换，各页读取后全局生效

**<Entity>TransferDocument.swift** — `FileDocument` 封装导入导出：
```swift
struct LedgerTransferDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let transfer: LedgerTransfer
    init(configuration: ReadConfiguration) throws { /* 读 */ }
    init(data: Data) throws { /* 供 fileImporter 用 */ }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601   // 日期统一 ISO8601
        return .init(regularFileWithContents: try encoder.encode(transfer))
    }
}
```
> 导入时在 `fileImporter` 回调里 `url.startAccessingSecurityScopedResource()`，用完 `defer` 释放。

---

## 10. 命名与样式约定

| 项 | 约定 |
|----|------|
| 视图 | `<Feature>View`，子视图 `private struct <Name>Row / <Name>Header` |
| 计算展示数据 | `camelCase`：`filteredTransactions`、`totalsByCategory` |
| 金额显示 | 一律 `MoneyFormat.currencyString(for:)` + `.monospacedDigit()` |
| 日期显示 | `Date.FormatStyle` 或 `DateRange.label` |
| 选中态色 | `Color.accentColor` |
| 次要文字 | `.foregroundStyle(.secondary)` |
| 标签/芯片 | `Capsule()` + `.stroke` 或填充 |
| 数据列表 | `.listStyle(.plain)`；分组统计 `.listStyle(.insetGrouped)` |
| 错误提示 | `.alert(...)` 统一 `showAlert(_:)` 助手 |

---

## 11. 新功能 Checklist

- [ ] 定义 `@Model` 实体（含 `@Attribute(.unique) id`）
- [ ] 定义分类枚举（如需）
- [ ] 定义 DTO + 双向转换（如需导入导出）
- [ ] 在 `App.modelContainer(for:)` 注册实体
- [ ] 列表页：`@Query` + 过滤计算属性 + CRUD
- [ ] 新增 / 编辑 sheet（复用 §5 骨架）
- [ ] 筛选 sheet（如需，复用「暂存+应用」）
- [ ] 统计页聚合（如需）
- [ ] 搜索页（如需）
- [ ] 注册到 `MainTabView` 的 `TabView`
- [ ] 在 `Utils/` 抽离可复用纯函数

---

## 12. 常见坑（务必规避）

1. **不要**让 `@Model` 直接遵守 `Codable`，用 DTO 中转。
2. 金额用 `Decimal`，**不要**用 `Double`（精度丢失）。
3. 所有写操作（`insert`/`delete`/改属性）后都要 `try modelContext.save()` 并 `catch`。
4. `@Binding` / 从 `init` 初始化的 `@State` 必须用 `_x =` 在 `init` 中赋值。
5. `Date` 序列化统一用 `.iso8601`，编码与解码两端一致。
6. `fileImporter` 拿到 `URL` 后须 `startAccessingSecurityScopedResource()`，否则读不到内容。
7. 部署目标 iOS 17+（SwiftData 硬要求）。
8. `.xcodeproj` 由 XcodeGen 生成，不入库；`.gitignore` 忽略 `xcuserdata/`。
