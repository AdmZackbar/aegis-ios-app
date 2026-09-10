//
//  SubscriptionListView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import SwiftData
import SwiftUI

struct SubscriptionListView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Subscription.payee) var subscriptions: [Subscription]
    
    var body: some View {
        Form {
            Section("Active") {
                ForEach(subscriptions.filter({ $0.latestPeriod?.endDate == nil }), id: \.hashValue) {
                    subEntryView($0)
                }
            }
            Section("Inactive") {
                ForEach(subscriptions.filter({ $0.latestPeriod?.endDate != nil }), id: \.hashValue) {
                    subEntryView($0)
                }
            }
        }.navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        navigationStore.push(ExpenseViewType.addSub())
                    } label: {
                        Label("Add New", systemImage: "plus")
                    }
                    Menu {
                        Button("Merge Expenses to Subscriptions") {
                            navigationStore.push(ExpenseViewType.merge)
                        }
                    } label: {
                        Label("Helpers", systemImage: "wrench.adjustable")
                    }
                }
            }
    }
    
    @ViewBuilder
    func subEntryView(_ sub: Subscription) -> some View {
        if let period = sub.latestPeriod {
            Button {
                navigationStore.push(ExpenseViewType.viewSub(subscription: sub))
            } label: {
                VStack(alignment: .leading) {
                    HStack {
                        Text(sub.payee)
                        Spacer()
                        Text(period.amount.toString())
                    }.font(.title3)
                        .bold()
                    HStack {
                        Text(sub.category)
                        Spacer()
                        Text(period.type.text)
                    }.font(.subheadline)
                        .italic()
                    if !sub.notes.isEmpty {
                        Text(sub.notes)
                            .font(.subheadline)
                    }
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
        } else {
            Button {
                navigationStore.push(ExpenseViewType.viewSub(subscription: sub))
            } label: {
                HStack {
                    Text(sub.payee)
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        SubscriptionListView()
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
