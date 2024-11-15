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
            case Gas(amount: Double, rate: Price, octane: Int, user: String)
            case Tip(tip: Price, details: String)
            case Bill(type: BillType, details: String)
            case Groceries(list: GroceryList)
        }
        
        enum BillType: Codable {
            case Electric(amount: Double, rate: Price)
            case Water(amount: Double, rate: Price)
            case Sewer
            case Trash
            case Internet
            case Other(name: String)
            
            func getName() -> String {
                switch self {
                case .Electric(_, _):
                    return "Electric"
                case .Water(_, _):
                    return "Water"
                case .Sewer:
                    return "Sewer"
                case .Trash:
                    return "Trash"
                case .Internet:
                    return "Internet"
                case .Other(let name):
                    return name
                }
            }
            
            func getUnit() -> String? {
                switch self {
                case .Electric(_, _):
                    return "kWH"
                case .Water(_, _):
                    return "gal"
                default:
                    return nil
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
                var category: Category
                
                enum Category: String, Codable, Hashable, Equatable {
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
