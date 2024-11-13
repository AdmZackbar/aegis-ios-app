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
            NavigationStack(path: $legacyPath) {
                PurchaseListView(path: $legacyPath)
                    .navigationDestination(for: ViewType.self, destination: computeDestination)
            }.tabItem {
                Label("Legacy", systemImage: "trash")
            }
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
        case .PurchaseListView:
            PurchaseListView(path: $path)
        case .AddPurchase:
            EditPurchaseView(path: $path)
        case .EditPurchase(let purchase):
            EditPurchaseView(path: $path, purchase: purchase)
        case .AddExpense:
            EditExpenseView(path: $path)
        case .EditExpense(let expense):
            EditExpenseView(path: $path, expense: expense)
        }
    }
}

enum ViewType: Hashable {
    case PurchaseListView
    case AddPurchase
    case EditPurchase(purchase: Purchase)
    case AddExpense
    case EditExpense(expense: Expense)
}

#Preview {
    let container = createTestModelContainer()
    container.mainContext.insert(Purchase(date: Date(), category: .Gas(numGallons: 9.1, costPerGallon: .Cents(254), octane: 87), seller: "Costco", price: .Cents(3591)))
    container.mainContext.insert(Purchase(date: Date(), category: .Hardware(name: "4 TB M.2 SSD"), seller: "Amazon", price: .Cents(39127)))
    container.mainContext.insert(Purchase(date: Date(), category: .Software(name: "Photoshop"), seller: "Adobe", price: .Cents(999)))
    container.mainContext.insert(Purchase(date: Date(), category: .Restaurant(details: "Day trip to Rocktown", tip: .Cents(250)), seller: "Mentone Cafe", price: .Cents(980)))
    return MainView().modelContainer(container)
}
