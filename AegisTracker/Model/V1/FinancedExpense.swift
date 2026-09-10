//
//  FinancedExpense.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import Foundation
import SwiftData

typealias FinancedExpense = SchemaV1.FinancedExpense

extension SchemaV1 {
    @Model
    final class FinancedExpense {
        var date: Date = Date()
        var amount: Price = Price.zero
        var payee: String = ""
        var category: String = ""
        var notes: String = ""
        var tags: [ExpenseTag]! = []
        var paymentPlan: PaymentPlan = PaymentPlan.acmi(numMonths: 12)
        
        init(date: Date = .now,
             amount: Price = .zero,
             payee: String = "",
             category: String = "",
             notes: String = "",
             tags: [ExpenseTag] = [],
             paymentPlan: PaymentPlan = .acmi(numMonths: 12)) {
            self.date = date
            self.amount = amount
            self.payee = payee
            self.category = category
            self.notes = notes
            self.tags = tags
            self.paymentPlan = paymentPlan
        }
        
        enum PaymentPlan: Codable, Hashable, Equatable {
            case acmi(numMonths: Int)
        }
    }
}
