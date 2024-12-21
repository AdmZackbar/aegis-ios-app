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
        var date: Date = Date()
        var payer: String = ""
        var amount: Price = Price.Cents(0)
        var category: String = ""
        var notes: String = ""
        
        init(date: Date = .now,
             payer: String = "",
             amount: Price = .Cents(0),
             category: String = "",
             notes: String = "") {
            self.date = date
            self.payer = payer
            self.amount = amount
            self.category = category
            self.notes = notes
        }
    }
}
