//
//  ModelUtilities.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/16/24.
//

import Foundation

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
        expenses.total + financedExpenses.total
    }
}

extension FinancedExpense {
    var interest: Price {
        switch paymentPlan {
        case .acmi(_):
            return .zero
        }
    }
    
    var total: Price {
        amount + interest
    }
    
    var dates: [Date] {
        switch paymentPlan {
        case .acmi(let numMonths):
            return (0..<numMonths).map({ self.date.addMonths($0)! })
        }
    }
    
    func getTotal(date: Date) -> Price {
        switch paymentPlan {
        case .acmi(let numMonths):
            return amount / Double(numMonths)
        }
    }
    
    var financeData: [FinanceData] {
        return dates.map({ FinanceData(date: $0, amount: getTotal(date: $0).toUsd(), category: .expense) })
    }
}

extension [FinancedExpense] {
    var total: Price {
        self.map({ $0.total }).reduce(.zero, +)
    }
}

extension Subscription {
    var periodDateMap: [Period : [Date]] {
        Dictionary.init(uniqueKeysWithValues: periods.map({ ($0, $0.dates) }))
    }
    
    var datePeriodMap: [Date : Period] {
        var dict: [Date : Period] = [:]
        for period in self.periods {
            period.dates.forEach({ dict[$0] = period })
        }
        return dict
    }
    
    var latestPeriod: Period? {
        if let latestOpen = periods.filter({ $0.endDate == nil }).max(by: { $0.startDate < $1.startDate }) {
            return latestOpen
        }
        return periods.filter({ $0.endDate != nil }).max(by: { $0.endDate! < $1.endDate! })
    }
    
    var financeData: [FinanceData] {
        return datePeriodMap.map({ FinanceData(date: $0.key, amount: $0.value.amount.toUsd(), category: .expense) })
    }
}

extension Subscription.Period {
    var total: Price {
        amount * Double(dates.count)
    }
    
    var dates: [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        while currentDate <= (endDate ?? .now) {
            dates.append(currentDate)
            guard let nextDate = type.nextDate(currentDate) else {
                break
            }
            currentDate = nextDate
        }
        return dates
    }
}

extension Subscription.PeriodType {
    var text: String {
        switch self {
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
    
    func nextDate(_ date: Date) -> Date? {
        switch self {
        case .monthly:
            return date.addMonths(1)
        case .yearly:
            return date.addYears(1)
        }
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
