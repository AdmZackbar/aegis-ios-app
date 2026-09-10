//
//  MergeExpenseView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import SwiftData
import SwiftUI

struct MergeExpenseView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date) var expenses: [Expense]
    @Query(sort: \Subscription.payee) var subs: [Subscription]
    
    @State private var loading: Bool = false
    @State private var data: [Key : [Expense]] = [:]
    @State private var mergeKey: Key? = nil
    
    var body: some View {
        Form {
            if loading {
                Text("Loading Data...")
            } else if data.isEmpty {
                Text("No Duplicate Expenses Found")
            } else {
                Section("Expenses") {
                    ForEach(data.keys.sorted(by: { $0.payee < $1.payee }), id: \.hashValue) { key in
                        Button("\(key.text): \(data[key]!.count) expenses") {
                            mergeKey = key
                        }
                    }
                }
            }
            if !subs.isEmpty {
                Section("Subscriptions") {
                    ForEach(subs, id: \.id) { s in
                        Button("\(s.payee) \(s.category)") {
                            navigationStore.push(ExpenseViewType.viewSub(subscription: s))
                        }
                    }
                }
            }
        }.navigationTitle("Subscription Conversion")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadData)
            .onChange(of: expenses, loadData)
            .alert("Merge Expenses?", isPresented: .init(get: {
                mergeKey != nil
            }, set: { newValue in
                if !newValue {
                    mergeKey = nil
                }
            })) {
                Button("Merge") {
                    if let mergeKey {
                        merge(key: mergeKey, expenses: data[mergeKey, default: []])
                    }
                    mergeKey = nil
                }
                Button("Cancel") {
                    mergeKey = nil
                }
            }
    }
    
    func loadData() {
        loading = true
        data = .init(grouping: expenses, by: { Key(payee: $0.payee, category: $0.category, notes: $0.notes, details: $0.details) })
            .filter({ $0.value.count > 1 })
        loading = false
    }
    
    func merge(key: Key, expenses: [Expense]) {
        guard !expenses.isEmpty else { return }
        var periods: [Subscription.Period] = []
        var period: Subscription.Period? = nil
        for expense in expenses {
            if period != nil {
                if expense.amount != period!.amount {
                    period!.endDate = expense.date.addDays(-1)
                    periods.append(period!)
                    period = .init(startDate: expense.date, type: .monthly, amount: expense.amount)
                } else {
                    period!.endDate = expense.date.addMonths(1)
                }
            } else {
                period = .init(startDate: expense.date, type: .monthly, amount: expense.amount)
            }
        }
        if let period {
            periods.append(period)
        }
        if !periods.isEmpty {
            let sub = Subscription(payee: key.payee, category: key.category, notes: key.toNotes(), periods: periods)
            modelContext.insert(sub)
            for expense in expenses {
                modelContext.delete(expense)
            }
            navigationStore.push(ExpenseViewType.viewSub(subscription: sub))
        }
    }
    
    struct Key: Hashable, Equatable {
        var payee: String
        var category: String
        var notes: String
        var details: Expense.Details?
        
        init(payee: String, category: String, notes: String, details: Expense.Details?) {
            self.payee = payee
            self.category = category
            self.notes = notes
            self.details = details
        }
        
        var text: String {
            "\(payee) (\(category))"
        }
        
        func toNotes() -> String {
            if !notes.isEmpty {
                return notes
            }
            switch details {
            case .Items(let list):
                return list.items.map({ "\($0.name) \($0.total.toString())" }).joined(separator: "\n")
            default:
                return ""
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        MergeExpenseView().navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
