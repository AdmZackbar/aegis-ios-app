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
        
        init(date: Date = Date(),
             payee: String = "",
             amount: Price = .Cents(0),
             category: String = "",
             notes: String = "",
             details: Details? = nil) {
            self.date = date
            self.payee = payee
            self.amount = amount
            self.category = category
            self.notes = notes
            self.details = details
        }
        
        enum Details: Codable {
            case Tip(amount: Price)
            case Items(list: ItemList)
            case Bill(details: BillDetails)
            case Fuel(details: FuelDetails)
        }
        
        struct BillDetails: Codable, Hashable, Equatable {
            var bills: [Bill]
            
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
            var discount: Price?
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
            var fullCost: Price {
                get {
                    return total + (discount ?? .Cents(0))
                }
            }
            
            enum Amount: Codable, Hashable, Equatable {
                case Discrete(_ num: Int)
                case Unit(num: Double, unit: String)
            }
        }
        
        struct FuelDetails: Codable, Hashable, Equatable {
            var amount: Double
            var rate: Double
            var user: String
        }
    }
}
