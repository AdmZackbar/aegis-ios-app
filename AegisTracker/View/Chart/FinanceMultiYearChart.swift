//
//  FinanceMultiYearChart.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/21/24.
//

import Charts
import SwiftUI

struct FinanceMultiYearChart: View {
    @Binding private var selection: Date?
    
    let data: [FinanceData]
    
    init(data: [FinanceData], selection: Binding<Date?>) {
        self.data = data
        self._selection = selection
    }
    
    var body: some View {
        let colorMap: [String : Color] = {
            var map: [String : Color] = [:]
            FinanceData.Category.allCases.forEach({ map[$0.rawValue] = $0.color })
            return map
        }()
        Chart(data, id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .year), y: .value("Amount", item.amount))
                .cornerRadius(4)
                .foregroundStyle(by: .value("Category", selection == nil || selection!.year == item.date.year ? item.category.rawValue : ""))
                .position(by: .value("Category", item.category.rawValue))
        }.chartForegroundStyleScale { colorMap[$0] ?? Color.gray }
            .chartXAxis {
                AxisMarks(values: .stride(by: .year)) { date in
                    AxisValueLabel(format: .dateTime.year(), centered: true)
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
        let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: .now)!
        let yearAgo2 = Calendar.current.date(byAdding: .year, value: -2, to: .now)!
        FinanceMultiYearChart(
            data: [.init(amount: 1540.1), .init(amount: 451.1),
                   .init(amount: 4301.23, category: .income),
                   .init(date: yearAgo, amount: 451.2),
                   .init(date: yearAgo, amount: 3410.1, category: .income),
                   .init(date: yearAgo2, amount: 451.2)],
            selection: $selection)
        .frame(height: 200)
    }
}
