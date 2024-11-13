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
            case Gas(numGallons: Double, costPerGallon: Price, octane: Int)
            case Tip(details: String, tip: Price)
            case Clothing(name: String, brand: String, size: String)
            case UtilityBill(name: String, unit: String, usage: Double, rate: Price)
            case Groceries(list: GroceryList)
        }
        
        // Need to wrap the list in a struct
        struct GroceryList: Codable {
            var foods: [Food]
            
            struct Food: Codable, Hashable, Equatable {
                var name: String
                var totalPrice: Price
                var quantity: Int
                var unitPrice: Price {
                    get {
                        return totalPrice / Double(quantity)
                    }
                }
                var category: Category
                
                enum Category: Codable {
                    case Meat
                    case Carbs
                    case Meal
                    case Vegetables
                    case Fruits
                    case Sweets
                }
            }
        }
    }
}
