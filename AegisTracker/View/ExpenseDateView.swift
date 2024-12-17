//
//  ExpenseDateView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/16/24.
//

import Charts
import SwiftData
import SwiftUI

struct ExpenseDateView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    @State private var dateType: DateType = .Year
    @State private var monthSelection: DateTag? = nil
    @State private var yearSelection: Int? = nil
    
    var body: some View {
        mainView()
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.init(uiColor: UIColor.systemGroupedBackground))
            .onAppear {
                if let date = expenses.map({ $0.date }).max() {
                    monthSelection = DateTag(year: date.year, month: date.month)
                    yearSelection = date.year
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $dateType) {
                        ForEach(DateType.allCases, id: \.hashValue) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }.pickerStyle(.segmented)
                        .frame(width: 150)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.push(RecordType.addExpense())
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
    }
    
    @ViewBuilder
    private func mainView() -> some View {
        switch dateType {
        case .Month:
            TabView(selection: $monthSelection) {
                byMonthView()
            }
        case .Year:
            TabView(selection: $yearSelection) {
                byYearView()
            }
        }
    }
    
    @ViewBuilder
    private func byMonthView() -> some View {
        let map: [Int : [Int : [Expense]]] = {
            var map: [Int : [Int : [Expense]]] = [:]
            expenses.forEach({ map[$0.date.year, default: [:]][$0.date.month, default: []].append($0) })
            return map
        }()
        ForEach(map.sorted(by: { $0.key < $1.key }), id: \.key) { year, yearMap in
            ForEach(yearMap.sorted(by: { $0.key < $1.key }), id: \.key) { month, monthExpenses in
                monthView(year: year, month: month, monthExpenses: monthExpenses)
                    .tag(DateTag(year: year, month: month))
            }
        }
    }
    
    @ViewBuilder
    private func monthView(year: Int, month: Int, monthExpenses: [Expense]) -> some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Total Spending")
                            .font(.subheadline)
                            .opacity(0.6)
                        Text(monthExpenses.total.toString())
                            .font(.title)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                    }
                    byMonthChart(year: year, month: month, expenses: monthExpenses)
                        .frame(height: 140)
                }
            } header: {
                Text("\(month.monthText()) \(year.yearText())")
                    .font(.title)
                    .bold()
            }.headerProminence(.increased)
            let dayMap: [Int : [Expense]] = {
                var map: [Int : [Expense]] = [:]
                monthExpenses.forEach({ map[$0.date.day, default: []].append($0) })
                return map
            }()
            ForEach(dayMap.sorted(by: { $0.key > $1.key }), id: \.key) { day, dayExpenses in
                Section("\(month.monthText()) \(day)") {
                    ExpenseListView(expenses: dayExpenses, omitted: [.Date], allowSwipeActions: false)
                }
            }
        }.scrollContentBackground(.hidden)
    }
    
    @ViewBuilder
    private func byMonthChart(year: Int, month: Int, expenses: [Expense]) -> some View {
        Chart(expenses.map({ (date: $0.date, amount: $0.amount.toUsd()) }), id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .day), y: .value("Amount", item.amount))
                .cornerRadius(4)
        }.chartXScale(domain: createDate(year: year, month: month, day: 1)...createDate(year: year, month: month, day: Calendar.current.range(of: .day, in: .month, for: createDate(year: year, month: month))?.upperBound))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { date in
                    if date.index % 4 == 0 {
                        AxisValueLabel(format: .dateTime.day(), centered: true)
                    }
                    if date.index % 2 == 0 {
                        AxisGridLine()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)),
                          values: .automatic(desiredCount: 4))
            }
    }
    
    private func createDate(year: Int, month: Int = 12, day: Int? = nil) -> Date {
        return {
            var d = DateComponents()
            d.year = year
            d.month = month
            d.day = day
            return Calendar.current.date(from: d)!
        }()
    }
    
    @ViewBuilder
    private func byYearView() -> some View {
        let map: [Int : [Expense]] = {
            var map: [Int : [Expense]] = [:]
            expenses.forEach({ map[$0.date.year, default: []].append($0) })
            return map
        }()
        ForEach(map.sorted(by: { $0.key < $1.key }), id: \.key) { year, yearExpenses in
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Total Spending")
                                .font(.subheadline)
                                .opacity(0.6)
                            Text(yearExpenses.total.toString())
                                .font(.title)
                                .fontWeight(.bold)
                                .fontDesign(.rounded)
                        }
                        byYearBarChart(expenses: yearExpenses, year: year)
                            .frame(height: 140)
                    }
                } header: {
                    Text(year.formatted(.number.grouping(.never)))
                        .font(.title)
                        .bold()
                }.headerProminence(.increased)
                let monthMap: [Int : [Expense]] = {
                    var map: [Int : [Expense]] = [:]
                    yearExpenses.forEach({ map[$0.date.month, default: []].append($0) })
                    return map
                }()
                Section("Expenses") {
                    ForEach(monthMap.sorted { $0.key > $1.key }, id: \.key.hashValue) { month, monthExpenses in
                        monthButton(year: year, month: month, expenses: monthExpenses)
                    }
                }
            }.tag(year)
                .scrollContentBackground(.hidden)
        }
    }
    
    @ViewBuilder
    private func byYearBarChart(expenses: [Expense], year: Int) -> some View {
        let domain = {
            var start = DateComponents()
            start.year = year
            start.month = 1
            var end = DateComponents()
            end.year = year + 1
            end.month = 1
            return Calendar.current.date(from: start)!...Calendar.current.date(from: end)!
        }()
        Chart(expenses.map({ (date: $0.date, amount: $0.amount.toUsd()) }), id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .month), y: .value("Amount", item.amount))
                .cornerRadius(4)
        }.chartXScale(domain: domain)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { date in
                    AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)),
                          values: .automatic(desiredCount: 4))
            }
    }
    
    @ViewBuilder
    private func monthButton(year: Int, month: Int, expenses: [Expense]) -> some View {
        let m = DateFormatter().monthSymbols[month - 1]
        Button {
            navigationStore.push(ViewType.month(year: year, month: month))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(m).font(.headline)
                HStack {
                    Text("\(expenses.count) expenses")
                    Spacer()
                    Text("\(expenses.total.toString())")
                }.font(.subheadline).italic()
            }.contentShape(Rectangle())
                .frame(height: 48)
        }.buttonStyle(.plain)
            .contextMenu {
                Button("View") {
                    navigationStore.push(ViewType.month(year: year, month: month))
                }
            }
    }
    
    enum DateType: String, CaseIterable {
        case Month
        case Year
    }
    
    struct DateTag: Equatable, Hashable {
        let year: Int
        let month: Int?
        
        init(year: Int, month: Int) {
            self.year = year
            self.month = month
        }
    }
}

struct ExpenseMonthView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    let year: Int
    let month: Int
    
    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
    
    var body: some View {
        let map: [Date : [Expense]] = {
            var map: [Date : [Expense]] = [:]
            expenses.filter({ $0.date.month == month && $0.date.year == year })
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
        }.navigationTitle("\(month.monthText()) \(year.yearText())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.push(RecordType.addExpense())
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        ExpenseDateView()
            .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
