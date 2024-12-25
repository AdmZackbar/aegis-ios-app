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
    @State private var chartSelection: Date? = nil
    
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
                        navigationStore.push(ExpenseViewType.add())
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
                    FinanceMonthChart(data: monthExpenses.map(Expense.toFinanceData), year: year, month: month, selection: $chartSelection)
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
                            Text(chartSelection == nil ? "Total Spending" : chartSelection!.month.monthText())
                                .font(.subheadline)
                                .opacity(0.6)
                            Text(yearExpenses.filter({ chartSelection == nil || $0.date.month == chartSelection!.month }).total.toString())
                                .font(.title)
                                .fontWeight(.bold)
                                .fontDesign(.rounded)
                        }
                        FinanceYearChart(data: yearExpenses.map(Expense.toFinanceData), year: year, selection: $chartSelection)
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
    private func monthButton(year: Int, month: Int, expenses: [Expense]) -> some View {
        let m = DateFormatter().monthSymbols[month - 1]
        Button {
            navigationStore.push(ExpenseViewType.byMonth(year: year, month: month))
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
                    navigationStore.push(ExpenseViewType.byMonth(year: year, month: month))
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
    
    @State private var chartSelection: Date? = nil
    
    let year: Int
    let month: Int
    
    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
    
    var body: some View {
        let expenses = expenses.filter({ $0.date.month == month && $0.date.year == year })
        let map: [Date : [Expense]] = {
            var map: [Date : [Expense]] = [:]
            expenses.sorted(by: { $0.category < $1.category })
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
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Total Spending")
                            .font(.subheadline)
                            .opacity(0.6)
                        Text(expenses.total.toString())
                            .font(.title)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                    }
                    FinanceMonthChart(data: expenses.map(Expense.toFinanceData), year: year, month: month, selection: $chartSelection)
                        .frame(height: 140)
                }
            }
            ForEach(map.sorted(by: { $0.key > $1.key }), id: \.key.hashValue) { day, expenses in
                Section(dayFormatter.string(for: day)!) {
                    ExpenseListView(expenses: expenses, omitted: [.Date])
                }
            }
        }.navigationTitle("\(month.monthText()) \(year.yearText())")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.push(ExpenseViewType.add())
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
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
