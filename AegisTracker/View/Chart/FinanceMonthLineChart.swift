//
//  FinanceMonthLineChart.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 4/26/26.
//

import Charts
import SwiftUI

struct FinanceMonthLineChart: View {
    let data: [FinanceData]
    let year: Int
    let month: Int
    
    var body: some View {
        let colorMap: [String : Color] = {
            var map: [String : Color] = [:]
            FinanceData.Category.allCases.forEach({ map[$0.rawValue] = $0.color })
            return map
        }()
        var cumulativeData: [(category: FinanceData.Category, date: Date, total: Double)] {
            var dayMap: [FinanceData.Category : [Int : Double]] = [:]
            data.forEach({ d in
                dayMap[d.category, default: [:]][d.date.day, default: 0.0] += d.amount
            })
            let maxDay = Calendar.current.range(of: .day, in: .month, for: createDate())!.upperBound - 1
            var totalMap: [FinanceData.Category : [Int : Double]] = [:]
            for category in FinanceData.Category.allCases {
                if let map = dayMap[category] {
                    var total = 0.0
                    for day in 1...maxDay {
                        total += map[day, default: 0.0]
                        totalMap[category, default: [:]][day] = total
                    }
                }
            }
            var totals: [(category: FinanceData.Category, date: Date, total: Double)] = []
            for category in FinanceData.Category.allCases {
                if let map = totalMap[category] {
                    var latest = 0.0
                    for day in 1...maxDay {
                        latest = map[day, default: latest]
                        totals.append((category: category, date: createDate(day: day), total: latest))
                    }
                }
            }
            return totals
//            return totalMap.flatMap { (key: FinanceData.Category, map: [Int : Double]) in
//                map.map { (day: Int, total: Double) in
//                    (category: category, date: createDate(day: day), total: total)
//                }
//            }
        }
        Chart(cumulativeData, id: \.date.hashValue) { d in
            LineMark(x: .value("Date", d.date, unit: .day), y: .value("Total", d.total))
                .foregroundStyle(by: .value("Category", d.category.rawValue))
                .interpolationMethod(.monotone)
        }.chartXScale(domain: createDate(day: 1)...createDate(day: Calendar.current.range(of: .day, in: .month, for: createDate())!.upperBound - 1))
            .chartForegroundStyleScale { colorMap[$0] ?? Color.gray }
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { date in
                    if date.index == 0 || date.index % 7 == 6 {
                        AxisValueLabel(format: .dateTime.day(), centered: true)
                    }
                    AxisGridLine()
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
        let date = Date.from(year: Date().year, month: 1, day: 12)
        let daysAgo = Calendar.current.date(byAdding: .day, value: -5, to: date)!
        FinanceMonthLineChart(
            data: [.init(date: date, amount: 1540.11),
                   .init(date: date, amount: 451.18),
                   .init(date: date, amount: 4301.23, category: .income),
                   .init(date: daysAgo, amount: 451.2),
                   .init(date: daysAgo, amount: 3410.1, category: .income)],
            year: date.year,
            month: date.month)
        .frame(height: 200)
    }
}
