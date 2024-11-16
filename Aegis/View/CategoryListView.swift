//
//  CategoryListView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/15/24.
//

import SwiftData
import SwiftUI

struct CategoryListView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    @Binding private var path: [ViewType]
    
    init(path: Binding<[ViewType]>) {
        self._path = path
    }
    
    var body: some View {
        let map = {
            var map: [String: [Expense]] = [:]
            for expense in expenses {
                map[expense.category, default: []].append(expense)
            }
            return map
        }()
        Form {
            ForEach(map.sorted(by: { $0.key < $1.key }), id: \.key) { category, expenses in
                Section(category) {
                    expenseList(expenses)
                }
            }
        }.navigationTitle("By Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        path.append(.AddExpense)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
    }
    
    @ViewBuilder
    private func expenseList(_ expenses: [Expense]) -> some View {
        ForEach(expenses, id: \.hashValue) { expense in
            expenseEntry(expense)
                .contextMenu {
                    Button {
                        path.append(.EditExpense(expense: expense))
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                    Button {
                        let duplicate = Expense(date: expense.date, payee: expense.payee, amount: expense.amount, category: expense.category, details: expense.details)
                        modelContext.insert(duplicate)
                        path.append(.EditExpense(expense: duplicate))
                    } label: {
                        Label("Duplicate...", systemImage: "plus.square.on.square")
                    }
                    Button(role: .destructive) {
                        modelContext.delete(expense)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }.onDelete(perform: { indexSet in
            for index in indexSet {
                modelContext.delete(expenses[index])
            }
        })
    }
    
    @ViewBuilder
    private func expenseEntry(_ expense: Expense) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(expense.date.formatted(date: .abbreviated, time: .omitted)).bold()
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
                if !details.details.isEmpty {
                    Text(details.details).font(.caption)
                }
            }
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    return NavigationStack {
        CategoryListView(path: .constant([]))
    }.modelContainer(container)
}
