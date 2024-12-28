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
    @Query(filter: #Predicate<BudgetCategory> { $0.name == "Main Budget" }) var budgets: [BudgetCategory]
    @Query(sort: \Expense.date) var expenses: [Expense]
    @Query(sort: \Revenue.date) var revenue: [Revenue]
    @Query var assets: [Asset]
    
    var body: some View {
        let expenses = expenses.filter({ navigationStore.dashboardConfig.contains($0.date) })
        let revenue = revenue.filter({ navigationStore.dashboardConfig.contains($0.date) })
        if let mainBudget = budgets.first {
            var assetData: [CategoryData] = []
            let payments: [Asset.Loan.Payment] = {
                var payments: [Asset.Loan.Payment] = []
                for asset in assets.filter({ mainBudget.contains($0.metaData.category) && $0.loan != nil }) {
                    let assetPayments = asset.loan!.payments.filter({ navigationStore.dashboardConfig.contains($0.date) })
                    payments += assetPayments
                    assetData += asset.toCategoryData(assetPayments)
                }
                return payments
            }()
            let categoryData = expenses.map(Expense.toCategoryData) + assetData
            let financeData = expenses.map(Expense.toFinanceData) + revenue.map(Revenue.toFinanceData) + payments.map({ .init(date: $0.date, amount: ($0.amount - $0.principal).toUsd(), category: .expense) })
            ZStack(alignment: .bottomTrailing) {
                Form {
                    BudgetCategoryView(category: mainBudget, financeData: financeData, categoryData: categoryData)
                }.gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                    .onEnded { value in
                        switch(value.translation.width, value.translation.height) {
                        case (...(-30), -30...30): next()
                        case (30..., -30...30): prev()
                        default: break
                        }
                    }
                )
                Menu {
                    Button("Add Expense...") {
                        navigationStore.push(ExpenseViewType.add())
                    }
                    Button("Add Revenue...") {
                        navigationStore.push(RevenueViewType.add())
                    }
                    Button("Add Asset...") {
                        navigationStore.push(AssetViewType.add)
                    }
                } label: {
                    Image(systemName: "plus")
                        .bold()
                        .foregroundStyle(Color.init(uiColor: UIColor.systemBackground))
                        .padding(20)
                        .background(.accent)
                        .clipShape(Circle())
                        .padding(.bottom, 8)
                        .padding(.trailing, 32)
                }
            }.navigationTitle(Self.computeTitle(category: mainBudget, dashboardConfig: navigationStore.dashboardConfig))
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.init(uiColor: UIColor.secondarySystemBackground))
                .toolbar {
                    toolbarItems(budget: mainBudget)
                }
        }
    }
    
    private func prev() {
        let date = navigationStore.dashboardConfig.date
        withAnimation {
            navigationStore.dashboardConfig.date = .from(year: date.year, month: date.month - 1, day: 1)
        }
    }
    
    private func next() {
        let date = navigationStore.dashboardConfig.date
        withAnimation {
            navigationStore.dashboardConfig.date = .from(year: date.year, month: date.month + 1, day: 1)
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarItems(budget: BudgetCategory) -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("Type", selection: $navigationStore.dashboardConfig.dateRangeType) {
                Text("Month").tag(DashboardConfig.DateRangeType.month)
                Text("YTD").tag(DashboardConfig.DateRangeType.ytd)
            }.pickerStyle(.segmented)
                .frame(width: 120)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Edit Budget") {
                    navigationStore.push(ExpenseViewType.editCategory(category: budget))
                }
                Button("View Assets") {
                    navigationStore.push(AssetViewType.list)
                }
            } label: {
                Image(systemName: "gear")
            }
        }
    }
    
    static func computeTitle(category: BudgetCategory, dashboardConfig: DashboardConfig) -> String {
        let dateStr: String = {
            let date = dashboardConfig.date
            let month = category.parent != nil ? date.month.shortMonthText() : date.month.monthText()
            switch dashboardConfig.dateRangeType {
            case .month:
                return "\(month) \(date.year.yearText())"
            case .ytd:
                if date.month > 1 {
                    return "Jan-\(date.month.shortMonthText()) \(date.year.yearText())"
                }
                return "\(month) \(date.year.yearText())"
            }
        }()
        return category.parent != nil ? "\(dateStr): \(category.name)" : dateStr
    }
}

