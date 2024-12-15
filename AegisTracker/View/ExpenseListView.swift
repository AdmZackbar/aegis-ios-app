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
    
    private let expenses: [Expense]
    private let omitted: [ExpenseEntryView.Component]
    
    @Binding private var path: [ViewType]
    @State private var deleteShowing: Bool = false
    @State private var deleteItem: Expense? = nil
    
    init(path: Binding<[ViewType]>, expenses: [Expense], omitted: [ExpenseEntryView.Component] = []) {
        self._path = path
        self.expenses = expenses
        self.omitted = omitted
    }
    
    var body: some View {
        ForEach(expenses, id: \.hashValue) { expense in
            expenseEntry(expense)
                .swipeActions {
                    deleteButton(expense)
                    editButton(expense)
                }
                .contextMenu {
                    Button {
                        path.append(.ListByCategory(category: expense.category))
                    } label: {
                        Label("View '\(expense.category)'", systemImage: "magnifyingglass")
                    }
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
            path.append(.EditExpense(expense: expense))
        } label: {
            Label("Edit", systemImage: "pencil.circle").tint(.blue)
        }
    }
    
    private func duplicateButton(_ expense: Expense) -> some View {
        Button {
            let duplicate = Expense(date: expense.date, payee: expense.payee, amount: expense.amount, category: expense.category, notes: expense.notes, details: expense.details)
            modelContext.insert(duplicate)
            path.append(.EditExpense(expense: duplicate))
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
            path.append(.ViewExpense(expense: expense))
        } label: {
            ExpenseEntryView(expense: expense, omitted: omitted)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NavigationStack {
        Form {
            ExpenseListView(path: .constant([]), expenses: [], omitted: [])
        }
    }
}
