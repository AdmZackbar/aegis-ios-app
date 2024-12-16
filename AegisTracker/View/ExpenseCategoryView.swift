//
//  ExpenseCategoryView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/15/24.
//

import Charts
import SwiftData
import SwiftUI

private extension Date {
    var year: Int {
        get {
            Calendar.current.component(.year, from: self)
        }
    }
    var yearStr: String {
        get {
            year.formatted(.number.grouping(.never))
        }
    }
    var month: Int {
        get {
            Calendar.current.component(.month, from: self)
        }
    }
    var monthStr: String {
        get {
            Calendar.current.monthSymbols[month - 1]
        }
    }
}

// Lists all categories
struct ExpenseCategoryListView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    @State private var searchText: String = ""
    
    var body: some View {
        let map: [String : [Expense]] = {
            var map: [String : [Expense]] = [:]
            expenses.forEach({ map[$0.category, default: []].append($0) })
            return map
        }()
        Form {
            ForEach(map.filter({ isFiltered($0.key) })
                .sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { category, expenses in
                    createButton(map: map, category: category)
                }
        }.navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
    }
    
    @ViewBuilder
    private func createButton(map: [String: [Expense]], category: String) -> some View {
        Button {
            navigationStore.push(ViewType.category(name: category))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(category).font(.headline)
                HStack {
                    Text("\(map[category, default: []].count) expenses")
                    Spacer()
                    Text(map[category, default: []].map({ $0.amount }).reduce(Price.Cents(0), +).toString())
                }.font(.subheadline).italic()
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    
    private func isFiltered(_ name: String) -> Bool {
        searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
    }
}

// Shows specific categories
struct ExpenseCategoryView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    private var category: String
    
    @State private var searchText: String = ""
    @State private var showEditAlert: Bool = false
    @State private var editName: String = ""
    @State private var year: Int? = nil
    @State private var chartSelection: Date? = nil
    
    init(category: String) {
        self.category = category
    }
    
    var body: some View {
        let yearMap: [Int : [Expense]] = {
            var map: [Int : [Expense]] = [:]
            expenses.filter({ $0.category == category && isFiltered($0) })
                .forEach({ map[$0.date.year, default: []].append($0) })
            return map
        }()
        TabView(selection: $year) {
            // This skips years with no entries, which could be good or bad
            ForEach(yearMap.sorted(by: { $0.key < $1.key }), id: \.key) { y, e in
                sectionView(expenses: e, year: y)
                    .tag(y as Int?)
            }
            sectionView(expenses: expenses.filter({ $0.category == category && isFiltered($0) }), year: nil)
                .tag(nil as Int?)
        }.navigationTitle(category)
            .navigationBarTitleDisplayMode(.inline)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.init(uiColor: UIColor.systemGroupedBackground))
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.push(RecordType.addExpense)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        editName = category
                        showEditAlert = true
                    } label: {
                        Label("Change Category Name...", systemImage: "pencil.circle")
                    }
                }
            }
            .alert("Edit category name", isPresented: $showEditAlert) {
                TextField("New Name", text: $editName)
                Button("Cancel") {
                    showEditAlert = false
                }
                Button("Save", action: updateAllCategoryNames)
                    .disabled(editName.isEmpty)
            } message: {
                Text("This will update all expenses")
            }
    }
    
    @ViewBuilder
    private func byMonthBarChart(expenses: [Expense], year: Int) -> some View {
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
                .foregroundStyle(chartSelection == nil || item.date.month == chartSelection!.month ? .accent : .gray)
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
            .chartXSelection(value: $chartSelection)
    }
    
    @ViewBuilder
    private func byYearBarChart(expenses: [Expense]) -> some View {
        Chart(expenses.map({ (date: $0.date, amount: $0.amount.toUsd()) }), id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .year), y: .value("Amount", item.amount))
                .cornerRadius(4)
                .foregroundStyle(chartSelection == nil || item.date.year == chartSelection!.year ? .accent : .gray)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .year)) { date in
                AxisValueLabel(format: .dateTime.year(), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)),
                      values: .automatic(desiredCount: 4))
        }
        .chartXSelection(value: $chartSelection)
    }
    
    @ViewBuilder
    private func sectionView(expenses: [Expense], year: Int?) -> some View {
        Form {
            Section {
                if expenses.isEmpty {
                    Text("No Filtered Entries")
                        .font(.title3)
                        .bold()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        chartHeader(expenses)
                        if let year {
                            byMonthBarChart(expenses: expenses, year: year)
                                .frame(height: 100)
                        } else {
                            byYearBarChart(expenses: expenses)
                                .frame(height: 100)
                        }
                    }
                }
            } header: {
                Text(sectionHeader(year))
                    .font(.system(size: 40))
                    .fontWeight(.heavy)
                    .fontDesign(.rounded)
            }.headerProminence(.increased)
            if !expenses.isEmpty {
                Section("\(expenses.count) Expenses") {
                    ExpenseListView(expenses: expenses, omitted: [.Category], allowSwipeActions: false)
                }
            }
        }.scrollContentBackground(.hidden)
    }
    
    @ViewBuilder
    private func chartHeader(_ expenses: [Expense]) -> some View {
        HStack(alignment: .bottom) {
            Text(expenses.map({ $0.amount }).reduce(.Cents(0), +).toString())
                .font(.title)
                .fontWeight(.bold)
                .fontDesign(.rounded)
            Spacer()
            if let date = chartSelection {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(year != nil ? date.monthStr.uppercased() : date.yearStr)
                        .font(.caption)
                        .fontWeight(.light)
                    Text((year != nil ? computeMonthAmount(expenses, month: date.month) : computeYearAmount(expenses, year: date.year)).toString())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func sectionHeader(_ year: Int?) -> String {
        if let year {
            return year.formatted(.number.grouping(.never))
        }
        return "All"
    }
    
    private func computeMonthAmount(_ expenses: [Expense], month: Int) -> Price {
        return expenses.filter({ month == $0.date.month })
            .map({ $0.amount })
            .reduce(.Cents(0), +)
    }
    
    private func computeYearAmount(_ expenses: [Expense], year: Int) -> Price {
        return expenses.filter({ year == $0.date.year })
            .map({ $0.amount })
            .reduce(.Cents(0), +)
    }
    
    private func isFiltered(_ expense: Expense) -> Bool {
        searchText.isEmpty ||
        isFiltered(expense.payee) ||
        isFiltered(expense.notes) ||
        isDetailFiltered(expense.details)
    }
    
    private func isDetailFiltered(_ details: Expense.Details?) -> Bool {
        switch details {
        case .Items(let list):
            return list.items.contains(where: { isFiltered($0.name) ||
                isFiltered($0.brand) })
        case .Bill(let details):
            return details.bills.contains(where: { isFiltered($0.getName()) })
        case .Fuel(let details):
            return isFiltered(details.user)
        default:
            return false
        }
    }
    
    private func isFiltered(_ str: String) -> Bool {
        str.localizedCaseInsensitiveContains(searchText)
    }
    
    private func updateAllCategoryNames() {
        expenses.filter({ $0.category == category }).forEach({ $0.category = editName })
        try? modelContext.save()
        navigationStore.replace(ViewType.category(name: editName))
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        ExpenseCategoryView(category: "Gas")
            .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
