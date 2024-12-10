//
//  Expense.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/12/24.
//

import Foundation
import SwiftData

typealias Expense = SchemaV1.Expense

extension SchemaV1 {
    @Model
    final class Expense {
        var date: Date = Date()
        var payee: String = ""
        var amount: Price = Price.Cents(0)
        var category: String = ""
        var notes: String = ""
        var detailType: DetailType? = nil
        
        init(date: Date, payee: String, amount: Price, category: String, notes: String, detailType: DetailType? = nil) {
            self.date = date
            self.payee = payee
            self.amount = amount
            self.category = category
            self.notes = notes
            self.detailType = detailType
        }
        
        enum DetailType: Codable {
            case Tag(name: String)
            case Tip(amount: Price)
            case Bill(details: BillDetails)
            case Foods(list: GroceryList)
            case Fuel(details: FuelDetails)
        }
        
        struct BillDetails: Codable {
            var types: [BillType]
            var tax: Price
        }
        
        enum BillType: Codable, Hashable, Equatable {
            case Flat(name: String, base: Price)
            case Variable(name: String, base: Price, amount: Double, rate: Double)
            
            func getName() -> String {
                switch self {
                case .Flat(let name, _):
                    return name
                case .Variable(let name, _, _, _):
                    return name
                }
            }
            
            func getTotal() -> Price {
                switch self {
                case .Flat(_, let base):
                    return base
                case .Variable(_, let base, let amount, let rate):
                    return base + .Cents(Int(round(amount * rate * 100.0)))
                }
            }
        }
        
        // Need to wrap the list in a struct
        struct GroceryList: Codable {
            var foods: [Food]
            
            struct Food: Codable, Hashable, Equatable {
                var name: String
                var brand: String
                var unitPrice: Price
                var quantity: Double
                var totalPrice: Price {
                    get {
                        return unitPrice * quantity
                    }
                }
                var category: String
            }
        }
        
        struct FuelDetails: Codable {
            var amount: Double
            var rate: Double
            var user: String
        }
    }
}
