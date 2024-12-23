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
        "Utilities",
        "Healthcare",
        "Personal",
        "Entertainment",
        "Other"
    ]
    static let RevenueCategories: [String] = [
        "Paycheck",
        "Gift",
        "Bonus",
        "Retirement",
        "Reimbursement",
        "Dividend"
    ]
    
    static let ExpenseCategoryColors: [String : Color] = [
        "Car": Color.indigo,
        "Food": Color.blue,
        "Housing": Color.red,
        "Media": Color.cyan,
        "Medicine": Color.pink,
        "Personal": Color.orange,
        "Recreation": Color.yellow,
        "Technology": Color.green,
        "Travel": Color.purple,
        "Other": Color.gray
    ]
    
    @Query(filter: #Predicate<BudgetCategory> { $0.parent == nil }) var budgets: [BudgetCategory]
    @StateObject private var navigationStore = NavigationStore()
    
    @SceneStorage("navigation")
    private var navigationData: Data?
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            List {
                Section("Expenses") {
                    Button {
                        navigationStore.push(ExpenseViewType.add())
                    } label: {
                        button("Add Expense", icon: "text.badge.plus")
                    }.buttonStyle(.plain)
                    Button {
                        navigationStore.push(ExpenseViewType.byDate)
                    } label: {
                        button("View By Date", icon: "calendar")
                    }.buttonStyle(.plain)
                    Button {
                        navigationStore.push(ExpenseViewType.byCategory())
                    } label: {
                        button("View By Category", icon: "folder")
                    }.buttonStyle(.plain)
                    Button {
                        navigationStore.push(ExpenseViewType.byPayee())
                    } label: {
                        button("View By Payee", icon: "person")
                    }.buttonStyle(.plain)
                    if !budgets.isEmpty {
                        Menu {
                            ForEach(budgets, id: \.hashValue) { budget in
                                Button(budget.name) {
                                    navigationStore.push(ExpenseViewType.editCategory(category: budget))
                                }
                            }
                        } label: {
                            button("Edit Budget Categories", icon: "pencil.circle")
                        }.buttonStyle(.plain)
                    }
                }
                Section("Revenue") {
                    Button {
                        navigationStore.push(RevenueViewType.add())
                    } label: {
                        button("Add Revenue", icon: "text.badge.plus")
                    }.buttonStyle(.plain)
                    Button {
                        navigationStore.push(RevenueViewType.byDate)
                    } label: {
                        button("View By Date", icon: "calendar")
                    }.buttonStyle(.plain)
                    Button {
                        navigationStore.push(RevenueViewType.byPayer())
                    } label: {
                        button("View By Payer", icon: "person")
                    }.buttonStyle(.plain)
                }
                Section("Assets") {
                    Button {
                        navigationStore.push(AssetViewType.add)
                    } label: {
                        button("Add Asset", icon: "plus")
                    }.buttonStyle(.plain)
                    Button {
                        navigationStore.push(AssetViewType.list)
                    } label: {
                        button("View Assets", icon: "folder")
                    }.buttonStyle(.plain)
                }
            }.navigationTitle("Aegis")
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
        case .editCategory(let category):
            BudgetCategoryEditView(category: category)
        case .byCategory(let name):
            if let name {
                ExpenseCategoryView(category: name)
            } else {
                ExpenseCategoryListView()
            }
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
        case .add(let initial):
            ExpenseEditView(expense: initial, mode: .Add)
        case .edit(let expense):
            ExpenseEditView(expense: expense, mode: .Edit)
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
    case editCategory(category: BudgetCategory)
    case byCategory(name: String? = nil)
    case byDate
    case byMonth(year: Int, month: Int)
    case byPayee(name: String? = nil)
    case view(expense: Expense)
    case add(initial: Expense? = nil)
    case edit(expense: Expense)
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
