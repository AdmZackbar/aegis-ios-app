//
//  RevenuePayerView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/20/24.
//

import Charts
import SwiftData
import SwiftUI

// Lists all payees
struct RevenuePayerListView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Revenue.date, order: .reverse) var revenues: [Revenue]
    
    @State private var searchText: String = ""
    
    var body: some View {
        let map: [String : [Revenue]] = {
            var map: [String : [Revenue]] = [:]
            revenues.forEach({ map[$0.payer, default: []].append($0) })
            return map
        }()
        Form {
            ForEach(map.filter({ isFiltered($0.key) })
                .sorted(by: { $0.key < $1.key }), id: \.key.hashValue) { payer, revenues in
                    createButton(map, payer: payer)
                }
        }.navigationTitle("Select Payer")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
    }
    
    @ViewBuilder
    private func createButton(_ map: [String: [Revenue]], payer: String) -> some View {
        Button {
            navigationStore.push(RevenueViewType.byPayer(name: payer))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(payer).font(.headline)
                HStack {
                    Text("\(map[payer, default: []].count) entries")
                    Spacer()
                    Text(map[payer, default: []].map({ $0.amount }).reduce(Price.Cents(0), +).toString())
                }.font(.subheadline).italic()
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    
    private func isFiltered(_ name: String) -> Bool {
        searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
    }
}

// Shows specific payees
struct RevenuePayerView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Revenue.date, order: .reverse) var revenues: [Revenue]
    
    private var payer: String
    
    @State private var searchText: String = ""
    @State private var showEditAlert: Bool = false
    @State private var editName: String = ""
    @State private var year: Int? = nil
    @State private var chartSelection: Date? = nil
    
    init(payer: String) {
        self.payer = payer
    }
    
    var body: some View {
        let yearMap: [Int : [Revenue]] = {
            var map: [Int : [Revenue]] = [:]
            revenues.filter({ $0.payer == payer && isFiltered($0) })
                .forEach({ map[$0.date.year, default: []].append($0) })
            return map
        }()
        TabView(selection: $year) {
            // This skips years with no entries, which could be good or bad
            ForEach(yearMap.sorted(by: { $0.key < $1.key }), id: \.key) { y, r in
                sectionView(revenues: r, year: y)
                    .tag(y as Int?)
            }
            sectionView(revenues: revenues.filter({ $0.payer == payer && isFiltered($0) }), year: nil)
                .tag(nil as Int?)
        }.navigationTitle(payer)
            .navigationBarTitleDisplayMode(.inline)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.init(uiColor: UIColor.systemGroupedBackground))
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.push(RevenueViewType.add(initial: .init(payer: payer)))
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        editName = payer
                        showEditAlert = true
                    } label: {
                        Label("Change Payer Name...", systemImage: "pencil.circle")
                    }
                }
            }
            .alert("Edit payer name", isPresented: $showEditAlert) {
                TextField("New Name", text: $editName)
                Button("Cancel") {
                    showEditAlert = false
                }
                Button("Save", action: updateAllPayerNames)
                    .disabled(editName.isEmpty)
            } message: {
                Text("This will update all revenues")
            }
    }
    
    @ViewBuilder
    private func byMonthBarChart(revenues: [Revenue], year: Int) -> some View {
        let domain = {
            var start = DateComponents()
            start.year = year
            start.month = 1
            var end = DateComponents()
            end.year = year + 1
            end.month = 1
            return Calendar.current.date(from: start)!...Calendar.current.date(from: end)!
        }()
        Chart(revenues.map({ (date: $0.date, amount: $0.amount.toUsd()) }), id: \.date.hashValue) { item in
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
    private func byYearBarChart(revenues: [Revenue]) -> some View {
        Chart(revenues.map({ (date: $0.date, amount: $0.amount.toUsd()) }), id: \.date.hashValue) { item in
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
    private func sectionView(revenues: [Revenue], year: Int?) -> some View {
        Form {
            Section {
                if revenues.isEmpty {
                    Text("No Filtered Entries")
                        .font(.title3)
                        .bold()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        chartHeader(revenues)
                        if let year {
                            byMonthBarChart(revenues: revenues, year: year)
                                .frame(height: 100)
                        } else {
                            byYearBarChart(revenues: revenues)
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
            if !revenues.isEmpty {
                Section("\(revenues.count) Entries") {
                    RevenueListView(revenues: revenues)
                }
            }
        }.scrollContentBackground(.hidden)
    }
    
    @ViewBuilder
    private func chartHeader(_ revenues: [Revenue]) -> some View {
        HStack(alignment: .bottom) {
            Text(revenues.total.toString())
                .font(.title)
                .fontWeight(.bold)
                .fontDesign(.rounded)
            Spacer()
            if let date = chartSelection {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(year != nil ? date.month.monthText().uppercased() : date.year.yearText())
                        .font(.caption)
                        .fontWeight(.light)
                    Text((year != nil ? computeMonthAmount(revenues, month: date.month) : computeYearAmount(revenues, year: date.year)).toString())
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
    
    private func computeMonthAmount(_ revenues: [Revenue], month: Int) -> Price {
        return revenues.filter({ month == $0.date.month })
            .map({ $0.amount })
            .reduce(.Cents(0), +)
    }
    
    private func computeYearAmount(_ revenues: [Revenue], year: Int) -> Price {
        return revenues.filter({ year == $0.date.year })
            .map({ $0.amount })
            .reduce(.Cents(0), +)
    }
    
    private func isFiltered(_ revenue: Revenue) -> Bool {
        searchText.isEmpty ||
        isFiltered(revenue.payer) ||
        isFiltered(revenue.notes)
    }
    
    private func isFiltered(_ str: String) -> Bool {
        str.localizedCaseInsensitiveContains(searchText)
    }
    
    private func updateAllPayerNames() {
        revenues.filter({ $0.payer == payer }).forEach({ $0.payer = editName })
        try? modelContext.save()
        navigationStore.replace(RevenueViewType.byPayer(name: editName))
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        RevenuePayerView(payer: "RMCI")
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}

