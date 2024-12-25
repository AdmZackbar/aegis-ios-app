//
//  DashboardCategoryView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/25/24.
//

import SwiftData
import SwiftUI

struct DashboardCategoryView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var allExpenses: [Expense]
    @Query var assets: [Asset]
    
    let category: BudgetCategory
    let dateInterval: DateInterval
    
    @State private var selectedData: CategoryData? = nil
    @State private var selectedDate: Date? = nil
    
    private var dateIntervalType: Calendar.Component? {
        if dateInterval.start.year == dateInterval.end.year {
            if dateInterval.start.month == dateInterval.end.month {
                return .month
            }
            return .year
        }
        return nil
    }
    private var title: String {
        switch dateIntervalType {
        case .month:
            return "\(category.name) \(dateInterval.start.month.shortMonthText()) \(dateInterval.start.year.yearText())"
        case .year:
            if dateInterval.start.month == 1 && dateInterval.end.month == 12 {
                return "\(category.name) \(dateInterval.start.year.yearText())"
            }
            return "\(category.name) \(dateInterval.start.month.shortMonthText())-\(dateInterval.end.month.shortMonthText()) \(dateInterval.start.year.yearText())"
        default:
            return "\(category.name) \(dateInterval.start.year.yearText())-\(dateInterval.end.year.yearText())"
        }
    }
    
    init(category: BudgetCategory, dateInterval: DateInterval) {
        self.category = category
        self.dateInterval = dateInterval
    }
    
    var body: some View {
        let expenses = allExpenses.filter({ category.contains($0.category) && dateInterval.contains($0.date) })
        var assetData: [CategoryData] = []
        let payments: [Asset.Loan.Payment] = {
            var payments: [Asset.Loan.Payment] = []
            for asset in assets.filter({ category.contains($0.metaData.category) && $0.loan != nil }) {
                let assetPayments = asset.loan!.payments.filter({ dateInterval.contains($0.date) })
                payments += assetPayments
                assetData += asset.toCategoryData(assetPayments)
            }
            return payments
        }()
        let data = expenses.map(Expense.toCategoryData) + assetData
        let financeData = expenses.map(Expense.toFinanceData) + payments.map({ .init(date: $0.date, amount: ($0.amount - $0.principal).toUsd(), category: .expense) })
        Form {
            dateView(financeData: financeData)
            if let subcategories = category.children, !subcategories.isEmpty {
                subcategoryView(data: data, subcategories: subcategories)
            } else if let budget = category.monthlyBudget {
                Section("Budget") {
                    budgetView(name: "Total", data: data, budget: budget)
                }.headerProminence(.increased)
            }
            if !expenses.isEmpty {
                Section("Entries") {
                    ExpenseListView(expenses: expenses)
                }.headerProminence(.increased)
            }
            if !payments.isEmpty {
                Section("Asset Payments") {
                    ForEach(payments, id: \.hashValue) { payment in
                        AssetPaymentEntryView(payment: payment)
                    }
                }.headerProminence(.increased)
            }
        }.navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigationStore.push(ExpenseViewType.editCategory(category: category))
                    } label: {
                        Label("Edit Category", systemImage: "pencil.circle").labelStyle(.iconOnly)
                    }
                }
            }
    }
    
    @ViewBuilder
    private func subcategoryView(data: [CategoryData], subcategories: [BudgetCategory]) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 0) {
                budgetView(data: data, subcategories: subcategories)
                CategoryPieChart(categories: subcategories, data: data, selectedData: $selectedData)
                    .frame(height: 180)
            }
        } header: {
            HStack {
                Text("Subcategories")
                if !data.isEmpty {
                    Spacer()
                    Menu {
                        ForEach(subcategories.sorted(by: { $0.name < $1.name }), id: \.hashValue) { subcategory in
                            Button(subcategory.name) {
                                navigationStore.push(ExpenseViewType.dashboardCategory(category: subcategory, dateInterval: dateInterval))
                            }.disabled(!data.contains(where: { subcategory.contains($0.category) }))
                        }
                    } label: {
                        Label("View Expenses", systemImage: "list.bullet")
                            .labelStyle(.iconOnly)
                    }.controlSize(.large)
                }
            }
        }.headerProminence(.increased)
    }
    
    @ViewBuilder
    private func budgetView(data: [CategoryData], subcategories: [BudgetCategory]) -> some View {
        if category.monthlyBudget != nil {
            let numMonths = Double(dateInterval.end.month - dateInterval.start.month + 1)
            let selectedBudget: Price? = {
                let childBudgets = subcategories.filter({ selectedData == nil || $0.name == selectedData!.category }).total
                if let childBudgets {
                    if selectedData == nil, let base = category.amount {
                        return (childBudgets + base) * numMonths
                    }
                    return childBudgets * numMonths
                }
                if selectedData == nil, let base = category.amount {
                    return base * numMonths
                }
                return nil
            }()
            let selectedCategory = selectedData != nil ? subcategories.find(selectedData!.category) : nil
            budgetView(name: selectedData?.category ?? "Total",
                       data: data.filter({ selectedCategory == nil || selectedCategory!.contains($0.category) }),
                       budget: selectedBudget)
        }
    }
    
    @ViewBuilder
    private func budgetView(name: String, data: [CategoryData], budget: Price?) -> some View {
        HStack(alignment: .top, spacing: 24) {
            stackedText(header: "\(name) Budget", main: budget?.toString(maxDigits: 0) ?? "N/A")
            if let budget {
                let remaining = budget - data.total
                stackedText(header: remaining.toCents() >= 0 ? "Remaining" : "Over", main: remaining.abs().toString(maxDigits: 0))
                    .foregroundStyle(remaining.toCents() >= 0 ? Color.primary : Color.red)
            }
        }
    }
    
    @ViewBuilder
    private func dateView(financeData: [FinanceData]) -> some View {
        let header: String = {
            if let selectedDate {
                let total = financeData.filter({ isFiltered(date: selectedDate, item: $0) }).total
                let header: String = {
                    switch dateIntervalType {
                    case .month:
                        "\(selectedDate.month.shortMonthText()) \(selectedDate.day.formatted())"
                    case .year:
                        selectedDate.month.monthText()
                    default:
                        selectedDate.year.yearText()
                    }
                }()
                return "\(header): \(total.toString())"
            }
            return "Total: \(financeData.total.toString())"
        }()
        Section(header) {
            dateChart(financeData: financeData)
                .frame(height: 120)
        }.headerProminence(.increased)
    }
    
    private func isFiltered(date: Date, item: FinanceData) -> Bool {
        switch dateIntervalType {
        case .month:
            return item.date.year == date.year && item.date.month == date.month && item.date.day == date.day
        case .year:
            return item.date.year == date.year && item.date.month == date.month
        default:
            return item.date.year == date.year
        }
    }
    
    @ViewBuilder
    private func dateChart(financeData: [FinanceData]) -> some View {
        switch dateIntervalType {
        case .month:
            FinanceMonthChart(data: financeData,
                              year: dateInterval.start.year,
                              month: dateInterval.start.month,
                              selection: $selectedDate)
        case .year:
            FinanceYearChart(data: financeData,
                             year: dateInterval.start.year,
                             selection: $selectedDate)
        default:
            FinanceMultiYearChart(data: financeData, selection: $selectedDate)
        }
    }
    
    @ViewBuilder
    private func stackedText(header: String, main: String) -> some View {
        VStack(alignment: .leading) {
            Text(header)
                .font(.subheadline)
                .opacity(0.6)
            Text(main)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    @Previewable @Environment(\.modelContext) var modelContext
    var query = FetchDescriptor<BudgetCategory>(predicate: #Predicate<BudgetCategory> { $0.parent == nil })
    let budgets = try! modelContext.fetch(query)
    NavigationStack(path: $navigationStore.path) {
        DashboardCategoryView(category: budgets.first!, dateInterval: .monthOf(.now))
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
