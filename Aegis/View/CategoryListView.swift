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
    
    private var selectedCategory: String?
    
    @Binding private var path: [ViewType]
    
    init(path: Binding<[ViewType]>, selectedCategory: String? = nil) {
        self._path = path
        self.selectedCategory = selectedCategory
    }
    
    var body: some View {
        let map: [String: [Expense]] = {
            var map: [String: [Expense]] = [:]
            for expense in expenses {
                map[expense.category, default: []].append(expense)
            }
            return map
        }()
        Form {
            if let category = selectedCategory {
                if MainView.ExpenseCategories.keys.contains(category) {
                    ForEach(MainView.ExpenseCategories[category]!, id: \.hashValue) { c in
                        categoryListView(category: c, expenses: map[c, default: []])
                    }
                } else {
                    categoryListView(category: category, expenses: map[category, default: []])
                }
            } else {
                selectView(map)
            }
        }.navigationTitle(selectedCategory ?? "Select Category")
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
    private func selectView(_ map: [String: [Expense]]) -> some View {
        ForEach(MainView.ExpenseCategories.sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { header, categories in
            // Only display sections with expenses in its subcategories
            if categories.map({ map[$0, default: []].count }).reduce(0, +) > 0 {
                Section(header) {
                    ForEach(categories, id: \.hashValue) { category in
                        // Only show the button if it has expenses
                        if !map[category, default: []].isEmpty {
                            categoryButton(map: map, category: category)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func categoryButton(map: [String: [Expense]], category: String) -> some View {
        Button {
            path.append(.ListByCategory(category: category))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(category).font(.headline)
                HStack {
                    Text("\(map[category, default: []].count) expenses")
                    Spacer()
                    Text(map[category, default: []].map({ $0.amount }).reduce(Price.Cents(0), +).toString())
                }.font(.subheadline).italic()
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func categoryListView(category: String, expenses: [Expense]) -> some View {
        Section(category) {
            ExpenseListView(path: $path, expenses: expenses, titleComponents: [.Date])
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
