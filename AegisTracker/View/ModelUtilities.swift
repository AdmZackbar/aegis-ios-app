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

extension [BudgetCategory] {
    var total: Price? {
        let amounts = self.filter({ $0.monthlyBudget != nil }).map({ $0.monthlyBudget! })
        return amounts.isEmpty ? nil : amounts.reduce(.Cents(0), +)
    }
    
    func find(_ name: String) -> BudgetCategory? {
        for category in self {
            if category.contains(name) {
                return category
            }
        }
        return nil
    }
}

extension BudgetCategory {
    func contains(_ name: String) -> Bool {
        if self.name == name {
            return true
        }
        if let assetType = self.assetType, assetType == name {
            return true
        }
        if let children = self.children {
            if children.find(name) != nil {
                return true
            }
        }
        return false
    }
}
