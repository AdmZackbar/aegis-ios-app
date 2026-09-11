//
//  ExpenseListView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/16/24.
//

import SwiftData
import SwiftUI

struct ExpenseListView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    private let expenses: [Expense]
    private let omitted: [ExpenseEntryView.Component]
    private let category: BudgetCategory?
    private let allowSwipeActions: Bool
    
    @State private var deleteShowing: Bool = false
    @State private var deleteItem: Expense? = nil
    
    init(expenses: [Expense], omitted: [ExpenseEntryView.Component] = [], category: BudgetCategory? = nil, allowSwipeActions: Bool = true) {
        self.expenses = expenses
        self.omitted = omitted
        self.category = category
        self.allowSwipeActions = allowSwipeActions
    }
    
    var body: some View {
        ForEach(expenses.enumerated().sorted(by: { $0.offset < $1.offset }), id: \.offset) { offset, expense in
            expenseEntry(expense)
                .swipeActions {
                    if allowSwipeActions {
                        deleteButton(expense)
                        editButton(expense)
                    }
                }
                .contextMenu {
                    if !omitted.contains(.Category) {
                        Button {
                            navigationStore.push(ExpenseViewType.byCategory(name: expense.category))
                        } label: {
                            Label("View '\(expense.category)'", systemImage: "tag")
                        }
                    }
                    if !omitted.contains(.Payee) {
                        Button {
                            navigationStore.push(ExpenseViewType.byPayee(name: expense.payee))
                        } label: {
                            Label("View '\(expense.payee)'", systemImage: "person")
                        }
                    }
                    Divider()
                    editButton(expense)
                    deleteButton(expense)
                }
        }.alert("Delete Expense?", isPresented: $deleteShowing) {
            Button("Delete", role: .destructive) {
                if let generic = deleteItem as? GenericExpense {
                    withAnimation {
                        modelContext.delete(generic)
                    }
                }
            }
        }
    }
    
    private func editButton(_ expense: Expense) -> some View {
        Button {
            if let generic = expense as? GenericExpense {
                navigationStore.push(ExpenseViewType.edit(expense: generic))
            } else if let financed = expense as? FinancedExpenseInstance {
                navigationStore.push(ExpenseViewType.editFinanced(expense: financed.expense))
            } else if let sub = expense as? SubscriptionExpense {
                navigationStore.push(ExpenseViewType.editSub(subscription: sub.subscription))
            }
        } label: {
            Label("Edit", systemImage: "pencil.circle").tint(.blue)
        }
    }
    
    private func deleteButton(_ expense: Expense) -> some View {
        Button {
            deleteItem = expense
            deleteShowing = true
        } label: {
            Label("Delete", systemImage: "trash").tint(.red)
        }
    }
    
    @ViewBuilder
    private func expenseEntry(_ expense: Expense) -> some View {
        Button {
            if let generic = expense as? GenericExpense {
                navigationStore.push(ExpenseViewType.view(expense: generic))
            } else if let financed = expense as? FinancedExpenseInstance {
                navigationStore.push(ExpenseViewType.viewFinanced(expense: financed.expense))
            } else if let sub = expense as? SubscriptionExpense {
                navigationStore.push(ExpenseViewType.viewSub(subscription: sub.subscription))
            }
        } label: {
            ExpenseEntryView(expense: expense, omitted: omitted, category: category)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        Form {
            ExpenseListView(expenses: [GenericExpense(payee: "Costco", amount: .Cents(34156), category: "Groceries", notes: "Test run", details: .Items(list: .init(items: [
                .init(name: "Chicken Thighs", brand: "Kirkland Signature", quantity: .Unit(num: 4.51, unit: "lb"), total: .Cents(3541)),
                .init(name: "Hot Chocolate", brand: "Swiss Miss", quantity: .Discrete(1), total: .Cents(799), discount: .Cents(300)),
                .init(name: "Chicken Chunks", brand: "Just Bare", quantity: .Discrete(2), total: .Cents(1499))
            ])))], omitted: [])
        }.navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
