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
    
    var categoryPriceMap: [String : Price] {
        var map: [String : Price] = [:]
        map[self.category] = self.amount
        switch details {
        case .Items(let list):
            for item in list.items {
                if let itemCategory = item.category {
                    if itemCategory != self.category {
                        map[self.category] = map[self.category]! - item.total
                        map[itemCategory] = map[itemCategory, default: .Cents(0)] + item.total
                    }
                }
            }
        default:
            break
        }
        return map
    }
    
    func fullPriceText() -> String? {
        switch details {
        case .Items(_):
            return discount.toCents() > 0 ? (amount + discount).toString() : nil
        default:
            return nil
        }
    }
    
    func hasCategory(category: String) -> Bool {
        if (self.category == category) {
            return true
        }
        switch details {
        case .Items(let list):
            return list.items.contains(where: { $0.category == category })
        default:
            return false
        }
    }
}

extension [Expense] {
    var total: Price {
        return self.map({ $0.amount }).reduce(.Cents(0), +)
    }
    
    func getTotal(category: String) -> Price {
        return self.map({ $0.categoryPriceMap[category, default: .Cents(0)] }).reduce(.Cents(0), +)
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
