//
//  LoanView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/28/24.
//

import SwiftData
import SwiftUI

struct LoanView: View {
    @Environment(\.modelContext) var modelContext
    
    let loan: Loan
    
    @Binding private var path: [ViewType]
    @State private var showPaymentSheet: Bool = false
    @State private var selectedPayment: LoanPayment? = nil
    
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
                        ForEach(loan.payments.sorted(by: { $0.date > $1.date }), id: \.id) { payment in
                            Button {
                                selectedPayment = payment
                                showPaymentSheet = true
                            } label: {
                                HStack {
                                    Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                                    Spacer()
                                    Text(payment.getAmount().toString())
                                }.contentShape(Rectangle())
                            }.buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        loan.payments.removeAll(where: { $0 == payment })
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                Spacer()
            }
        }.navigationTitle(loan.name)
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Edit") {
                        path.append(.EditLoan(loan: loan))
                    }
                    Button {
                        selectedPayment = nil
                        showPaymentSheet = true
                    } label: {
                        Label("Add Payment", systemImage: "plus").labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $showPaymentSheet) {
                NavigationStack {
                    LoanPaymentView(path: $path, loan: loan, payment: selectedPayment)
                }
            }
    }
}

struct LoanPaymentView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    private let mode: Mode
    let loan: Loan
    let payment: LoanPayment
    
    @Binding private var path: [ViewType]
    @State private var date: Date = .now
    @State private var type: LoanType = .Regular
    @State private var principal: Int = 0
    @State private var interest: Int = 0
    @State private var escrow: Int = 0
    @State private var other: Int = 0
    @State private var details: String = ""
    
    init(path: Binding<[ViewType]>, loan: Loan, payment: LoanPayment? = nil) {
        self._path = path
        self.loan = loan
        self.payment = payment ?? .init(date: .now, type: .Principal(principal: .Cents(0)), details: "")
        mode = payment == nil ? .Add : .Edit
    }
    
    var body: some View {
        Form {
            Picker("", selection: $type) {
                Text("Regular").tag(LoanType.Regular)
                Text("Principal").tag(LoanType.Principal)
            }.pickerStyle(.segmented)
            DatePicker("Date:", selection: $date, displayedComponents: .date)
            HStack {
                Text("Principal:")
                CurrencyField(value: $principal)
            }
            if type == .Regular {
                HStack {
                    Text("Interest:")
                    CurrencyField(value: $interest)
                }
                HStack {
                    Text("Escrow:")
                    CurrencyField(value: $escrow)
                }
                HStack {
                    Text("Other:")
                    CurrencyField(value: $other)
                }
            }
            TextField("Details", text: $details, axis: .vertical)
                .lineLimit(3...8)
        }.navigationTitle(mode.getTitle())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: load)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: back)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(principal <= 0)
                }
            }
    }
    
    private func load() {
        if mode == .Edit {
            self.date = payment.date
            switch payment.type {
            case .Regular(let details):
                type = .Regular
                principal = details.principal.toCents()
                interest = details.interest.toCents()
                escrow = details.escrow.toCents()
                other = details.other.toCents()
            case .Principal(let principal):
                type = .Principal
                self.principal = principal.toCents()
            }
        }
    }
    
    private func back() {
        dismiss()
    }
    
    private func save() {
        payment.date = date
        switch type {
        case .Regular:
            payment.type = .Regular(details: .init(principal: .Cents(principal), interest: .Cents(interest), escrow: .Cents(escrow), other: .Cents(other)))
        case .Principal:
            payment.type = .Principal(principal: .Cents(principal))
        }
        payment.details = details
        if mode == .Add {
            payment.loan = loan
            loan.payments.append(payment)
        }
        back()
    }
    
    private enum LoanType {
        case Regular, Principal
    }
    
    private enum Mode {
        case Add, Edit
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Loan Payment"
            case .Edit:
                "Edit Loan Payment"
            }
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let loan = addTestLoan(container.mainContext)
    return NavigationStack {
        LoanView(path: .constant([]), loan: loan)
    }.modelContainer(container)
}
