//
//  MonthListView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/20/24.
//

import SwiftData
import SwiftUI

struct MonthListView: View {
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    @Binding private var path: [ViewType]
    
    let month: Int
    let year: Int
    
    init(path: Binding<[ViewType]>, month: Int, year: Int) {
        self._path = path
        self.month = month
        self.year = year
    }
    
    var body: some View {
        let map: [Date : [Expense]] = {
            var map: [Date : [Expense]] = [:]
            expenses.filter(validExpense)
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
                    ExpenseListView(path: $path, expenses: expenses, titleComponents: [.Category])
                }
            }
        }.navigationTitle("\(DateFormatter().monthSymbols[month - 1]) \(year.formatted(.number.grouping(.never)))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        path.append(.AddExpense)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
    }
    
    private func validExpense(expense: Expense) -> Bool {
        let m = Calendar.current.component(.month, from: expense.date)
        let y = Calendar.current.component(.year, from: expense.date)
        return self.month == m && self.year == y
    }
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    let m = Calendar.current.component(.month, from: .now)
    let y = Calendar.current.component(.year, from: .now)
    return NavigationStack {
        MonthListView(path: .constant([]), month: m, year: y)
    }.modelContainer(container)
}
