//
//  Subscription.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import Foundation
import SwiftData

typealias Subscription = SchemaV1.Subscription

extension SchemaV1 {
    @Model
    final class Subscription {
        var payee: String = ""
        var category: String = ""
        var notes: String = ""
        var periods: [Period] = []
        
        init(payee: String = "", category: String = "", notes: String = "", periods: [Period] = []) {
            self.payee = payee
            self.category = category
            self.notes = notes
            self.periods = periods
        }
        
        struct Period: Codable, Hashable, Equatable {
            var startDate: Date
            var endDate: Date?
            var type: PeriodType
            var amount: Price
            var notes: String
            
            init(startDate: Date = .now, endDate: Date? = nil, type: PeriodType = .monthly, amount: Price = .zero, notes: String = "") {
                self.startDate = startDate
                self.endDate = endDate
                self.type = type
                self.amount = amount
                self.notes = notes
            }
        }
        
        enum PeriodType: Codable, Hashable, Equatable {
            case monthly, yearly
        }
    }
}
