//
//  FinanceData.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/21/24.
//

import SwiftUI

extension Expense {
    static func toFinanceData(_ expense: Expense) -> FinanceData {
        .init(date: expense.date, amount: expense.amount.toUsd(), category: .expense)
    }
    
    static func toOldFinanceData(_ expense: Expense) -> FinanceData {
        .init(date: expense.date, amount: expense.amount.toUsd(), category: .old)
    }
}

extension Revenue {
    static func toFinanceData(_ revenue: Revenue) -> FinanceData {
        .init(date: revenue.date, amount: revenue.amount.toUsd(), category: .income)
    }
}

extension Asset {
    static func toFinanceData(_ payment: Asset.Loan.Payment) -> FinanceData {
        .init(date: payment.date, amount: (payment.amount - payment.principal).toUsd(), category: .expense)
    }
    
    static func toOldFinanceData(_ payment: Asset.Loan.Payment) -> FinanceData {
        .init(date: payment.date, amount: (payment.amount - payment.principal).toUsd(), category: .old)
    }
}

extension [FinanceData] {
    var total: Price {
        self.map({ .Cents(Int($0.amount * 100)) }).reduce(.Cents(0), +)
    }
}

struct FinanceData: Codable {
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
        case old
        
        var color: Color {
            get {
                switch self {
                case .expense:
                    return .red
                case .income:
                    return .green
                case .old:
                    return .gray
                }
            }
        }
    }
}
