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

extension [Price] {
    func sum() -> Price {
        self.reduce(.zero, +)
    }
}

protocol Expense {
    var date: Date { get }
    var payee: String { get }
    var amount: Price { get }
    var category: String { get }
    var notes: String { get }
    var details: GenericExpense.Details? { get }
}

extension Expense {
    func getAmount(category: BudgetCategory? = nil) -> Price {
        if let category {
            var total = categoryPriceMap[category.name, default: .zero]
            if let children = category.children {
                total += children.map(getAmount).sum()
            }
            return total
        }
        return amount
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
    
    var categoryPriceMap: [String : Price] {
        var map: [String : Price] = [:]
        map[category] = amount
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
    
    func getDiscount(category: BudgetCategory? = nil) -> Price {
        if let category {
            if !hasCategory(category: category) {
                switch details {
                case .Items(let list):
                    return list.items.filter({ $0.category != nil && category.contains($0.category!) }).map({ $0.discount ?? .zero }).sum()
                default:
                    return .zero
                }
            }
            switch details {
            case .Items(let list):
                return list.items.filter({ $0.category == nil || category.contains($0.category!) }).map({ $0.discount ?? .zero }).sum()
            default:
                return .zero
            }
        }
        switch details {
        case .Items(let list):
            return list.items.map({ $0.discount ?? .zero }).sum()
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
    
    func toCategoryData() -> [CategoryData] {
        categoryPriceMap.map(CategoryData.init)
    }
    
    func toFinanceData() -> FinanceData {
        .init(date: self.date, amount: self.amount.toUsd(), category: .expense)
    }
}

extension GenericExpense: Expense {
    // TODO
}

extension GenericExpense.Item {
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
        return self.map({ $0.amount }).sum()
    }
    
    func getTotal(category: BudgetCategory) -> Price {
        return self.map({ $0.getAmount(category: category) }).sum()
    }
}
extension [GenericExpense] {
    var total: Price {
        return self.map({ $0.amount }).sum()
    }
    
    func getTotal(category: BudgetCategory) -> Price {
        return self.map({ $0.getAmount(category: category) }).sum()
    }
}

extension ExpenseTag {
    var totalAmount: Price {
        expenses.total + financedExpenses.total
    }
}

struct FinancedExpenseInstance: Expense {
    let expense: FinancedExpense
    let date: Date
    
    init(expense: FinancedExpense, date: Date) {
        self.expense = expense
        self.date = date
    }
    
    var payee: String {
        expense.payee
    }
    var amount: Price {
        expense.getTotal(date: date)
    }
    var category: String {
        expense.category
    }
    var notes: String {
        expense.notes
    }
    var details: GenericExpense.Details? {
        nil
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
    
    var allExpenses: [Expense] {
        dates.map(toExpense)
    }
    
    func toExpense(date: Date) -> Expense {
        return FinancedExpenseInstance(expense: self, date: date)
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
        self.map({ $0.total }).sum()
    }
}

struct SubscriptionExpense: Expense {
    let subscription: Subscription
    let date: Date
    
    init(subscription: Subscription, date: Date) {
        self.subscription = subscription
        self.date = date
    }
    
    var payee: String {
        subscription.payee
    }
    var amount: Price {
        subscription.datePeriodMap[date]?.amount ?? .zero
    }
    var category: String {
        subscription.category
    }
    var notes: String {
        subscription.notes
    }
    var details: GenericExpense.Details? {
        nil
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
    
    var allExpenses: [Expense] {
        periods.flatMap({ $0.dates.map(toExpense) })
    }
    
    func toExpense(date: Date) -> Expense {
        return SubscriptionExpense(subscription: self, date: date)
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

extension Revenue {
    func toCategoryData() -> CategoryData {
        return .init(category: self.category, amount: self.amount)
    }
}

extension [Revenue] {
    var total: Price {
        return self.map({ $0.amount }).sum()
    }
}

extension Asset {
    func toCategoryData(_ payments: [Loan.Payment]? = nil) -> [CategoryData] {
        if let payments {
            return payments.map({ .init(category: self.metaData.category, amount: $0.amount - $0.principal) })
        }
        if let loan {
            return loan.payments.map({ .init(category: self.metaData.category, amount: $0.amount - $0.principal) })
        }
        return []
    }
}

extension [BudgetCategory] {
    var total: Price? {
        let amounts = self.filter({ $0.monthlyBudget != nil }).map({ $0.monthlyBudget! })
        return amounts.isEmpty ? nil : amounts.sum()
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
