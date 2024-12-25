//
//  DashboardView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/24/24.
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(filter: #Predicate<BudgetCategory> { $0.parent == nil }) var budgets: [BudgetCategory]
    @Query(sort: \Expense.date) var expenses: [Expense]
    @Query(sort: \Revenue.date) var revenue: [Revenue]
    
    @State private var selection: Date = {
        let date = Date()
        return createDate(year: date.year, month: date.month)
    }()
    @State private var summaryView: SummaryViewType = .month
    
    var body: some View {
        let current = Date()
        let startYear = (expenses.map({ $0.date }) + revenue.map({ $0.date })).min()?.year ?? current.year
        let numYears = current.year - startYear + 1
        TabView(selection: $selection) {
            ForEach(0..<(12 * numYears), id: \.hashValue) { index in
                let date = Self.createDate(year: startYear + (index / 12), month: (index % 12) + 1)
                DashboardMonthView(expenses: expenses, revenue: revenue, year: date.year, month: date.month, summaryView: $summaryView)
                    .tag(date)
            }
        }.tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.init(uiColor: UIColor.secondarySystemBackground))
            .toolbar(content: toolbarItems)
    }
    
    @ToolbarContentBuilder
    private func toolbarItems() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Picker("Type", selection: $summaryView.animation()) {
                Text("Month").tag(SummaryViewType.month)
                Text("YTD").tag(SummaryViewType.ytd)
            }.pickerStyle(.segmented)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Menu("Edit Budget") {
                    ForEach(budgets, id: \.hashValue) { budget in
                        Button(budget.name) {
                            navigationStore.push(ExpenseViewType.editCategory(category: budget))
                        }
                    }
                }
            } label: {
                Label("Settings", systemImage: "gear").labelStyle(.iconOnly)
            }
        }
    }
    
    static func createDate(year: Int, month: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components)!
    }
    
    enum SummaryViewType {
        case month
        case ytd
    }
}

