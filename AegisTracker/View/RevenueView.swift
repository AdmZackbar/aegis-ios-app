//
//  RevenueView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/20/24.
//

import SwiftData
import SwiftUI

struct RevenueView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Revenue.date, order: .reverse) var revenues: [Revenue]
    
    let revenue: Revenue
   
    @State private var showDelete: Bool = false
    
    init(revenue: Revenue) {
        self.revenue = revenue
    }
    
    var body: some View {
        VStack(spacing: 4) {
            headerView()
            Form {
                let relatedRevenues = revenues.filter({ $0.payer == revenue.payer && $0.category == revenue.category && $0 != revenue })
                if !relatedRevenues.isEmpty {
                    payerExpenseList(relatedRevenues)
                }
            }.scrollContentBackground(.hidden)
            footerActionsView()
        }.navigationTitle("View \(revenue.category)")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.init(uiColor: UIColor.systemGroupedBackground))
            .confirmationDialog("Are you sure you want to delete this revenue?", isPresented: $showDelete) {
                Button("Delete", role: .destructive, action: delete)
            } message: {
                Text("You cannot undo this action")
            }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        Text(revenue.amount.toString())
            .font(.system(size: 48, weight: .bold, design: .rounded))
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(revenue.category)
                        .textCase(.uppercase)
                        .font(.caption)
                        .fontWeight(.light)
                    Text(revenue.payer)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .bold()
                }
                Spacer()
                Text(revenue.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            if !revenue.notes.isEmpty {
                Text(revenue.notes)
                    .font(.subheadline)
                    .lineLimit(5)
            }
        }.padding([.leading, .trailing], 28)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func payerExpenseList(_ revenues: [Revenue]) -> some View {
        Section("\(revenue.payer) \(revenue.category)") {
            ForEach(revenues, id: \.hashValue) { r in
                Button {
                    navigationStore.push(RevenueViewType.view(revenue: r))
                } label: {
                    RevenueEntryView(revenue: r)
                        .contentShape(Rectangle())
                }.foregroundStyle(.primary)
            }
        }
    }
    
    @ViewBuilder
    private func footerActionsView() -> some View {
        Grid {
            GridRow {
                Button {
                    navigationStore.push(RevenueViewType.edit(revenue: revenue))
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                        .bold()
                        .frame(maxWidth: .infinity, maxHeight: 30)
                }.tint(.blue)
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .bold()
                        .frame(maxWidth: .infinity, maxHeight: 30)
                }
            }.gridColumnAlignment(.center)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle)
        }.padding([.leading, .trailing], 20)
            .padding([.top, .bottom], 8)
    }
    
    private func delete() {
        modelContext.delete(revenue)
        navigationStore.pop()
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        RevenueView(revenue: .init(payer: "RMCI", amount: .Cents(245012), category: "Paycheck", notes: "Test"))
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
