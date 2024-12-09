//
//  GroceryListExpenseView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/15/24.
//

import SwiftData
import SwiftUI

struct ExpenseGroceryListView: View {
    let expense: Expense
    let groceryList: Expense.GroceryList
    
    @Binding private var path: [ViewType]
    
    init(path: Binding<[ViewType]>, expense: Expense) {
        self._path = path
        self.expense = expense
        switch expense.details {
        case .Groceries(let list):
            self.groceryList = list
        default:
            self.groceryList = .init(foods: [])
        }
    }
    
    var body: some View {
        Form {
            Section("Info") {
                Text(expense.payee)
                Text(expense.date.formatted(date: .complete, time: .omitted))
                Text("Total: \(expense.amount.toString())")
            }
            Section("Foods") {
                ForEach(groceryList.foods, id: \.hashValue, content: foodEntry)
            }
        }.navigationTitle("\(expense.payee) Groceries - \(expense.date.formatted(date: .abbreviated, time: .omitted))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        path.append(.EditExpense(expense: expense))
                    }
                }
            }
    }
    
    @ViewBuilder
    private func foodEntry(_ food: Expense.GroceryList.Food) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(food.name)
                Spacer()
                Text(food.totalPrice.toString())
            }
            HStack {
                Text(food.category)
                Spacer()
                if food.quantity > 1 {
                    Text("x\(food.quantity.formatted())")
                }
            }.font(.subheadline).italic()
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    let expenses = try! container.mainContext.fetch(FetchDescriptor<Expense>(predicate: #Predicate { $0.category == "Groceries" }))
    return NavigationStack {
        ExpenseGroceryListView(path: .constant([]), expense: expenses.first!)
    }.modelContainer(container)
}
