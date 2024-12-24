//
//  Price.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/15/24.
//

import Foundation

enum Price: Codable, Equatable, Hashable, Comparable {
    case Cents(_ amount: Int)
    
    func toCents() -> Int {
        switch self {
        case .Cents(let amount):
            return amount
        }
    }
    
    func toUsd() -> Double {
        switch self {
        case .Cents(let amount):
            return Double(amount) / 100.0
        }
    }
    
    func abs() -> Price {
        switch self {
        case .Cents(let value):
            return Price.Cents(Swift.abs(value))
        }
    }
    
    func toString(maxDigits: Int = 2) -> String {
        let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = maxDigits
            return formatter
        }()
        return formatter.string(for: toUsd())!
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
