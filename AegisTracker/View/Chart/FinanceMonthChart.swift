//
//  FinanceMonthChart.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/21/24.
//

import Charts
import SwiftUI

struct FinanceMonthChart: View {
    let data: [FinanceData]
    let year: Int
    let month: Int
    
    init(data: [FinanceData], year: Int, month: Int) {
        self.data = data
        self.year = year
        self.month = month
    }
    
    var body: some View {
        let colorMap: [String : Color] = {
            var map: [String : Color] = [:]
            FinanceData.Category.allCases.forEach({ map[$0.rawValue] = $0.color })
            return map
        }()
        Chart(data, id: \.date.hashValue) { item in
            BarMark(x: .value("Date", item.date, unit: .day), y: .value("Amount", item.amount))
                .cornerRadius(4)
                .foregroundStyle(by: .value("Category", item.category.rawValue))
                .position(by: .value("Category", item.category.rawValue))
        }.chartXScale(domain: createDate(day: 1)...createDate(day: Calendar.current.range(of: .day, in: .month, for: createDate())!.upperBound - 1))
            .chartForegroundStyleScale { colorMap[$0] ?? Color.gray }
            .chartLegend(.hidden)
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
    
    private func createDate(day: Int = 1) -> Date {
        .from(year: year, month: month, day: day)
    }
}

#Preview {
    Form {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: .now)!
        FinanceMonthChart(
            data: [.init(amount: 1540.11), .init(amount: 451.18),
                   .init(amount: 4301.23, category: .income),
                   .init(date: monthAgo, amount: 451.2),
                   .init(date: monthAgo, amount: 3410.1, category: .income)],
            year: Date().year,
            month: Date().month)
        .frame(height: 200)
    }
}
