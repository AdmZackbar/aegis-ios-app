//
//  LoanView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/28/24.
//

import SwiftData
import SwiftUI

struct LoanView: View {
    let loan: Loan
    
    @Binding private var path: [ViewType]
    
    init(path: Binding<[ViewType]>, loan: Loan) {
        self._path = path
        self.loan = loan
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(loan.metaData.lender)
                        Spacer()
                        Text(loan.startDate.formatted(date: .abbreviated, time: .omitted))
                    }.font(.headline)
                    switch loan.metaData.term {
                    case .Years(let num):
                        Text("\(loan.metaData.rate.formatted())% for \(num) years").italic()
                    }
                }
                Gauge(value: (loan.originalAmount - loan.remainingAmount).toUsd(),
                      in: 0...loan.originalAmount.toUsd()) {
                    Text("\((loan.originalAmount - loan.remainingAmount).toString()) paid")
                } currentValueLabel: {
                    Text("Remaining: \(loan.remainingAmount.toString())").italic()
                } minimumValueLabel: {
                    Text("")
                } maximumValueLabel: {
                    Text(loan.originalAmount.toString())
                }
                if !loan.payments.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Payments").font(.title).bold()
                            Spacer()
                        }
                        List(loan.payments, id: \.id) { payment in
                            VStack {
                                Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                                Text(payment.getAmount().toString())
                            }
                        }
                    }
                }
                Spacer()
            }
        }.navigationTitle(loan.name)
            .navigationBarTitleDisplayMode(.inline)
            .padding()
    }
}

#Preview {
    let container = createTestModelContainer()
    let loan = Loan(name: "332 Dovington Drive Mortgage", startDate: .now, originalAmount: .Cents(24531223), remainingAmount: .Cents(20010245), metaData: .init(lender: "NBKC Bank", rate: 6.625, term: .Years(num: 30), category: "Housing"))
    let payment = LoanPayment(loan: loan, date: .now, type: .Regular(principal: .Cents(30141), interest: .Cents(158323)), details: "November payment")
    container.mainContext.insert(payment)
    return NavigationStack {
        LoanView(path: .constant([]), loan: payment.loan)
    }.modelContainer(container)
}
