//
//  ModelUtilities.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/16/24.
//

extension Price {
    static let zero: Price = .Cents(0)
}

extension Expense {
    var categoryPriceMap: [String : Price] {
        var map: [String : Price] = [:]
        map[self.category] = self.amount
        switch details {
        case .Items(let list):
            for item in list.items {
                if let itemCategory = item.category {
                    if itemCategory != self.category {
                        map[self.category]! -= item.total
                        map[itemCategory, default: .zero] += item.total
                    }
                }
            }
        default:
            break
        }
        return map
    }
    
    func getAmount(category: BudgetCategory? = nil) -> Price {
        if let category {
            var total = categoryPriceMap[category.name, default: .zero]
            if let children = category.children {
                total += children.map(getAmount).reduce(.zero, +)
            }
            return total
        }
        return amount
    }
    
    func getDiscount(category: BudgetCategory? = nil) -> Price {
        if let category {
            if !hasCategory(category: category) {
                switch details {
                case .Items(let list):
                    return list.items.filter({ $0.category != nil && category.contains($0.category!) }).map({ $0.discount ?? .zero }).reduce(.zero, +)
                default:
                    return .zero
                }
            }
            switch details {
            case .Items(let list):
                return list.items.filter({ $0.category == nil || category.contains($0.category!) }).map({ $0.discount ?? .zero }).reduce(.zero, +)
            default:
                return .zero
            }
        }
        switch details {
        case .Items(let list):
            return list.items.map({ $0.discount ?? .zero }).reduce(.zero, +)
        default:
            return .zero
        }
    }
    
    func fullPriceText(category: BudgetCategory? = nil) -> String? {
        switch details {
        case .Items(_):
            let discount = getDiscount(category: category)
            return discount.toCents() > 0 ? (getAmount(category: category) + discount).toString() : nil
        default:
            return nil
        }
    }
    
    func hasCategory(category: BudgetCategory) -> Bool {
        if (category.contains(self.category)) {
            return true
        }
        switch details {
        case .Items(let list):
            return list.items.contains(where: { $0.category != nil && category.contains($0.category!) })
        default:
            return false
        }
    }
}

extension Expense.Item {
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
            return total + (discount ?? .zero)
        }
    }
}

extension [Expense] {
    var total: Price {
        return self.map({ $0.amount }).reduce(.zero, +)
    }
    
    func getTotal(category: BudgetCategory) -> Price {
        return self.map({ $0.getAmount(category: category) }).reduce(.zero, +)
    }
}

extension ExpenseTag {
    var totalAmount: Price {
        expenses.map({ $0.amount }).reduce(.zero, +)
    }
}

extension [Revenue] {
    var total: Price {
        return self.map({ $0.amount }).reduce(.zero, +)
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
