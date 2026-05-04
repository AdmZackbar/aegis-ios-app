//
//  ExpenseItemEntryView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 5/4/26.
//

import SwiftUI

struct ExpenseItemEntryView: View {
    let item: Expense.Item
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack (alignment: .top, spacing: 4) {
                    Text(item.name)
                    if !item.quantity.summary.isEmpty {
                        Text("(\(item.quantity.summary))")
                            .font(.subheadline)
                            .padding(.top, 1)
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

#Preview {
    let chicken = Expense.Item(name: "Chicken Thighs", brand: "Kirkland Signature", quantity: .Unit(num: 4.51, unit: "lb"), total: .Cents(3541))
    let hotChoc = Expense.Item(name: "Hot Chocolate", brand: "Swiss Miss", quantity: .Discrete(1), total: .Cents(799), discount: .Cents(300))
    let chunks = Expense.Item(name: "Lightly Breaded Chicken Chunks", brand: "Just Bare", quantity: .Discrete(2), total: .Cents(1499))
    let card = Expense.Item(name: "Mother's Day Card", brand: "Hallmark", quantity: .Discrete(1), total: .Cents(599), category: "Gift")
    return Form {
        ExpenseItemEntryView(item: chicken)
        ExpenseItemEntryView(item: hotChoc)
        ExpenseItemEntryView(item: chunks)
        ExpenseItemEntryView(item: card)
    }
}
