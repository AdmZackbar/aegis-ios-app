//
//  MonthListView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/20/24.
//

import SwiftData
import SwiftUI

struct MonthListView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    let month: Int
    let year: Int
    
    init(month: Int, year: Int) {
        self.month = month
        self.year = year
    }
    
    var body: some View {
        let map: [Date : [Expense]] = {
            var map: [Date : [Expense]] = [:]
            expenses.filter({ isValid($0) })
                .sorted(by: { $0.category < $1.category })
                .sorted(by: { $0.date > $1.date })
                .forEach({ map[Calendar.current.startOfDay(for: $0.date), default: []].append($0) })
            return map
        }()
        let dayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter
        }()
        Form {
            ForEach(map.sorted(by: { $0.key > $1.key }), id: \.key.hashValue) { day, expenses in
                Section(dayFormatter.string(for: day)!) {
                    ExpenseListView(expenses: expenses, omitted: [.Date])
                }
            }
        }.navigationTitle("\(DateFormatter().monthSymbols[month - 1]) \(year.formatted(.number.grouping(.never)))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.path.append(RecordType.addExpense())
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
    }
    
    private func isValid(_ expense: Expense) -> Bool {
        let m = Calendar.current.component(.month, from: expense.date)
        let y = Calendar.current.component(.year, from: expense.date)
        return self.month == m && self.year == y
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    let m = Calendar.current.component(.month, from: .now)
    let y = Calendar.current.component(.year, from: .now)
    return NavigationStack(path: $navigationStore.path) {
        MonthListView(month: m, year: y)
            .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
