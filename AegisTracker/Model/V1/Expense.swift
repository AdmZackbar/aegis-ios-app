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
        var details: Details? = nil
        
        init(date: Date, payee: String, amount: Price, category: String, notes: String, details: Details? = nil) {
            self.date = date
            self.payee = payee
            self.amount = amount
            self.category = category
            self.notes = notes
            self.details = details
        }
        
        enum Details: Codable {
            case Tag(name: String)
            case Tip(amount: Price)
            case Items(list: ItemList)
            case Bill(details: BillDetails)
            case Fuel(details: FuelDetails)
        }
        
        struct BillDetails: Codable, Hashable, Equatable {
            var bills: [Bill]
            var tax: Price
            
            enum Bill: Codable, Hashable, Equatable {
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
        }
        
        // Need to wrap the list in a struct
        struct ItemList: Codable, Hashable, Equatable {
            var items: [Item]
        }
        
        struct Item: Codable, Hashable, Equatable {
            var name: String
            var brand: String
            var quantity: Amount
            var total: Price
            var unitCost: Price {
                get {
                    switch quantity {
                    case .Discrete(let num):
                        return total / Double(num)
                    case .Unit(let num, _):
                        return total / num
                    }
                }
            }
            
            enum Amount: Codable, Hashable, Equatable {
                case Discrete(_ num: Int)
                case Unit(num: Double, unit: String)
                
                var summary: String {
                    get {
                        switch self {
                        case .Discrete(let num):
                            if num <= 1 {
                                return ""
                            }
                            return "\(num.formatted()) items"
                        case .Unit(let num, let unit):
                            return unit.isEmpty ? num.formatted() : "\(num.formatted()) \(unit)"
                        }
                    }
                }
            }
        }
        
        struct FuelDetails: Codable, Hashable, Equatable {
            var amount: Double
            var rate: Double
            var user: String
        }
    }
}
