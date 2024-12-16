//
//  PayeeListView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/14/24.
//

import SwiftData
import SwiftUI

struct PayeeListView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    private var selectedPayee: String?
    
    @State private var searchText: String = ""
    @State private var showEditAlert: Bool = false
    @State private var editName: String = ""
    
    init(selectedPayee: String? = nil) {
        self.selectedPayee = selectedPayee
    }
    
    var body: some View {
        let map: [String: [Expense]] = {
            var map: [String: [Expense]] = [:]
            for expense in expenses {
                map[expense.payee, default: []].append(expense)
            }
            return map
        }()
        Form {
            if let payee = selectedPayee {
                payeeListView(payee: payee, expenses: map[payee, default: []])
            } else {
                selectView(map)
            }
        }.navigationTitle(selectedPayee ?? "Select Payee")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.path.append(RecordType.addExpense)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                if selectedPayee != nil {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showEditAlert = true
                        } label: {
                            Label("Change Payee Name...", systemImage: "pencil.circle")
                        }
                    }
                }
            }
            .alert("Edit payee name", isPresented: $showEditAlert) {
                TextField("New Name", text: $editName)
                Button("OK", action: changePayeeName).disabled(editName.isEmpty)
                Button("Cancel") {
                    showEditAlert = false
                }
            }
    }
    
    private func changePayeeName() {
        expenses.filter({ $0.payee == selectedPayee }).forEach({ $0.payee = editName })
        try? modelContext.save()
        if !navigationStore.path.isEmpty {
            navigationStore.path.removeLast()
            navigationStore.path.append(ViewType.payee(name: editName))
        }
    }
    
    @ViewBuilder
    private func selectView(_ map: [String: [Expense]]) -> some View {
        ForEach(map.filter({ isPayeeFiltered($0.key) })
            .sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { payee, expenses in
                payeeButton(map: map, payee: payee)
        }
    }
    
    private func isPayeeFiltered(_ payee: String) -> Bool {
        searchText.isEmpty || payee.localizedCaseInsensitiveContains(searchText)
    }
    
    @ViewBuilder
    private func payeeButton(map: [String: [Expense]], payee: String) -> some View {
        Button {
            navigationStore.path.append(ViewType.payee(name: payee))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(payee).font(.headline)
                HStack {
                    Text("\(map[payee, default: []].count) expenses")
                    Spacer()
                    Text(map[payee, default: []].map({ $0.amount }).reduce(Price.Cents(0), +).toString())
                }.font(.subheadline).italic()
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func payeeListView(payee: String, expenses: [Expense]) -> some View {
        Section(payee) {
            ExpenseListView(expenses: expenses.filter({ isFiltered($0) }), omitted: [.Payee])
        }
    }
    
    private func isFiltered(_ expense: Expense) -> Bool {
        searchText.isEmpty || expense.payee.localizedCaseInsensitiveContains(searchText) || expense.notes.localizedCaseInsensitiveContains(searchText)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        PayeeListView()
            .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
