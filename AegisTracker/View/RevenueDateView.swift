//
//  RevenueDateView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/20/24.
//

import Charts
import SwiftData
import SwiftUI

struct RevenueDateView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Revenue.date, order: .reverse) var revenues: [Revenue]
    
    @State private var yearSelection: Int? = nil
    
    var body: some View {
        mainView()
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.init(uiColor: UIColor.systemGroupedBackground))
            .onAppear {
                if let date = revenues.map({ $0.date }).max() {
                    yearSelection = date.year
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.push(RevenueViewType.add())
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
    }
    
    @ViewBuilder
    private func mainView() -> some View {
        let map: [Int : [Revenue]] = {
            var map: [Int : [Revenue]] = [:]
            revenues.forEach({ map[$0.date.year, default: []].append($0) })
            return map
        }()
        TabView(selection: $yearSelection) {
            ForEach(map.sorted(by: { $0.key < $1.key }), id: \.key) { year, yearRevenues in
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Total Income")
                                    .font(.subheadline)
                                    .opacity(0.6)
                                Text(yearRevenues.total.toString())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .fontDesign(.rounded)
                            }
                            byYearBarChart(revenues: yearRevenues, year: year)
                                .frame(height: 140)
                        }
                    } header: {
                        Text(year.formatted(.number.grouping(.never)))
                            .font(.title)
                            .bold()
                    }.headerProminence(.increased)
                    Section("Entries") {
                        RevenueListView(revenues: yearRevenues)
                    }
                }.tag(year)
                    .scrollContentBackground(.hidden)
            }
        }
    }
    
    @ViewBuilder
    private func byYearBarChart(revenues: [Revenue], year: Int) -> some View {
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
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        RevenueDateView()
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
