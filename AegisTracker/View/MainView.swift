//
//  MainView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/10/24.
//

import SwiftData
import SwiftUI

struct MainView: View {
    static let MainExpenseCategories: [String] = [
        "Housing",
        "Food",
        "Transportation",
        "Healthcare",
        "Personal",
        "Entertainment"
    ]
    static let RevenueCategories: [String] = [
        "Paycheck",
        "Gift",
        "Bonus",
        "Retirement",
        "Reimbursement"
    ]
    
    @Query(filter: #Predicate<BudgetCategory> { $0.parent == nil }) var budgets: [BudgetCategory]
    @StateObject private var navigationStore = NavigationStore()
    
    @SceneStorage("navigation")
    private var navigationData: Data?
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            DashboardView()
                .navigationTitle("Aegis")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: ExpenseViewType.self, destination: Self.computeDestination)
                .navigationDestination(for: RevenueViewType.self, destination: Self.computeDestination)
                .navigationDestination(for: AssetViewType.self, destination: Self.computeDestination)
        }.environmentObject(navigationStore)
    }
    
    @ViewBuilder
    func button(_ text: String, icon: String) -> some View {
        HStack {
            Label(text, systemImage: icon)
            Spacer()
        }.frame(height: 36).contentShape(Rectangle())
    }
    
    @ViewBuilder
    static func computeDestination(type: RevenueViewType, navigationStore: NavigationStore) -> some View {
        Self.computeDestination(type: type)
            .environmentObject(navigationStore)
    }
    
    @ViewBuilder
    static func computeDestination(type: RevenueViewType) -> some View {
        switch type {
        case .byDate:
            RevenueDateView()
        case .byPayer(let name):
            if let name {
                RevenuePayerView(payer: name)
            } else {
                RevenuePayerListView()
            }
        case .view(let revenue):
            RevenueView(revenue: revenue)
        case .add(let initial):
            RevenueEditView(revenue: initial, mode: .Add)
        case .edit(let revenue):
            RevenueEditView(revenue: revenue)
        }
    }
    
    @ViewBuilder
    static func computeDestination(type: ExpenseViewType, navigationStore: NavigationStore) -> some View {
        Self.computeDestination(type: type)
            .environmentObject(navigationStore)
    }
    
    @ViewBuilder
    static func computeDestination(type: ExpenseViewType) -> some View {
        switch type {
        case .dashboardCategory(let category):
            DashboardCategoryView(category: category)
        case .editCategory(let category):
            BudgetCategoryEditView(category: category)
        case .byCategory(let name):
            if let name {
                // TODO
                ExpenseCategoryView(category: .init(name: name))
            } else {
                ExpenseCategoryListView()
            }
        case .viewTags:
            ExpenseTagsView()
        case .viewTag(let tag):
            ExpenseTagView(tag: tag)
        case .byDate:
            ExpenseDateView()
        case .byMonth(let year, let month):
            ExpenseMonthView(year: year, month: month)
        case .byPayee(let name):
            if let name {
                ExpensePayeeView(payee: name)
            } else {
                ExpensePayeeListView()
            }
        case .view(let expense):
            ExpenseView(expense: expense)
        case .viewFinanced(let expense):
            FinancedExpenseView(expense: expense)
        case .viewSub(let subscription):
            SubscriptionView(subscription: subscription)
        case .add(let initial):
            ExpenseEditView(expense: initial, mode: .Add)
        case .addFinanced(let initial):
            FinancedExpenseEditView(expense: initial, mode: .Add)
        case .addSub(let initial):
            SubscriptionEditView(subscription: initial, mode: .Add)
        case .edit(let expense):
            ExpenseEditView(expense: expense, mode: .Edit)
        case .editFinanced(let expense):
            FinancedExpenseEditView(expense: expense, mode: .Edit)
        case .editSub(let subscription):
            SubscriptionEditView(subscription: subscription, mode: .Edit)
        case .list(let title, let expenses):
            Form {
                Section("Expenses") {
                    ExpenseListView(expenses: expenses, omitted: [.Category])
                }.headerProminence(.increased)
            }.navigationTitle(title)
        }
    }
    
    @ViewBuilder
    static func computeDestination(type: AssetViewType, navigationStore: NavigationStore) -> some View {
        Self.computeDestination(type: type)
            .environmentObject(navigationStore)
    }
    
    @ViewBuilder
    static func computeDestination(type: AssetViewType) -> some View {
        switch type {
        case .list:
            AssetListView()
        case .view(let asset):
            AssetView(asset: asset)
        case .add:
            AssetEditView()
        case .edit(let asset):
            AssetEditView(asset: asset)
        }
    }
}

enum ExpenseViewType: Hashable {
    case dashboardCategory(category: BudgetCategory)
    case editCategory(category: BudgetCategory)
    case viewTags
    case viewTag(tag: ExpenseTag)
    case byCategory(name: String? = nil)
    case byDate
    case byMonth(year: Int, month: Int)
    case byPayee(name: String? = nil)
    case view(expense: Expense)
    case viewFinanced(expense: FinancedExpense)
    case viewSub(subscription: Subscription)
    case add(initial: Expense? = nil)
    case addFinanced(initial: FinancedExpense? = nil)
    case addSub(initial: Subscription? = nil)
    case edit(expense: Expense)
    case editFinanced(expense: FinancedExpense)
    case editSub(subscription: Subscription)
    case list(title: String, expenses: [Expense])
}

enum RevenueViewType: Hashable {
    case byDate
    case byPayer(name: String? = nil)
    case view(revenue: Revenue)
    case add(initial: Revenue? = nil)
    case edit(revenue: Revenue)
}

enum AssetViewType: Hashable {
    case list
    case view(asset: Asset)
    case add
    case edit(asset: Asset)
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    MainView()
}
