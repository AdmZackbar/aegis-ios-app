//
//  Purchase.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/9/24.
//

import Foundation
import SwiftData

typealias Purchase = SchemaV1.Purchase

extension SchemaV1 {
    @Model
    final class Purchase {
        var date: Date
        var category: Category
        var seller: String
        var price: Price
        
        init(date: Date, category: Category, seller: String, price: Price) {
            self.date = date
            self.category = category
            self.seller = seller
            self.price = price
        }
        
        enum Category: Codable {
            case Basic(name: String, details: String)
            case Gas(numGallons: Double, costPerGallon: Price, octane: Int)
            case Groceries(items: [Food])
            case Restaurant(info: String, tip: Price)
            case Clothing(name: String, type: String, size: String)
            case Shoes(name: String, brand: String, size: String)
            case ElectricBill(usageKw: Double, costPerKw: Double)
            case WaterBill(usageGal: Double, costPerGal: Double)
            case Charity(recipient: String, details: String)
            case Gift(recipient: String, details: String)
            case Software(name: String)
            case Hardware(name: String)
            case VideoGame(name: String, platform: String)
        }
        
        struct Food: Codable, Hashable, Equatable {
            var name: String
            var category: Category
            var price: Price
            var quantity: Int
            
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

enum Price: Codable, Equatable, Hashable, Comparable {
    case Cents(_ amount: Int)
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    func toUsd() -> Double {
        switch self {
        case .Cents(let amount):
            return Double(amount) / 100.0
        }
    }
    
    func toString() -> String {
        return Price.formatter.string(for: toUsd())!
    }
    
    static func < (lhs: Price, rhs: Price) -> Bool {
        return lhs.toUsd() < rhs.toUsd()
    }
    
    static func + (left: Price, right: Price) -> Price {
        switch left {
        case .Cents(let l):
            switch right {
            case .Cents(let r):
                return .Cents(l + r)
            }
        }
    }
    
    static func - (left: Price, right: Price) -> Price {
        switch left {
        case .Cents(let l):
            switch right {
            case .Cents(let r):
                return .Cents(l - r)
            }
        }
    }
    
    static func * (left: Price, right: Double) -> Price {
        switch left {
        case .Cents(let l):
            return .Cents(Int(round(Double(l) * right)))
        }
    }
    
    static func / (left: Price, right: Double) -> Price {
        switch left {
        case .Cents(let l):
            return .Cents(Int(round(Double(l) / right)))
        }
    }
}
