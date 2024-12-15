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
    @State private var searchText: String = ""
    @State private var showEditAlert: Bool = false
    @State private var editName: String = ""
    
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
                categoryListView(category: category, expenses: map[category, default: []])
            } else {
                selectView(map)
            }
        }.navigationTitle(selectedCategory ?? "Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        path.append(.AddExpense)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                if selectedCategory != nil {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showEditAlert = true
                        } label: {
                            Label("Change Category Name...", systemImage: "pencil.circle")
                        }
                    }
                }
            }
            .alert("Edit category name", isPresented: $showEditAlert) {
                TextField("New Name", text: $editName)
                Button("OK", action: changeName).disabled(editName.isEmpty)
                Button("Cancel") {
                    showEditAlert = false
                }
            }
    }
    
    private func changeName() {
        expenses.filter({ $0.category == selectedCategory }).forEach({ $0.category = editName })
        try? modelContext.save()
        if !path.isEmpty {
            path.removeLast()
            path.append(.ListByCategory(category: editName))
        }
    }
    
    @ViewBuilder
    private func selectView(_ map: [String : [Expense]]) -> some View {
        ForEach(map.filter({ isCategoryFiltered($0.key) })
            .sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { category, expenses in
                categoryButton(map: map, category: category)
        }
    }
    
    private func isCategoryFiltered(_ category: String) -> Bool {
        searchText.isEmpty || category.localizedCaseInsensitiveContains(searchText)
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
            ExpenseListView(path: $path, expenses: expenses.filter({ isFiltered($0) }), omitted: [.Category])
        }
    }
    
    private func isFiltered(_ expense: Expense) -> Bool {
        searchText.isEmpty || expense.payee.localizedCaseInsensitiveContains(searchText) || expense.notes.localizedCaseInsensitiveContains(searchText)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NavigationStack {
        CategoryListView(path: .constant([]))
    }
}
