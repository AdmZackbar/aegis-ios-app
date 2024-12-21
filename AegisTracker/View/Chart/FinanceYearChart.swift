//
//  FinanceYearChart.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/21/24.
//

import Charts
import SwiftUI

struct FinanceYearChart: View {
    @Binding private var selection: Date?
    
    let data: [FinanceData]
    let year: Int
    
    init(data: [FinanceData], year: Int, selection: Binding<Date?>) {
        self.data = data
        self.year = year
        self._selection = selection
    }
    
    var body: some View {
        let domain = {
            var start = DateComponents()
            start.year = year
            start.month = 1
            var end = DateComponents()
            end.year = year + 1
            end.month = 1
            return Calendar.current.date(from: start)!...Calendar.current.date(from: end)!
        }()
        let colorMap: [String : Color] = {
            var map: [String : Color] = [:]
            FinanceData.Category.allCases.forEach({ map[$0.rawValue] = $0.color })
            return map
        }()
        Chart(data, id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .month), y: .value("Amount", item.amount))
                .cornerRadius(4)
                .foregroundStyle(by: .value("Category", selection == nil || selection!.month == item.date.month ? item.category.rawValue : ""))
                .position(by: .value("Category", item.category.rawValue))
                
        }.chartXScale(domain: domain)
            .chartForegroundStyleScale { colorMap[$0] ?? Color.gray }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { date in
                    AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(format: .currency(code: "USD").precision(.fractionLength(0)),
                          values: .automatic(desiredCount: 4))
            }
            .chartLegend(.hidden)
            .chartXSelection(value: $selection)
    }
}

#Preview {
    @Previewable @State var selection: Date? = nil
    Form {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: .now)!
        FinanceYearChart(
            data: [.init(amount: 1540.1), .init(amount: 451.1),
                   .init(amount: 4301.23, category: .income),
                   .init(date: monthAgo, amount: 451.2),
                   .init(date: monthAgo, amount: 3410.1, category: .income)],
            year: Date().year,
            selection: $selection)
        .frame(height: 200)
    }
}