struct DashboardMonthView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(filter: #Predicate<BudgetCategory> { $0.parent == nil }) var budgets: [BudgetCategory]
    @Query var assets: [Asset]
    
    let expenses: [Expense]
    let revenue: [Revenue]
    let year: Int
    let month: Int
    
    @Binding private var summaryView: DashboardView.SummaryViewType
    @State private var selectedData: CategoryData? = nil
    
    init(expenses: [Expense], revenue: [Revenue], year: Int, month: Int, summaryView: Binding<DashboardView.SummaryViewType>) {
        switch summaryView.wrappedValue {
        case .month:
            self.expenses = expenses.filter({ $0.date.year == year && $0.date.month == month })
            self.revenue = revenue.filter({ $0.date.year == year && $0.date.month == month })
        case .ytd:
            self.expenses = expenses.filter({ $0.date.year == year && $0.date.month <= month })
            self.revenue = revenue.filter({ $0.date.year == year && $0.date.month <= month })
        }
        self.year = year
        self.month = month
        self._summaryView = summaryView
    }
    
    var body: some View {
        let expenseData: [CategoryData] = {
            return expenses.map({ $0.toCategoryData() }) + assets.map(toCategoryData).flatMap({ $0 })
        }()
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("\(month.monthText()) \(year.yearText())")
                        .font(.title)
                        .bold()
                    Spacer()
                }
                totalSummary(expenses: expenseData.total, income: revenue.total)
                expenseCategoryView(expenseData)
            }.padding([.leading, .trailing], 20)
        }
    }
    
    private func toCategoryData(_ asset: Asset) -> [CategoryData] {
        if let loan = asset.loan {
            return asset.toCategoryData(loan.payments.filter({ isFiltered($0.date) }))
        }
        return []
    }
    
    @ViewBuilder
    private func totalSummary(expenses: Price, income: Price) -> some View {
        let expenseHeader: String = {
            switch summaryView {
            case .month:
                "Expenses"
            case .ytd:
                "Expenses YTD"
            }
        }()
        let revenueHeader: String = {
            switch summaryView {
            case .month:
                "Income"
            case .ytd:
                "Income YTD"
            }
        }()
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                stackedText(header: expenseHeader, main: expenses.toString())
                Divider()
                stackedText(header: revenueHeader, main: income.toString())
                Spacer()
            }
            diffSummary(diff: income - expenses)
        }.padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func diffSummary(diff: Price) -> some View {
        let cents = diff.toCents()
        if cents != 0 {
            let diffText: String = cents > 0 ? "Surplus" : "Deficit"
            stackedText(header: diffText, main: diff.abs().toString())
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
    
    @ViewBuilder
    private func expenseCategoryView(_ data: [CategoryData]) -> some View {
        if let categories = budgets.first?.children {
            let budget: Price? = {
                switch summaryView {
                case .month:
                    return categories.total
                case .ytd:
                    if let total = categories.total {
                        return total * Double(month)
                    }
                    return nil
                }
            }()
            let selectedBudget: Price? = {
                let categories = categories.filter({ selectedData == nil || $0.name == selectedData!.category })
                switch summaryView {
                case .month:
                    return categories.total
                case .ytd:
                    if let total = categories.total {
                        return total * Double(month)
                    }
                    return nil
                }
            }()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Expenses")
                        .font(.title3)
                        .bold()
                    Spacer()
                    if !data.isEmpty {
                        Menu {
                            ForEach(categories.sorted(by: { $0.name < $1.name }), id: \.hashValue) { category in
                                Button("View \(category.name)") {
                                    viewExpenseCategory(category)
                                }.disabled(!data.contains(where: { category.contains($0.category) }))
                            }
                            Divider()
                            Button("View All", action: viewExpenseList)
                        } label: {
                            Label("View Expenses", systemImage: "list.bullet").labelStyle(.iconOnly)
                        }
                    }
                }
                VStack(alignment: .leading) {
                    if budget != nil {
                        HStack(alignment: .top, spacing: 16) {
                            stackedText(header: "\(selectedData?.category ?? "Total") Budget", main: selectedBudget?.toString(maxDigits: 0) ?? "N/A")
                            if let selectedBudget {
                                let selectedCategory = selectedData != nil ? categories.find(selectedData!.category) : nil
                                let remaining = selectedBudget - data.filter({ selectedCategory == nil || selectedCategory!.contains($0.category) }).total
                                Divider()
                                stackedText(header: remaining.toCents() >= 0 ? "Remaining" : "Over", main: remaining.abs().toString(maxDigits: 0))
                                    .foregroundStyle(remaining.toCents() >= 0 ? Color.primary : Color.red)
                            }
                        }
                    }
                    if !data.isEmpty {
                        CategoryPieChart(categories: categories, data: data, selectedData: $selectedData)
                            .frame(height: 200)
                    } else {
                        HStack {
                            Spacer()
                            Text("No Expenses")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }.padding()
                    }
                }.padding()
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private func isFiltered(_ date: Date) -> Bool {
        switch summaryView {
        case .month:
            return date.year == year && date.month == month
        case .ytd:
            return date.year == year && date.month <= month
        }
    }
    
    private func viewExpenseCategory(_ category: BudgetCategory) {
        let date = Date.from(year: year, month: month, day: 1)
        switch summaryView {
        case .month:
            navigationStore.push(ExpenseViewType.dashboardCategory(category: category, dateInterval: .monthOf(date)))
        case .ytd:
            navigationStore.push(ExpenseViewType.dashboardCategory(category: category, dateInterval: .yearToDate(date)))
        }
    }
    
    private func viewExpenseList() {
        switch summaryView {
        case .month:
            navigationStore.push(ExpenseViewType.byMonth(year: year, month: month))
        case .ytd:
            // TODO
            navigationStore.push(ExpenseViewType.byDate)
        }
    }
    
    private func viewRevenueList() {
        // TODO
        navigationStore.push(RevenueViewType.byDate)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        DashboardView()
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
