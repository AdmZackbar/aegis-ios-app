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
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
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
                        navigationStore.path.append(RecordType.addExpense())
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
            navigationStore.path.append(ViewType.month(year: year, month: month))
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
                    navigationStore.path.append(ViewType.month(year: year, month: month))
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
    return NavigationStack(path: $navigationStore.path) {
        DateListView()
            .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
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
