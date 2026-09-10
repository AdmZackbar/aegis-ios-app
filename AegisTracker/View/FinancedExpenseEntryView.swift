//
//  FinancedExpenseEntryView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import SwiftUI

struct FinancedExpenseEntryView: View {
    typealias Component = ExpenseEntryView.Component
    
    let expense: FinancedExpense
    let date: Date
    let omitted: [Component]
    let category: BudgetCategory?
    
    init(expense: FinancedExpense, date: Date, omitted: [Component] = [.Category], category: BudgetCategory? = nil) {
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
            return expense.getTotal(date: date).toString()
        }
    }
}

#Preview {
    let expense = FinancedExpense(amount: .Cents(79999), payee: "Apple", category: "Tech Devices", notes: "Apple Watch Ultra 4", paymentPlan: .acmi(numMonths: 12))
    Form {
        ForEach(expense.dates, id: \.self) { date in
            FinancedExpenseEntryView(expense: expense, date: date)
        }
    }
}
