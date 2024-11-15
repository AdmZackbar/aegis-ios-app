//
//  MainView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/10/24.
//

import SwiftUI

struct MainView: View {
    @State private var path: [ViewType] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("View") {
                    Button {
                        path.append(.ListByDate)
                    } label: {
                        HStack {
                            Label("List By Date", systemImage: "calendar")
                            Spacer()
                        }.frame(height: 36).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
                Section("Record") {
                    Button {
                        path.append(.AddExpense)
                    } label: {
                        HStack {
                            Label("Add Expense", systemImage: "cart.badge.plus")
                            Spacer()
                        }.frame(height: 36).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }.navigationTitle("Aegis")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: ViewType.self, destination: computeDestination)
        }
    }
    
    @ViewBuilder
    private func computeDestination(viewType: ViewType) -> some View {
        switch viewType {
        case .ListByDate:
            DateListView(path: $path)
        case .AddExpense:
            EditExpenseView(path: $path)
        case .EditExpense(let expense):
            EditExpenseView(path: $path, expense: expense)
        case .ViewGroceryListExpense(let expense):
            GroceryListExpenseView(path: $path, expense: expense)
        }
    }
}

enum ViewType: Hashable {
    case ListByDate
    case AddExpense
    case EditExpense(expense: Expense)
    case ViewGroceryListExpense(expense: Expense)
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    return MainView().modelContainer(container)
}
