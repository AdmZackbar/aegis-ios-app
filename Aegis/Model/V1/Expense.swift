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
        var date: Date
        var payee: String
        var amount: Price
        var category: String
        var details: Details
        
        init(date: Date, payee: String, amount: Price, category: String, details: Details) {
            self.date = date
            self.payee = payee
            self.amount = amount
            self.category = category
            self.details = details
        }
        
        enum Details: Codable {
            case Generic(details: String)
            case Tag(tag: String, details: String)
            case Fuel(amount: Double, rate: Double, type: String, user: String)
            case Tip(tip: Price, details: String)
            case Bill(details: BillDetails)
            case Groceries(list: GroceryList)
        }
        
        struct BillDetails: Codable {
            var types: [BillType]
            var tax: Price
            var details: String
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
                var unitPrice: Price
                var quantity: Int
                var totalPrice: Price {
                    get {
                        return unitPrice * Double(quantity)
                    }
                }
                var category: String
            }
        }
    }
}
