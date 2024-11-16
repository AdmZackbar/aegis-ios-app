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
    @Query(sort: \Expense.category) var expenses: [Expense]
    
    @Binding private var path: [ViewType]
    
    init(path: Binding<[ViewType]>) {
        self._path = path
    }
    
    var body: some View {
        let map = {
            var map: [Date: [Expense]] = [:]
            for expense in expenses {
                map[Calendar.current.startOfDay(for: expense.date), default: []].append(expense)
            }
            return map
        }()
        Form {
            ForEach(map.sorted(by: { $0.key > $1.key }), id: \.key) { date, expenses in
                Section(date.formatted(date: .long, time: .omitted)) {
                    ExpenseListView(path: $path, expenses: expenses, titleComponents: [.Category])
                }
            }
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
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    return NavigationStack {
        DateListView(path: .constant([]))
    }.modelContainer(container)
}