struct BudgetCategoryView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    
    let category: BudgetCategory
    let financeData: [FinanceData]
    let categoryData: [CategoryData]
    
    @State private var selectedData: CategoryData? = nil
    @State private var selectedDate: Date? = nil
    
    var body: some View {
        Section(DashboardView.computeTitle(category: category, dashboardConfig: navigationStore.dashboardConfig)) {
            dateView()
        }.headerProminence(.increased)
        if let subcategories = category.children, !subcategories.isEmpty {
            subcategoryView(subcategories: subcategories)
        } else if let budget = category.monthlyBudget {
            Section("Budget") {
                budgetView(name: "Total", data: categoryData, budget: budget)
            }.headerProminence(.increased)
        }
    }
    
    @ViewBuilder
    private func dateView() -> some View {
        VStack(alignment: .leading) {
            dataSummary()
            dateChart()
                .frame(height: 120)
        }
    }
    
    @ViewBuilder
    private func dataSummary() -> some View {
        let header: String = {
            if let selectedDate {
                switch navigationStore.dashboardConfig.dateRangeType {
                case .month:
                    "\(selectedDate.month.shortMonthText()) \(selectedDate.day.formatted())"
                case .ytd:
                    "\(selectedDate.month.shortMonthText())"
                }
            } else {
                "Total"
            }
        }()
        let expenseTotal: Price = {
            let expenses = financeData.filter({ $0.category == .expense })
            if let selectedDate {
                switch navigationStore.dashboardConfig.dateRangeType {
                case .month:
                    return expenses.filter({ $0.date.day == selectedDate.day }).total
                case .ytd:
                    return expenses.filter({ $0.date.month == selectedDate.month }).total
                }
            }
            return expenses.total
        }()
        let income = financeData.filter({ $0.category == .income })
        let incomeTotal: Price = {
            if let selectedDate {
                switch navigationStore.dashboardConfig.dateRangeType {
                case .month:
                    return income.filter({ $0.date.day == selectedDate.day }).total
                case .ytd:
                    return income.filter({ $0.date.month == selectedDate.month }).total
                }
            }
            return income.total
        }()
        HStack(spacing: 16) {
            stackedText(header: "\(header) Spending", main: expenseTotal.toString())
            if !income.isEmpty {
                stackedText(header: "\(header) Income", main: incomeTotal.toString())
            }
        }
    }
    
    @ViewBuilder
    private func dateChart() -> some View {
        let month = navigationStore.dashboardConfig.date.month
        let year = navigationStore.dashboardConfig.date.year
        switch navigationStore.dashboardConfig.dateRangeType {
        case .month:
            FinanceMonthChart(data: financeData,
                              year: year,
                              month: month,
                              selection: $selectedDate)
        case .ytd:
            FinanceYearChart(data: financeData,
                             year: year,
                             dateRange: Date.from(year: year, month: 1, day: 1)...Date.from(year: year, month: month + 1, day: 1),
                             selection: $selectedDate)
        }
    }
    
    @ViewBuilder
    private func subcategoryView(subcategories: [BudgetCategory]) -> some View {
        Section(category.parent == nil ? "Categories" : "Subcategories") {
            VStack(alignment: .leading, spacing: 0) {
                budgetView(subcategories: subcategories)
                if categoryData.total.toCents() > 0 {
                    CategoryPieChart(categories: subcategories, data: categoryData, selectedData: $selectedData)
                        .frame(height: 180)
                } else {
                    Text("No Expenses")
                        .frame(maxWidth: .infinity)
                        .bold()
                        .padding()
                }
                ForEach(subcategories.sorted(by: { $0.name < $1.name })
                    .sorted(by: { computeActual($0) > computeActual($1) }), id: \.hashValue) { subcategory in
                    Divider()
                        .padding([.top, .bottom], 8)
                    Button {
                        navigationStore.push(ExpenseViewType.dashboardCategory(category: subcategory))
                    } label: {
                        subcategoryEntryView(subcategory)
                    }.buttonStyle(.plain)
                }
            }
        }.headerProminence(.increased)
    }
    
    private func computeActual(_ subcategory: BudgetCategory) -> Price {
        categoryData.filter({ subcategory.contains($0.category) }).total
    }
    
    @ViewBuilder
    private func budgetView(subcategories: [BudgetCategory]) -> some View {
        if category.monthlyBudget != nil {
            let numMonths = Double(computeNumMonths())
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
                       data: categoryData.filter({ selectedCategory == nil || selectedCategory!.contains($0.category) }),
                       budget: selectedBudget)
        }
    }
    
    private func computeNumMonths() -> Int {
        switch navigationStore.dashboardConfig.dateRangeType {
        case .month:
            return 1
        case .ytd:
            return navigationStore.dashboardConfig.date.month
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
    private func subcategoryEntryView(_ subcategory: BudgetCategory) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text(subcategory.name)
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Total: \(computeActual(subcategory).toString(maxDigits: 0))")
                    .font(.subheadline)
                    .opacity(0.8)
            }
            Spacer()
            if let budget = subcategory.monthlyBudget {
                VStack(alignment: .trailing) {
                    Text("Budget")
                        .font(.subheadline)
                        .opacity(0.6)
                    Text((budget * Double(computeNumMonths())).toString(maxDigits: 0))
                        .fontWeight(.bold)
                }
            }
            Image(systemName: "chevron.right")
        }.contentShape(Rectangle())
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

