//
//  RevenueListView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/20/24.
//

import SwiftData
import SwiftUI

struct RevenueListView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    private let revenues: [Revenue]
    
    @State private var deleteShowing: Bool = false
    @State private var deleteItem: Revenue? = nil
    
    init(revenues: [Revenue]) {
        self.revenues = revenues
    }
    
    var body: some View {
        ForEach(revenues, id: \.hashValue) { revenue in
            revenueEntry(revenue)
                .swipeActions {
                    deleteButton(revenue)
                    editButton(revenue)
                }
                .contextMenu {
                    // TODO
//                    if !omitted.contains(.Category) {
//                        Button {
//                            navigationStore.push(ExpenseViewType.byCategory(name: expense.category))
//                        } label: {
//                            Label("View '\(expense.category)'", systemImage: "tag")
//                        }
//                    }
//                    if !omitted.contains(.Payee) {
//                        Button {
//                            navigationStore.push(ExpenseViewType.byPayee(name: expense.payee))
//                        } label: {
//                            Label("View '\(expense.payee)'", systemImage: "person")
//                        }
//                    }
//                    Divider()
                    editButton(revenue)
                    duplicateButton(revenue)
                    deleteButton(revenue)
                }
        }.alert("Delete Revenue?", isPresented: $deleteShowing) {
            Button("Delete", role: .destructive) {
                if let item = deleteItem {
                    withAnimation {
                        modelContext.delete(item)
                    }
                }
            }
        }
    }
    
    private func editButton(_ revenue: Revenue) -> some View {
        Button {
            navigationStore.push(RevenueViewType.edit(revenue: revenue))
        } label: {
            Label("Edit", systemImage: "pencil.circle").tint(.blue)
        }
    }
    
    private func duplicateButton(_ revenue: Revenue) -> some View {
        Button {
            let duplicate = Revenue(date: revenue.date, payer: revenue.payer, amount: revenue.amount, category: revenue.category, notes: revenue.notes)
            modelContext.insert(duplicate)
            navigationStore.push(RevenueViewType.edit(revenue: duplicate))
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
    }
    
    private func deleteButton(_ revenue: Revenue) -> some View {
        Button {
            deleteItem = revenue
            deleteShowing = true
        } label: {
            Label("Delete", systemImage: "trash").tint(.red)
        }
    }
    
    @ViewBuilder
    private func revenueEntry(_ revenue: Revenue) -> some View {
        Button {
            navigationStore.push(RevenueViewType.view(revenue: revenue))
        } label: {
            RevenueEntryView(revenue: revenue)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        Form {
            RevenueListView(revenues: [
                .init(payer: "RMCI", amount: .Cents(233412), category: "Paycheck"),
                .init(payer: "Ruth Wassynger", amount: .Cents(2341), category: "Gift", notes: "Birthday"),
                .init(payer: "Fidelity", amount: .Cents(231), category: "Dividend", notes: "Apple divident")
            ])
        }.navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
