//
//  DateListView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/12/24.
//

import Charts
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
            .contextMenu {
                Button("View") {
                    path.append(.ListByMonth(month: month, year: year))
                }
            } preview: {
                monthPreview(month: month, expenses: expenses, year: year)
            }
    }
    
    @ViewBuilder
    private func monthPreview(month: Int, expenses: [Expense], year: Int) -> some View {
        let categoryMap: [String : String] = {
            var map: [String : String] = [:]
            MainView.ExpenseCategories.forEach({ header, categories in categories.forEach({ category in map[category] = header }) })
            return map
        }()
        let map: [String : [Expense]] = {
            var map: [String : [Expense]] = [:]
            for expense in expenses {
                map[categoryMap[expense.category, default: expense.category], default: []].append(expense)
            }
            return map
        }()
        let data = map.compactMap({ (name: $0, value: $1.map({ $0.amount }).reduce(Price.Cents(0), +).toUsd()) })
            .sorted(by: { $0.value > $1.value })
        let m = DateFormatter().monthSymbols[month - 1]
        let total = data.map({ $0.value }).reduce(0, +)
        VStack {
            Text("\(m) \(year.formatted(.number.grouping(.never)))")
                .font(.title2)
                .bold()
            Chart(data, id: \.name) { name, totals in
                SectorMark(
                    angle: .value("Value", totals),
                    innerRadius: .ratio(0.68),
                    outerRadius: .ratio(1.0),
                    angularInset: 1
                ).cornerRadius(4)
                    .foregroundStyle(by: .value("Category", name))
            }.chartForegroundStyleScale { category in
                MainView.ExpenseCategoryColors[category] ?? .clear
            }.chartLegend(position: .trailing, alignment: .top, spacing: 16)
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let anchor = chartProxy.plotFrame {
                            let frame = geometry[anchor]
                            Text("\(total.formatted(.currency(code: "USD")))")
                                .position(x: frame.midX, y: frame.midY)
                                .italic()
                        }
                    }
                }
        }.frame(width: 300, height: 220).padding()
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NavigationStack {
        DateListView(path: .constant([]))
    }
}