struct DashboardCategoryView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date) var expenses: [Expense]
    @Query var assets: [Asset]
    
    let category: BudgetCategory
    
    var body: some View {
        let expenses = expenses.filter({ isFiltered($0) })
        var assetData: [CategoryData] = []
        let payments: [Asset.Loan.Payment] = {
            var payments: [Asset.Loan.Payment] = []
            for asset in assets.filter({ category.contains($0.metaData.category) && $0.loan != nil }) {
                let assetPayments = asset.loan!.payments.filter({ navigationStore.dashboardConfig.contains($0.date) })
                payments += assetPayments
                assetData += asset.toCategoryData(assetPayments)
            }
            return payments
        }()
        let categoryData = expenses.map(Expense.toCategoryData) + assetData
        let financeData = expenses.map(Expense.toFinanceData) + payments.map({ .init(date: $0.date, amount: ($0.amount - $0.principal).toUsd(), category: .expense) })
        ZStack(alignment: .bottomTrailing) {
            Form {
                BudgetCategoryView(category: category, financeData: financeData, categoryData: categoryData)
            }.gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                .onEnded { value in
                    switch(value.translation.width, value.translation.height) {
                    case (...(-30), -30...30): next()
                    case (30..., -30...30): prev()
                    default: break
                    }
                }
            )
        }.tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle(DashboardView.computeTitle(category: category, dashboardConfig: navigationStore.dashboardConfig))
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.init(uiColor: UIColor.secondarySystemBackground))
            .toolbar(content: toolbarItems)
    }
    
    private func prev() {
        let date = navigationStore.dashboardConfig.date
        withAnimation {
            navigationStore.dashboardConfig.date = .from(year: date.year, month: date.month - 1, day: 1)
        }
    }
    
    private func next() {
        let date = navigationStore.dashboardConfig.date
        withAnimation {
            navigationStore.dashboardConfig.date = .from(year: date.year, month: date.month + 1, day: 1)
        }
    }
    
    private func isFiltered(_ expense: Expense) -> Bool {
        if category.parent != nil {
            return category.contains(expense.category) && navigationStore.dashboardConfig.contains(expense.date)
        }
        return navigationStore.dashboardConfig.contains(expense.date)
    }
    
    @ToolbarContentBuilder
    private func toolbarItems() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("Type", selection: $navigationStore.dashboardConfig.dateRangeType) {
                Text("Month").tag(DashboardConfig.DateRangeType.month)
                Text("YTD").tag(DashboardConfig.DateRangeType.ytd)
            }.pickerStyle(.segmented)
                .frame(width: 120)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Edit '\(category.name)'") {
                    navigationStore.push(ExpenseViewType.editCategory(category: category))
                }
                Button("View Assets") {
                    navigationStore.push(AssetViewType.list)
                }
            } label: {
                Label("Settings", systemImage: "gear").labelStyle(.iconOnly)
            }
        }
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
