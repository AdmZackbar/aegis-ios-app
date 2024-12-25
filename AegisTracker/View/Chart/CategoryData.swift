//
//  CategoryData.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/24/24.
//

extension Expense {
    static func toCategoryData(_ expense: Expense) -> CategoryData {
        .init(category: expense.category, amount: expense.amount)
    }
}

extension Revenue {
    static func toCategoryData(_ revenue: Revenue) -> CategoryData {
        .init(category: revenue.category, amount: revenue.amount)
    }
}

extension Asset {
    func toCategoryData(_ payments: [Loan.Payment]? = nil) -> [CategoryData] {
        if let payments {
            return payments.map({ .init(category: self.metaData.category, amount: $0.amount - $0.principal) })
        }
        if let loan {
            return loan.payments.map({ .init(category: self.metaData.category, amount: $0.amount - $0.principal) })
        }
        return []
    }
}

extension [CategoryData] {
    var total: Price {
        self.map({ $0.amount }).reduce(.Cents(0), +)
    }
}

struct CategoryData: Hashable, Equatable {
    var category: String
    var amount: Price
}
