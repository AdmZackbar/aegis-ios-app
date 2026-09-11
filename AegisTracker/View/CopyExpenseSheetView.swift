//
//  CopyExpenseSheetView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 4/26/26.
//

import SwiftData
import SwiftUI

struct CopyExpenseSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \GenericExpense.date, order: .reverse) var expenses: [GenericExpense]
    
    @State private var filter: String = ""
    
    var body: some View {
        NavigationStack {
            List(expenses.filter(filter).prefix(50)) { expense in
                Button {
                    dismiss()
                    let copy = GenericExpense(date: .now, payee: expense.payee, amount: expense.amount, category: expense.category, notes: expense.notes, tags: expense.tags, details: expense.details)
                    navigationStore.push(ExpenseViewType.add(initial: copy))
                } label: {
                    ExpenseEntryView(expense: expense)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
            }.navigationTitle("Select Base Expense")
                .searchable(text: $filter, prompt: "Filter by payee, category, notes...")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                    }
                }
        }
    }
    
    private func filter(_ expense: Expense) -> Bool {
        if (filter.isEmpty) {
            return true
        }
        return filter.split(whereSeparator: \.isWhitespace).allSatisfy({ word in
            expense.category.localizedCaseInsensitiveContains(word) || expense.payee.localizedCaseInsensitiveContains(word) || expense.notes.localizedCaseInsensitiveContains(word)
        })
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    @Previewable @State var presentSheet = false
    NavigationStack(path: $navigationStore.path) {
        Form {
            Button("Show Sheet") {
                presentSheet = true
            }
        }.navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
            .sheet(isPresented: $presentSheet) {
                CopyExpenseSheetView()
                    
            }
    }.environmentObject(navigationStore)
}
