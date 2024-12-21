//
//  FinanceSummaryView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/21/24.
//

import Charts
import SwiftData
import SwiftUI

struct FinanceSummaryView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    @Query(sort: \Revenue.date, order: .reverse) var revenues: [Revenue]
    @Query(sort: \Asset.purchaseDate, order: .reverse) var assets: [Asset]
    
    var body: some View {
        let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: .now)!
        yearView(e: expenses.filter({ $0.date > yearAgo }), r: revenues.filter({ $0.date > yearAgo }))
    }
    
    @ViewBuilder
    private func yearView(e: [Expense], r: [Revenue]) -> some View {
        // TODO
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        FinanceSummaryView()
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
