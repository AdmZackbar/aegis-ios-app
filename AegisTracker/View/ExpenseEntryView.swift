//
//  ExpenseEntryView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/13/24.
//

import SwiftUI

struct ExpenseEntryView: View {
    let expense: Expense
    let omitted: [Component]
    
    init(expense: Expense, omitted: [Component] = [.Category]) {
        self.expense = expense
        self.omitted = omitted
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(getTitle()).bold()
                Spacer()
                componentText(.Total).bold()
            }
            switch expense.details {
            case .none:
                componentText(.Payee).font(.subheadline).italic()
            case .Items(let list):
                itemListView(list)
            case .Fuel(let details):
                let amount = details.amount.formatted(.number.precision(.fractionLength(0...1)))
                let rate = details.rate.formatted(.currency(code: "USD"))
                if let payee = get(.Payee) {
                    HStack(alignment: .top) {
                        Text(payee)
                        Spacer()
                        Text("\(amount) gal @ \(rate)").multilineTextAlignment(.trailing)
                    }.font(.subheadline).italic()
                } else {
                    HStack(alignment: .top) {
                        Text("\(amount) gallons")
                        Spacer()
                        Text("\(rate) / gal").multilineTextAlignment(.trailing)
                    }.font(.subheadline).italic()
                }
                if (!details.user.isEmpty) {
                    Text(details.user).font(.caption)
                }
            case .Tip(let tip):
                HStack(alignment: .top) {
                    componentText(.Payee)
                    Spacer()
                    if tip.toUsd() > 0 {
                        Text("\(tip.toString()) tip").multilineTextAlignment(.trailing)
                    }
                }.font(.subheadline).italic()
            case .Bill(let details):
                HStack(alignment: .top) {
                    componentText(.Payee)
                    Spacer()
                    if details.bills.count > 1 {
                        Text("\(details.bills.count) bills").multilineTextAlignment(.trailing)
                    } else if !details.bills.isEmpty {
                        Text(details.bills[0].getName()).multilineTextAlignment(.trailing)
                    }
                }.font(.subheadline).italic()
            }
            componentText(.Notes).font(.caption)
        }
    }
    
    @ViewBuilder
    private func itemListView(_ list: Expense.ItemList) -> some View {
        let itemText = itemsText(list)
        let payee = get(.Payee)
        let discount = computeDiscount()
        if let payee, let itemText {
            HStack(alignment: .top) {
                Text(payee)
                Spacer()
                if let discount {
                    Text(discount)
                        .strikethrough()
                        .multilineTextAlignment(.trailing)
                }
            }.font(.subheadline).italic()
            Text(itemText)
                .font(.caption).italic()
        } else {
            let leftText = payee ?? itemText ?? nil
            HStack(alignment: .top) {
                if let leftText {
                    Text(leftText)
                }
                Spacer()
                if let discount {
                    Text(discount)
                        .strikethrough()
                        .multilineTextAlignment(.trailing)
                }
            }.font(.subheadline).italic()
        }
    }
    
    private func computeDiscount() -> String? {
        switch expense.details {
        case .Items(let list):
            let discount = list.items.map({ $0.discount ?? .Cents(0) }).reduce(.Cents(0), +)
            return discount.toCents() > 0 ? (expense.amount + discount).toString() : nil
        default:
            return nil
        }
    }
    
    private func itemsText(_ list: Expense.ItemList) -> String? {
        if list.items.isEmpty {
            return nil
        } else if list.items.count > 1 {
            return "\(list.items.count) items"
        }
        return list.items[0].name
    }
    
    @ViewBuilder
    private func componentText(_ component: Component) -> some View {
        if let text = get(component) {
            if !text.isEmpty {
                Text(text)
            }
        }
    }
    
    private func getTitle() -> String {
        if let date = get(.Date) {
            return date
        }
        if let category = get(.Category) {
            return category
        }
        return ""
    }
    
    private func get(_ component: Component) -> String? {
        guard !omitted.contains([component]) else {
            return nil
        }
        switch component {
        case .Date:
            return expense.date.formatted(date: .abbreviated, time: .omitted)
        case .Category:
            return expense.category
        case .Payee:
            return expense.payee
        case .Notes:
            return expense.notes
        case .Total:
            return expense.amount.toString()
        }
    }
    
    enum Component: CaseIterable {
        case Date
        case Category
        case Payee
        case Notes
        case Total
    }
}

