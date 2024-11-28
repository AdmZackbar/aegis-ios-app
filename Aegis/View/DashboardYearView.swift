//
//  DashboardYearView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/21/24.
//

import Charts
import SwiftData
import SwiftUI

struct DashboardYearView: View {
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    @Binding private var path: [ViewType]
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var viewType: ListViewType = .Category
    
    init(path: Binding<[ViewType]>) {
        self._path = path
    }
    
    var body: some View {
        let yearMap: [Int : [Int : [Expense]]] = {
            var map: [Int : [Int : [Expense]]] = [:]
            expenses.forEach({ map[Calendar.current.component(.year, from: $0.date), default: [:]][Calendar.current.component(.month, from: $0.date), default: []].append($0) })
            return map
        }()
        TabView(selection: $selectedYear) {
            ForEach(yearMap.sorted(by: { $0.key < $1.key }), id: \.key) { year, monthMap in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(year.formatted(.number.grouping(.never)))").font(.system(size: 40.0, weight: .heavy))
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Expenses").font(.caption).italic().opacity(0.7)
                                Text(monthMap.values.flatMap { $0 }.map({ $0.amount }).reduce(Price.Cents(0), +).toString()).font(.title2).fontWeight(.semibold)
                                yearBarChart(year: year, map: monthMap)
                                    .frame(height: 140)
                            }
                            Spacer()
                        }.padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        categoryChart(year: year, expenses: monthMap.values.flatMap { $0 })
                            .frame(height: 140)
                            .padding()
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        bottomView()
                        Spacer()
                    }.padding()
                }.tag(year)
            }
        }.tabViewStyle(.page)
    }
    
    @ViewBuilder
    private func yearBarChart(year: Int, map: [Int : [Expense]]) -> some View {
        let categoryMap: [String : String] = {
            var map: [String : String] = [:]
            MainView.ExpenseCategories.forEach({ header, categories in categories.forEach({ category in map[category] = header }) })
            return map
        }()
        let expenses = map.values.flatMap { $0 }
        let d = expenses.sorted(by: { $0.category < $1.category })
            .map({ (date: $0.date, amount: $0.amount.toUsd(), category: categoryMap[$0.category, default: $0.category]) })
        let start: Date = {
            var c = DateComponents()
            c.year = year
            c.month = 1
            return Calendar.current.date(from: c)!
        }()
        let end: Date = {
            var c = DateComponents()
            c.year = year + 1
            c.month = 1
            return Calendar.current.date(from: c)!
        }()
        Chart(d, id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .month), y: .value("Amount", item.amount))
                .foregroundStyle(by: .value("Category", item.category))
                .cornerRadius(4)
        }.chartXScale(domain: start...end)
            .chartForegroundStyleScale { category in
                MainView.ExpenseCategoryColors[category] ?? .black
            }.chartLegend(.hidden)
    }
    
    @ViewBuilder
    private func categoryChart(year: Int, expenses: [Expense]) -> some View {
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
        let total = data.map({ $0.value }).reduce(0, +)
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
                    }
                }
            }
    }
    
    @ViewBuilder
    private func bottomView() -> some View {
        Picker("", selection: $viewType) {
            ForEach(ListViewType.allCases, id: \.rawValue) { type in
                Text(type.rawValue).tag(type)
            }
        }.pickerStyle(.segmented)
        switch viewType {
        case .Category:
            categoryView()
        case .Date:
            // TODO
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func categoryView() -> some View {
        VStack(spacing: 16) {
            ForEach(MainView.ExpenseCategories.sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { header, categories in
                Button {
                    path.append(.ListByCategory(category: header))
                } label: {
                    // TODO
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(header).font(.headline)
                            Text("0 expenses").font(.subheadline).italic()
                        }
                        Spacer()
                        Text("$0").bold()
                    }.contentShape(RoundedRectangle(cornerRadius: 4))
                        .padding()
                        .background(.secondary.opacity(0.1))
                }.buttonStyle(.plain)
            }
        }
    }
    
    private enum ListViewType: String, CaseIterable {
        case Category
        case Date
    }
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    return NavigationStack {
        DashboardYearView(path: .constant([]))
    }.modelContainer(container)
}
