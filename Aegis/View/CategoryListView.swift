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
        let map = {
            var map: [String: [Expense]] = [:]
            for expense in expenses {
                map[expense.category, default: []].append(expense)
            }
            return map
        }()
        Form {
            if let selectedCategory = selectedCategory {
                if selectedCategory == "All" {
                    ForEach(map.sorted(by: { $0.key < $1.key }), id: \.key) { category, expenses in
                        Section(category) {
                            ExpenseListView(path: $path, expenses: expenses, titleComponents: [.Date])
                        }
                    }
                } else {
                    Section(selectedCategory) {
                        ExpenseListView(path: $path, expenses: map[selectedCategory, default: []], titleComponents: [.Date])
                    }
                }
            } else {
                Button {
                    path.append(.ListByCategory(category: "All"))
                } label: {
                    HStack {
                        Text("All")
                        Spacer()
                    }.frame(height: 36).contentShape(Rectangle())
                }.buttonStyle(.plain)
                Section("Categories") {
                    ForEach(MainView.ExpenseCategories.sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { header, children in
                        Menu {
                            ForEach(children, id: \.hashValue) { child in
                                Button(child) {
                                    path.append(.ListByCategory(category: child))
                                }
                            }
                        } label: {
                            HStack {
                                Text(header)
                                Spacer()
                            }.frame(height: 36).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }
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
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    return NavigationStack {
        CategoryListView(path: .constant([]), selectedCategory: "All")
    }.modelContainer(container)
}
