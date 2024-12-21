//
//  MockDataPreview.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/15/24.
//

import SwiftData
import SwiftUI

// Ideally this should reside in Preview Content, but
// because the dead code stripper doesn't work with the
// preview modifier, this has to stay in the main codebase...
struct MockDataPreviewModifier: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let container = try ModelContainer(
            for: Schema(CurrentSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        populateContainer(container)
        return container
    }
    
    static func populateContainer(_ container: ModelContainer) {
        let expenses: [Expense] = [
            .init(payee: "Costco",
                  amount: .Cents(3541),
                  category: "Gas",
                  details: .Fuel(details: .init(amount: 11.2, rate: 2.561, user: "CX-5"))),
            .init(payee: "NBKC Bank",
                  amount: .Cents(600),
                  category: "Housing Payment",
                  notes: "November payment"),
            .init(payee: "HSV Utils",
                  amount: .Cents(10234),
                  category: "Utility Bill",
                  notes: "November bill",
                  details: .Bill(details: .init(bills: [
                    .Variable(name: "Electric", base: .Cents(3552), amount: 462, rate: 0.00231),
                    .Flat(name: "Trash", base: .Cents(1423))]))),
            .init(payee: "Greasy Hands",
                  amount: .Cents(4523),
                  category: "Haircut",
                  notes: "Ryle cut",
                  details: .Tip(amount: .Cents(1002))),
            .init(payee: "Publix",
                  amount: .Cents(10723),
                  category: "Groceries",
                  details: .Items(list: .init(items: [
                    .init(name: "Chicken breast", brand: "Kirkland Signature", quantity: .Unit(num: 2.4, unit: "lb"), total: .Cents(1230)),
                    .init(name: "Apples", brand: "Publix", quantity: .Discrete(6), total: .Cents(190)),
                    .init(name: "Root beer", brand: "IBC", quantity: .Discrete(1), total: .Cents(699))
                  ])))
        ]
        expenses.forEach({ container.mainContext.insert($0) })
        let revenues: [Revenue] = [
            .init(payer: "RMCI", amount: .Cents(233412), category: "Paycheck"),
            .init(payer: "Ruth Wassynger", amount: .Cents(2341), category: "Gift", notes: "Birthday"),
            .init(payer: "Fidelity", amount: .Cents(231), category: "Dividend", notes: "Apple divident"),
            .init(payer: "Carmax", amount: .Cents(250000), category: "Sale", notes: "Sold 2002 MDX"),
            .init(payer: "RMCI", amount: .Cents(200000), category: "Bonus", notes: "Christmas bonue"),
            .init(date: Calendar.current.date(byAdding: .year, value: -1, to: .now)!, payer: "RMCI", amount: .Cents(170412), category: "Paycheck"),
        ]
        revenues.forEach({ container.mainContext.insert($0) })
        let asset: Asset = .init(name: "332 Dovington Drive Mortgage",
                                 totalCost: .Cents(30523199),
                                 metaData: .init(category: "House", notes: "First house"),
                                 valuations: [.init(date: Date(), amount: .Cents(31023199))],
                                 loan: .init(
                                    amount: .Cents(24531223),
                                    payments: [
                                        .init(type: .Regular(
                                                details: .init(
                                                    principal: .Cents(30141),
                                                    interest: .Cents(158323),
                                                    escrow: .Cents(53623),
                                                    other: .Cents(0))),
                                              notes: "November payment")],
                                    metaData: .init(
                                        lender: "NBKC Bank",
                                        rate: 6.625,
                                        term: .Years(num: 30))))
        container.mainContext.insert(asset)
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}
