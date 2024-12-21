//
//  ModelUtilities.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/16/24.
//

extension Expense {
    var discount: Price {
        get {
            switch details {
            case .Items(let list):
                return list.items.map({ $0.discount ?? .Cents(0) }).reduce(.Cents(0), +)
            default:
                return .Cents(0)
            }
        }
    }
    
    func fullPriceText() -> String? {
        switch details {
        case .Items(_):
            return discount.toCents() > 0 ? (amount + discount).toString() : nil
        default:
            return nil
        }
    }
}

extension [Expense] {
    var total: Price {
        return self.map({ $0.amount }).reduce(.Cents(0), +)
    }
}

extension [Revenue] {
    var total: Price {
        return self.map({ $0.amount }).reduce(.Cents(0), +)
    }
}
