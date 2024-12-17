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
    private let allowSwipeActions: Bool
    
    @State private var deleteShowing: Bool = false
    @State private var deleteItem: Expense? = nil
    
    init(expenses: [Expense], omitted: [ExpenseEntryView.Component] = [], allowSwipeActions: Bool = true) {
        self.expenses = expenses
        self.omitted = omitted
        self.allowSwipeActions = allowSwipeActions
    }
    
    var body: some View {
        ForEach(expenses, id: \.hashValue) { expense in
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
                            navigationStore.push(ViewType.category(name: expense.category))
                        } label: {
                            Label("View '\(expense.category)'", systemImage: "tag")
                        }
                    }
                    if !omitted.contains(.Payee) {
                        Button {
                            navigationStore.push(ViewType.payee(name: expense.payee))
                        } label: {
                            Label("View '\(expense.payee)'", systemImage: "person")
                        }
                    }
                    Divider()
                    editButton(expense)
                    duplicateButton(expense)
                    deleteButton(expense)
                }
        }.alert("Delete Expense?", isPresented: $deleteShowing) {
            Button("Delete", role: .destructive) {
                if let item = deleteItem {
                    withAnimation {
                        modelContext.delete(item)
                    }
                }
            }
        }
    }
    
    private func editButton(_ expense: Expense) -> some View {
        Button {
            navigationStore.push(RecordType.editExpense(expense: expense))
        } label: {
            Label("Edit", systemImage: "pencil.circle").tint(.blue)
        }
    }
    
    private func duplicateButton(_ expense: Expense) -> some View {
        Button {
            let duplicate = Expense(date: expense.date, payee: expense.payee, amount: expense.amount, category: expense.category, notes: expense.notes, details: expense.details)
            modelContext.insert(duplicate)
            navigationStore.push(RecordType.editExpense(expense: duplicate))
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
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
            navigationStore.push(ViewType.expense(expense: expense))
        } label: {
            ExpenseEntryView(expense: expense, omitted: omitted)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        Form {
            ExpenseListView(expenses: [.init(payee: "Costco", amount: .Cents(34156), category: "Groceries", notes: "Test run", details: .Items(list: .init(items: [
                .init(name: "Chicken Thighs", brand: "Kirkland Signature", quantity: .Unit(num: 4.51, unit: "lb"), total: .Cents(3541)),
                .init(name: "Hot Chocolate", brand: "Swiss Miss", quantity: .Discrete(1), total: .Cents(799), discount: .Cents(300)),
                .init(name: "Chicken Chunks", brand: "Just Bare", quantity: .Discrete(2), total: .Cents(1499))
            ])))], omitted: [])
        }
        .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
        .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
