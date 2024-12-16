//
//  ExpenseCategoryView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/15/24.
//

import Charts
import SwiftData
import SwiftUI

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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.push(RecordType.addExpense)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
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
    
    init(category: String) {
        self.category = category
    }
    
    var body: some View {
        let yearMap: [Int : [Expense]] = {
            var map: [Int : [Expense]] = [:]
            expenses.filter({ $0.category == category })
                .forEach({ map[Calendar.current.component(.year, from: $0.date), default: []].append($0) })
            return map
        }()
        TabView(selection: $year) {
            // This skips years with no entries, which could be good or bad
            ForEach(yearMap.sorted(by: { $0.key < $1.key }), id: \.key) { y, e in
                sectionView(expenses: e, year: y)
                    .tag(y as Int?)
            }
            sectionView(expenses: expenses.filter({ $0.category == category }), year: nil)
                .tag(nil as Int?)
        }.navigationTitle(category)
            .navigationBarTitleDisplayMode(.inline)
            .tabViewStyle(.page)
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
                        showEditAlert = true
                    } label: {
                        Label("Change Category Name...", systemImage: "pencil.circle")
                    }
                }
            }
            .alert("Edit category name", isPresented: $showEditAlert) {
                TextField("New Name", text: $editName)
                Button("OK", action: changeName).disabled(editName.isEmpty)
                Button("Cancel") {
                    showEditAlert = false
                }
            }
    }
    
    @ViewBuilder
    private func yearBarChart(expenses: [Expense], year: Int) -> some View {
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
        Chart(expenses.map({ (date: $0.date, amount: $0.amount.toUsd()) }), id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .month), y: .value("Amount", item.amount))
                .cornerRadius(4)
        }.chartXScale(domain: start...end)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { date in
                    AxisValueLabel(format: .dateTime.month(), centered: true)
                }
            }.chartYAxis {
                AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)),
                          values: .automatic(desiredCount: 4))
            }
    }
    
    @ViewBuilder
    private func allBarChart(expenses: [Expense]) -> some View {
        Chart(expenses.map({ (date: $0.date, amount: $0.amount.toUsd()) }), id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .year), y: .value("Amount", item.amount))
                .cornerRadius(4)
        }.chartXAxis {
            AxisMarks(values: .stride(by: .year)) { date in
                AxisValueLabel(format: .dateTime.year(), centered: true)
            }
        }.chartYAxis {
            AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)),
                      values: .automatic(desiredCount: 4))
        }
    }
    
    @ViewBuilder
    private func sectionView(expenses: [Expense], year: Int?) -> some View {
        let filteredExpenses = expenses.filter({ isFiltered($0) })
        Form {
            Section {
                if filteredExpenses.isEmpty {
                    Text("No Filtered Entries")
                        .font(.title3)
                        .bold()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(filteredExpenses.map({ $0.amount }).reduce(.Cents(0), +).toString())
                                .font(.title2)
                                .fontWeight(.bold)
                                .fontDesign(.rounded)
                            Spacer()
                        }
                        if let year {
                            yearBarChart(expenses: filteredExpenses.filter({ isFiltered($0) }), year: year)
                                .frame(height: 100)
                        } else {
                            allBarChart(expenses: filteredExpenses.filter({ isFiltered($0) }))
                                .frame(height: 100)
                        }
                    }
                }
            } header: {
                if let year {
                    Text(year.formatted(.number.grouping(.never)))
                        .font(.system(size: 40)).fontWeight(.heavy).fontDesign(.rounded)
                } else {
                    Text("All")
                        .font(.system(size: 40)).fontWeight(.heavy).fontDesign(.rounded)
                }
            }.headerProminence(.increased)
            if !filteredExpenses.isEmpty {
                Section("\(filteredExpenses.count) Expenses") {
                    ExpenseListView(expenses: filteredExpenses.filter({ isFiltered($0) }), omitted: [.Category])
                }
            }
        }.scrollContentBackground(.hidden)
    }
    
    private func changeName() {
        expenses.filter({ $0.category == category }).forEach({ $0.category = editName })
        try? modelContext.save()
        navigationStore.replace(ViewType.category(name: editName))
    }
    
    private func isFiltered(_ expense: Expense) -> Bool {
        searchText.isEmpty ||
        expense.payee.localizedCaseInsensitiveContains(searchText) ||
        expense.notes.localizedCaseInsensitiveContains(searchText) ||
        isDetailFiltered(expense.details)
    }
    
    private func isDetailFiltered(_ details: Expense.Details?) -> Bool {
        switch details {
        case .Items(let list):
            return list.items.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText) })
        case .Bill(let details):
            return details.bills.contains(where: { $0.getName().localizedCaseInsensitiveContains(searchText) })
        case .Fuel(let details):
            return details.user.localizedCaseInsensitiveContains(searchText)
        default:
            return false
        }
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
