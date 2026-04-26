//
//  CopyRevenueSheetView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 4/26/26.
//

import SwiftData
import SwiftUI

struct CopyRevenueSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Revenue.date, order: .reverse) var revenues: [Revenue]
    
    @State private var filter: String = ""
    
    var body: some View {
        NavigationStack {
            List(revenues.filter(filter).prefix(50)) { revenue in
                Button {
                    dismiss()
                    let copy = Revenue(date: .now, payer: revenue.payer, amount: revenue.amount, category: revenue.category, notes: revenue.notes)
                    navigationStore.push(RevenueViewType.add(initial: copy))
                } label: {
                    RevenueEntryView(revenue: revenue)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
            }.navigationTitle("Select Base Income")
                .searchable(text: $filter, prompt: "Filter by payer, category, notes...")
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
    
    private func filter(_ revenue: Revenue) -> Bool {
        if (filter.isEmpty) {
            return true
        }
        return filter.split(whereSeparator: \.isWhitespace).allSatisfy({ word in
            revenue.category.localizedCaseInsensitiveContains(word) || revenue.payer.localizedCaseInsensitiveContains(word) || revenue.notes.localizedCaseInsensitiveContains(word)
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
                CopyRevenueSheetView()
                    
            }
    }.environmentObject(navigationStore)
}
