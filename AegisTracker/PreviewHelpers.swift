//
//  PreviewHelpers.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/10/24.
//

import Foundation
import SwiftData
import SwiftUI

func createTestModelContainer() -> ModelContainer {
    let schema = Schema(CurrentSchema.models)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    return container
}

func addExpenses(_ context: ModelContext) {
    context.insert(Expense(date: .now,
                           payee: "Costco",
                           amount: .Cents(3541),
                           category: "Gas",
                           notes: "",
                           detailType: .Fuel(details: .init(amount: 11.2, rate: 2.561, user: "CX-5"))))
    context.insert(Expense(date: .now,
                           payee: "NBKC Bank",
                           amount: .Cents(600),
                           category: "Housing Payment",
                           notes: "November payment"))
    context.insert(Expense(date: .now,
                           payee: "HSV Utils",
                           amount: .Cents(10234),
                           category: "Utility Bill",
                           notes: "November bill",
                           detailType: .Bill(details: .init(types: [
                            .Variable(name: "Electric", base: .Cents(3552), amount: 462, rate: 0.00231),
                            .Flat(name: "Trash", base: .Cents(1423))], tax: .Cents(255)))))
    context.insert(Expense(date: .now,
                           payee: "HP HSV",
                           amount: .Cents(2267),
                           category: "Sports Gear",
                           notes: "Chalk",
                           detailType: .Tag(name: "Climbing")))
    context.insert(Expense(date: .now,
                           payee: "Greasy Hands",
                           amount: .Cents(4523),
                           category: "Haircut",
                           notes: "Ryle cut",
                           detailType: .Tip(amount: .Cents(1002))))
    context.insert(Expense(date: .now,
                           payee: "Publix",
                           amount: .Cents(10723),
                           category: "Groceries",
                           notes: "",
                           detailType: .Foods(list: .init(foods: [
                            .init(name: "Chicken breast", brand: "Kirkland Signature", unitPrice: .Cents(1230), quantity: 2, category: "Meat"),
                            .init(name: "Apples", brand: "Publix", unitPrice: .Cents(190), quantity: 1, category: "Fruit"),
                            .init(name: "Root beer", brand: "IBC", unitPrice: .Cents(699), quantity: 4, category: "Sweets")
                           ]))))
}

@discardableResult
func addTestLoan(_ context: ModelContext) -> Loan {
    let loan = Loan(name: "332 Dovington Drive Mortgage", startDate: .now, amount: .Cents(24531223), metaData: .init(lender: "NBKC Bank", rate: 6.625, term: .Years(num: 30), category: "Housing"))
    let payment = LoanPayment(loan: loan, date: .now, type: .Regular(details: .init(principal: .Cents(30141), interest: .Cents(158323), escrow: .Cents(53623), other: .Cents(0))), details: "November payment")
    context.insert(payment)
    return loan
}
