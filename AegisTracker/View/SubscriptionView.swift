//
//  SubscriptionView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import SwiftUI

struct SubscriptionView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    let subscription: Subscription
   
    @State private var showDelete: Bool = false
    
    init(subscription: Subscription) {
        self.subscription = subscription
    }
    
    var body: some View {
        VStack(spacing: 4) {
            headerView()
            Form {
                detailView()
            }.scrollContentBackground(.hidden)
            footerActionsView()
        }.navigationTitle("View Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.init(uiColor: UIColor.systemGroupedBackground))
            .confirmationDialog("Are you sure you want to delete this subscription?", isPresented: $showDelete) {
                Button("Delete", role: .destructive, action: delete)
            } message: {
                Text("You cannot undo this action")
            }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        if let latestPeriod = subscription.latestPeriod, latestPeriod.endDate == nil {
            Text(latestPeriod.amount.toString())
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text(latestPeriod.type.text)
                .font(.title3)
                .fontWeight(.semibold)
            Text("\(latestPeriod.startDate.formatted(date: .abbreviated, time: .omitted)) - Present")
                .italic()
            if !latestPeriod.notes.isEmpty {
                Text(latestPeriod.notes)
                    .font(.subheadline)
                    .lineLimit(5)
            }
        }
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(subscription.category)
                Spacer()
                Text("All Time")
            }.textCase(.uppercase)
                .font(.caption)
                .fontWeight(.light)
            HStack {
                Text(subscription.payee)
                    .multilineTextAlignment(.leading)
                Spacer()
                Text(subscription.periods.map({ $0.total }).reduce(.zero, +).toString())
            }.font(.title2)
                .bold()
            if !subscription.notes.isEmpty {
                Text(subscription.notes)
                    .font(.subheadline)
                    .lineLimit(5)
            }
        }.padding([.leading, .trailing], 28)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    @ViewBuilder
    func detailView() -> some View {
        let sorted = subscription.periods.sorted(by: { $0.startDate > $1.startDate })
        let periods = subscription.latestPeriod?.endDate == nil ? sorted.filter({ $0 != subscription.latestPeriod }) : sorted
        ForEach(periods, id: \.hashValue) { period in
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(period.type.text)
                                .font(.subheadline)
                                .italic()
                            Text(period.amount.toString())
                                .bold()
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Total")
                                .font(.subheadline)
                                .italic()
                            Text(period.total.toString())
                                .bold()
                        }
                    }
                    if !period.notes.isEmpty {
                        Text(period.notes)
                            .font(.subheadline)
                    }
                }
            } header: {
                HStack {
                    Text(period.startDate.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                    Text(period.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "Present")
                }
            }
        }
    }
    
    @ViewBuilder
    private func footerActionsView() -> some View {
        Grid {
            GridRow {
                Button {
                    navigationStore.push(ExpenseViewType.editSub(subscription: subscription))
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
        modelContext.delete(subscription)
        navigationStore.pop()
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    let date = Date()
    return NavigationStack(path: $navigationStore.path) {
        SubscriptionView(subscription: .init(payee: "Verizon", category: "Phone Bill", notes: "Test", periods: [
            .init(startDate: date.addYears(-2)!, endDate: date.addYears(-1)!, amount: .Cents(6501), notes: "initial plan"),
            .init(startDate: date.addYears(-1)!, amount: .Cents(7201), notes: "inflations a bitch")
        ])).navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
    
}