extension Expense.Item.Amount {
    var summary: String {
        get {
            switch self {
            case .Discrete(let num):
                if num <= 1 {
                    return ""
                }
                return "x\(num.formatted())"
            case .Unit(let num, let unit):
                return unit.isEmpty ? num.formatted() : "\(num.formatted()) \(unit)"
            }
        }
    }
}

struct ExpenseItemEntryView: View {
    let item: Expense.Item
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack (alignment: .center, spacing: 4) {
                    Text(item.name)
                    if !item.quantity.summary.isEmpty {
                        Text("(\(item.quantity.summary))").font(.subheadline)
                    }
                }.bold()
                if !item.brand.isEmpty {
                    Text(item.brand)
                        .font(.subheadline).italic()
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                HStack(alignment: .center, spacing: 6) {
                    if let discount = item.discount {
                        Text("(\((discount.toUsd() / item.fullCost.toUsd() * 100.0).formatted(.number.precision(.fractionLength(0))))%)")
                            .font(.subheadline)
                            .italic()
                    }
                    Text(item.total.toString())
                }.bold()
                if item.discount != nil {
                    Text(item.fullCost.toString())
                        .font(.subheadline)
                        .bold().strikethrough()
                }
            }
        }
    }
}

struct ExpenseBillEntryView: View {
    let bill: Expense.BillDetails.Bill
    
    var body: some View {
        switch bill {
        case .Flat(let name, _):
            HStack {
                Text(name)
                Spacer()
                Text(bill.getTotal().toString())
            }.bold()
        case .Variable(let name, _, let amount, let rate):
            VStack(alignment: .leading) {
                HStack {
                    Text(name)
                    Spacer()
                    Text(bill.getTotal().toString())
                }.bold()
                if let unit = ExpenseEditView.BillUnitMap[name] {
                    HStack {
                        Text("\(amount.formatted()) \(unit)")
                        Spacer()
                        Text("\(rate.formatted(.currency(code: "USD").precision(.fractionLength(2...7)))) / \(unit)")
                    }.font(.subheadline).italic()
                }
            }
        }
    }
}

#Preview {
    let chicken = Expense.Item(name: "Chicken Thighs", brand: "Kirkland Signature", quantity: .Unit(num: 4.51, unit: "lb"), total: .Cents(3541))
    let hotChoc = Expense.Item(name: "Hot Chocolate", brand: "Swiss Miss", quantity: .Discrete(1), total: .Cents(799), discount: .Cents(300))
    let chunks = Expense.Item(name: "Lightly Breaded Chicken Chunks", brand: "Just Bare", quantity: .Discrete(2), total: .Cents(1499))
    return Form {
        ExpenseEntryView(expense: .init(date: Date(), payee: "Costco", amount: .Cents(34156), category: "Groceries", notes: "Just another run", details: .Items(list: .init(items: [
            chicken, hotChoc, chunks
        ]))))
        ExpenseEntryView(expense: .init(date: Date(), payee: "Greasy Hands", amount: .Cents(4510), category: "Haircut", notes: "With Ryle - Middle Part", details: .Tip(amount: .Cents(1000))))
        ExpenseEntryView(expense: .init(date: Date(), payee: "Valve", amount: .Cents(499), category: "Video Games", notes: ""), omitted: [.Date])
        ExpenseItemEntryView(item: chicken)
        ExpenseItemEntryView(item: hotChoc)
        ExpenseItemEntryView(item: chunks)
        ExpenseBillEntryView(bill: .Variable(name: "Electric", base: .Cents(1402), amount: 5125.1, rate: 0.00234))
        ExpenseBillEntryView(bill: .Flat(name: "Internet", base: .Cents(4109)))
    }
}
