# VibeLedger 小记账

一款极简的 iOS 记账应用，使用 SwiftUI + SwiftData 构建，专注于最核心的记账体验：快速记录、灵活筛选、清晰统计。

## 功能特性

### 📒 主页（记账列表）
- 按时间倒序展示全部记账条目（分类标签、名称、金额、时间）
- 新增 / 编辑 / 左滑删除记账条目
- 列表头部实时汇总：当前筛选范围、笔数、总金额
- 账本导出为 JSON 文件 / 从 JSON 文件导入（按 ID 去重，跳过重复条目）
- 一键清空所有数据（含二次确认）

### 📊 统计
- 时间范围与总支出概览
- 分类支出汇总（联动筛选：仅展示选中的分类，未选则展示全部）
- 金额最大的 5 项支出

### 🔍 搜索
- 按名称、分类、金额关键词搜索
- 金额搜索支持忽略货币符号（¥/￥）、千分位逗号与空格

### 🎯 筛选（主页与统计页共享）
- **时间筛选**：选择开始 / 结束日期，自动对齐到当天 00:00:00 – 23:59:59
- **分类筛选**：五个分类按钮（餐饮、交通、住宿、购物、娱乐）横向排列，点击选中、再点取消，支持多选
- 时间与分类筛选可叠加使用；「清除筛选」一键重置全部条件
- 筛选状态在主页与统计页之间实时同步

## 技术栈

| 项目 | 说明 |
|------|------|
| UI 框架 | SwiftUI |
| 数据持久化 | SwiftData（`@Model` + `@Query`） |
| 最低系统版本 | iOS 17 |
| 项目生成 | [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`project.yml`） |
| 依赖 | 无第三方依赖 |

## 项目结构

```
VibeLedger/
├── VibeLedgerApp.swift          # App 入口，注册 SwiftData ModelContainer
├── Models/
│   ├── Transaction.swift        # 记账条目模型（@Model）
│   ├── TransactionCategory.swift# 五个分类枚举
│   └── LedgerTransfer.swift     # 导入导出的传输模型
├── Features/
│   ├── Main/MainTabView.swift   # TabView 入口，持有共享筛选状态
│   ├── Ledger/                  # 主页：列表、新增、编辑、筛选页
│   │   ├── LedgerListView.swift
│   │   ├── AddTransactionView.swift
│   │   ├── EditTransactionView.swift
│   │   └── DateRangeFilterView.swift
│   ├── Stats/StatisticsView.swift   # 统计页
│   └── Search/SearchView.swift      # 搜索页
└── Utils/
    ├── DateRange.swift          # 日期区间工具
    ├── MoneyFormat.swift        # 金额格式化（¥）
    └── LedgerTransferDocument.swift # JSON 导入导出文档
```

## 架构说明

- **共享筛选状态**：`MainTabView` 持有 `filterStart` / `filterEnd` / `selectedCategories`，通过 `@Binding` 下发给主页与统计页，保证两页筛选条件一致。
- **筛选页交互模式**：`DateRangeFilterView` 使用本地 `@State` 暂存编辑中的值，点击「应用」后才写回绑定，「取消」不产生副作用。
- **过滤规则**：`时间匹配 && (未选分类 ? 全部 : 命中所选分类)`，分类空集合表示不限分类。

## 快速开始

```bash
# 克隆仓库
git clone git@github.com:DeuvShawn/vibe-ledger.git
cd vibe-ledger

# （可选）如修改了 project.yml，用 XcodeGen 重新生成工程
xcodegen generate

# 用 Xcode 打开并运行
open VibeLedger.xcodeproj
```

要求：Xcode 15+，iOS 17+ 真机或模拟器。

## 数据导入导出格式

导出文件为 JSON，结构如下：

```json
{
  "transactions": [
    {
      "id": "UUID",
      "title": "午餐",
      "amount": 32.5,
      "createdAt": "2026-07-24T12:00:00Z",
      "category": "餐饮"
    }
  ]
}
```

导入时按 `id` 去重：已存在的条目自动跳过，并提示导入/跳过数量。

## License

本项目仅供学习交流使用。
