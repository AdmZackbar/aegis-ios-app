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
    private let titleComponents: [Component]
    
    @Binding private var path: [ViewType]
    @State private var deleteShowing: Bool = false
    @State private var deleteItem: Expense? = nil
    
    init(path: Binding<[ViewType]>, expenses: [Expense], titleComponents: [Component] = []) {
        self._path = path
        self.expenses = expenses
        self.titleComponents = !titleComponents.isEmpty ? titleComponents : [.Category, .Date]
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
                    Button {
                        let duplicate = Expense(date: expense.date, payee: expense.payee, amount: expense.amount, category: expense.category, notes: expense.notes, detailType: expense.detailType, details: expense.details)
                        modelContext.insert(duplicate)
                        path.append(.EditExpense(expense: duplicate))
                    } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(getTitle(expense)).bold()
                Spacer()
                Text(expense.amount.toString()).bold()
            }
            switch expense.details {
            case .Generic(let details):
                Text(expense.payee).font(.subheadline).italic()
                if !details.isEmpty {
                    Text(details).font(.caption)
                }
            case .Tag(let tag, let details):
                HStack {
                    Text(expense.payee).font(.subheadline).italic()
                    Spacer()
                    Text(tag).font(.subheadline).italic()
                }
                if !details.isEmpty {
                    Text(details).font(.caption)
                }
            case .Fuel(let numGallons, let costPerGallon, let type, let user):
                HStack(alignment: .top) {
                    Text(expense.payee).font(.subheadline).italic()
                    Spacer()
                    Text("\(numGallons.formatted(.number.precision(.fractionLength(0...1)))) gal @ \(costPerGallon.formatted(.currency(code: "USD")))")
                        .font(.subheadline).italic()
                }
                HStack {
                    Text(user).font(.caption)
                    Spacer()
                    Text(type).font(.caption)
                }
            case .Groceries(let list):
                Button {
                    path.append(.ViewGroceryListExpense(expense: expense))
                } label: {
                    HStack {
                        Text(expense.payee)
                        Spacer()
                        Text("\(list.foods.count) items")
                    }
                }.font(.subheadline).italic().tint(.primary)
            case .Tip(let tip, let details):
                HStack(alignment: .top) {
                    Text(expense.payee).font(.subheadline).italic()
                    Spacer()
                    if tip.toUsd() > 0 {
                        Text("\(tip.toString()) tip").font(.subheadline).italic()
                    }
                }
                if !details.isEmpty {
                    Text(details).font(.caption)
                }
            case .Bill(let details):
                HStack {
                    Text(expense.payee).font(.subheadline).italic()
                    Spacer()
                }
                ForEach(details.types, id: \.hashValue) { type in
                    HStack {
                        Text(type.getName())
                        Spacer()
                        Text(type.getTotal().toString())
                    }.font(.subheadline)
                }
                if !(details.details ?? "").isEmpty {
                    Text(details.details ?? "").font(.caption)
                }
            default:
                EmptyView()
            }
        }
    }
    
    private func getTitle(_ expense: Expense) -> String {
        titleComponents.map({ getTitle(expense: expense, component: $0) }).joined(separator: "\n")
    }
    
    private func getTitle(expense: Expense, component: Component) -> String {
        switch component {
        case .Date:
            expense.date.formatted(date: .abbreviated, time: .omitted)
        case .Category:
            expense.category
        }
    }
    
    enum Component {
        case Date
        case Category
    }
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    let expenses = try! container.mainContext.fetch(FetchDescriptor<Expense>())
    return NavigationStack {
        Form {
            ExpenseListView(path: .constant([]), expenses: expenses, titleComponents: [.Date, .Category])
        }
    }.modelContainer(container)
}
