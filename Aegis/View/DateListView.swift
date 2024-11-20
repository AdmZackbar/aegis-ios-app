//
//  DateListView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/12/24.
//

import SwiftData
import SwiftUI

struct DateListView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    @Binding private var path: [ViewType]
    
    init(path: Binding<[ViewType]>) {
        self._path = path
    }
    
    var body: some View {
        let map: [Int : [Int : [Expense]]] = {
            var map: [Int : [Int : [Expense]]] = [:]
            for expense in expenses {
                map[Calendar.current.component(.year, from: expense.date), default: [:]][Calendar.current.component(.month, from: expense.date), default: []].append(expense)
            }
            return map
        }()
        Form {
            ForEach(map.sorted { $0.key > $1.key }, id: \.key.hashValue, content: yearView)
        }.navigationTitle("By Date")
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
    
    @ViewBuilder
    private func yearView(year: Int, map: [Int : [Expense]]) -> some View {
        Section("\(year.formatted(.number.grouping(.never)))") {
            ForEach(map.sorted { $0.key > $1.key }, id: \.key.hashValue) {
                monthButton(month: $0, expenses: $1, year: year)
            }
        }
    }
    
    @ViewBuilder
    private func monthButton(month: Int, expenses: [Expense], year: Int) -> some View {
        let m = DateFormatter().monthSymbols[month - 1]
        Button {
            path.append(.ListByMonth(month: month, year: year))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(m).font(.headline)
                HStack {
                    Text("\(expenses.count) expenses")
                    Spacer()
                    Text("\(expenses.map({ $0.amount }).reduce(Price.Cents(0), +).toString())")
                }.font(.subheadline).italic()
            }.contentShape(Rectangle())
                .frame(height: 48)
        }.buttonStyle(.plain)
    }
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    return NavigationStack {
        DateListView(path: .constant([]))
    }.modelContainer(container)
}
