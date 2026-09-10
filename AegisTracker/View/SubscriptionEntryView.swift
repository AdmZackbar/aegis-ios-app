//
//  SubscriptionEntryView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import SwiftUI

struct SubscriptionEntryView: View {
    typealias Component = ExpenseEntryView.Component
    
    let expense: Subscription
    let date: Date
    let omitted: [Component]
    let category: BudgetCategory?
    
    init(expense: Subscription, date: Date, omitted: [Component] = [.Category], category: BudgetCategory? = nil) {
        self.expense = expense
        self.date = date
        self.omitted = omitted
        self.category = category
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(getTitle()).bold()
                Spacer()
                componentText(.Total).bold()
            }
            componentText(.Notes).font(.caption)
        }
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
    
    private func getSubtitle() -> String? {
        let date = get(.Date)
        let category = get(.Category)
        let payee = get(.Payee)
        if date != nil {
            if let category, let payee {
                return "\(payee) \(category)"
            }
            return category ?? payee
        }
        return payee
    }
    
    private func get(_ component: Component) -> String? {
        guard !omitted.contains([component]) else {
            return nil
        }
        switch component {
        case .Date:
            return date.formatted(date: .abbreviated, time: .omitted)
        case .Category:
            return expense.category
        case .Payee:
            return expense.payee
        case .Notes:
            return expense.notes
        case .Total:
            // TODO handle missing case better
            return expense.datePeriodMap[date]?.amount.toString() ?? "???"
        }
    }
}

#Preview {
    let subscription = Subscription(payee: "Verizon", category: "Phone Bill", notes: "Test", periods: [
        .init(startDate: .now.addMonths(-13)!, amount: .Cents(7540), notes: "Std Plan")
    ])
    Form {
        ForEach(subscription.periodDateMap.values.flatMap({ $0 }).sorted(by: { $0 > $1 }), id: \.self) { date in
            SubscriptionEntryView(expense: subscription, date: date)
        }
    }
}
