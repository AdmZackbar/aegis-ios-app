//
//  Revenue.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/12/24.
//

import Foundation
import SwiftData

typealias Revenue = SchemaV1.Revenue

extension SchemaV1 {
    @Model
    final class Revenue {
        var date: Date
        var payer: String
        var amount: Price
        var category: Category
        
        init(date: Date, payer: String, amount: Price, category: Category) {
            self.date = date
            self.payer = payer
            self.amount = amount
            self.category = category
        }
        
        enum Category: String, Codable, CaseIterable {
            // Earning money from a job or completing a task
            case Paycheck
            // Receiving cash as a gift
            case Gift
            // Selling assets for liquid cash
            case Liquidation
            // Dividends from the stock market
            case Dividend
        }
    }
}
