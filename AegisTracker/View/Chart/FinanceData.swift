//
//  FinanceData.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/21/24.
//

import SwiftUI

struct FinanceData: Codable {
    static func expense(_ expense: Expense) -> FinanceData {
        .init(date: expense.date, amount: expense.amount.toUsd(), category: .expense)
    }
    
    static func revenue(_ revenue: Revenue) -> FinanceData {
        .init(date: revenue.date, amount: revenue.amount.toUsd(), category: .income)
    }
    
    var date: Date
    var amount: Double
    var category: Category
    
    init(date: Date = .now, amount: Double = 0.0, category: Category = .expense) {
        self.date = date
        self.amount = amount
        self.category = category
    }
    
    enum Category: String, Codable, CaseIterable {
        case expense
        case income
        
        var color: Color {
            get {
                switch self {
                case .expense:
                    return .red
                case .income:
                    return .green
                }
            }
        }
    }
}
