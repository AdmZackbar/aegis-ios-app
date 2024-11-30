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
                Gauge(value: (loan.amount - loan.remainingAmount).toUsd(),
                      in: 0...loan.amount.toUsd()) {
                    Text("\((loan.amount - loan.remainingAmount).toString()) paid")
                } currentValueLabel: {
                    Text("Remaining: \(loan.remainingAmount.toString())").italic()
                } minimumValueLabel: {
                    Text("")
                } maximumValueLabel: {
                    Text(loan.amount.toString())
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
    let loan = addTestLoan(container.mainContext)
    return NavigationStack {
        LoanView(path: .constant([]), loan: loan)
    }.modelContainer(container)
}
