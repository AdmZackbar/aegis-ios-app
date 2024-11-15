//
//  MainView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/10/24.
//

import SwiftUI

struct MainView: View {
    @State private var legacyPath: [ViewType] = []
    @State private var path: [ViewType] = []
    
    var body: some View {
        TabView {
            NavigationStack(path: $path) {
                DateListView(path: $path)
                    .navigationDestination(for: ViewType.self, destination: computeDestination)
            }.tabItem {
                Label("New", systemImage: "cloud")
            }
        }
    }
    
    @ViewBuilder
    private func computeDestination(viewType: ViewType) -> some View {
        switch viewType {
        case .AddExpense:
            EditExpenseView(path: $path)
        case .EditExpense(let expense):
            EditExpenseView(path: $path, expense: expense)
        }
    }
}

enum ViewType: Hashable {
    case AddExpense
    case EditExpense(expense: Expense)
}

#Preview {
    let container = createTestModelContainer()
    container.mainContext.insert(Expense(date: .now, payee: "Costo", amount: .Cents(3541), category: "Gas", details: .Fuel(amount: 11.123, rate: 2.652, type: "Gas", user: "Personal Vehicle")))
    container.mainContext.insert(Expense(date: .now, payee: "NBKC Bank", amount: .Cents(600), category: "Housing Payment", details: .Generic(details: "November payment")))
    return MainView().modelContainer(container)
}
