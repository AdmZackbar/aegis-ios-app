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
            case .Tag(let tag):
                HStack {
                    componentText(.Payee)
                    Spacer()
                    Text(tag)
                }.font(.subheadline).italic()
            case .Items(let list):
                let itemText = itemsText(list)
                let payee = get(.Payee)
                if let payee, let itemText {
                    HStack {
                        Text(payee)
                        Spacer()
                        Text(itemText)
                    }.font(.subheadline).italic()
                } else if let payee {
                    Text(payee)
                        .font(.subheadline).italic()
                } else if let itemText {
                    Text(itemText)
                        .font(.subheadline).italic()
                }
            case .Fuel(let details):
                let amount = details.amount.formatted(.number.precision(.fractionLength(0...1)))
                let rate = details.rate.formatted(.currency(code: "USD"))
                if let payee = get(.Payee) {
                    HStack(alignment: .top) {
                        Text(payee)
                        Spacer()
                        Text("\(amount) gal @ \(rate)")
                    }.font(.subheadline).italic()
                } else {
                    HStack(alignment: .top) {
                        Text("\(amount) gallons")
                        Spacer()
                        Text("\(rate) / gal")
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
                        Text("\(tip.toString()) tip")
                    }
                }.font(.subheadline).italic()
            case .Bill(let details):
                HStack {
                    componentText(.Payee)
                    Spacer()
                    Text("\(details.bills.count) bills")
                }.font(.subheadline).italic()
            }
            componentText(.Notes).font(.caption)
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

#Preview {
    Form {
        ExpenseEntryView(expense: .init(date: Date(), payee: "Costco", amount: .Cents(34156), category: "Groceries", notes: "Just another run", details: .Items(list: .init(items: [
            .init(name: "Chicken Thighs", brand: "Kirkland Signature", quantity: .Unit(num: 4.51, unit: "lb"), total: .Cents(3541)),
            .init(name: "Hot Chocolate", brand: "Swiss Miss", quantity: .Discrete(1), total: .Cents(799), discount: .Cents(300)),
            .init(name: "Chicken Chunks", brand: "Just Bare", quantity: .Discrete(2), total: .Cents(1499))
        ]))))
        ExpenseEntryView(expense: .init(date: Date(), payee: "Greasy Hands", amount: .Cents(4510), category: "Haircut", notes: "With Ryle - Middle Part", details: .Tip(amount: .Cents(1000))))
        ExpenseEntryView(expense: .init(date: Date(), payee: "Valve", amount: .Cents(499), category: "Video Games", notes: ""), omitted: [.Date])
    }
}
