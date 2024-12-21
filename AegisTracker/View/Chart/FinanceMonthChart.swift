//
//  FinanceMonthChart.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/21/24.
//

import Charts
import SwiftUI

struct FinanceMonthChart: View {
    @Binding private var selection: Date?
    
    let data: [FinanceData]
    let year: Int
    let month: Int
    
    init(data: [FinanceData], year: Int, month: Int, selection: Binding<Date?>) {
        self.data = data
        self.year = year
        self.month = month
        self._selection = selection
    }
    
    var body: some View {
        Chart(data, id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .day), y: .value("Amount", item.amount))
                .cornerRadius(4)
        }.chartXScale(domain: createDate(day: 1)...createDate(day: Calendar.current.range(of: .day, in: .month, for: createDate())?.upperBound))
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
    
    private func createDate(day: Int? = nil) -> Date {
        return {
            var d = DateComponents()
            d.year = year
            d.month = month
            d.day = day
            return Calendar.current.date(from: d)!
        }()
    }
}
