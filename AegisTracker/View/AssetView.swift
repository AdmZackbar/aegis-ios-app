//
//  AssetView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/16/24.
//

import Charts
import SwiftData
import SwiftUI

struct AssetView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    let asset: Asset
    
    @State private var showDelete: Bool = false
    // Payment
    @State private var showPaymentSheet: Bool = false
    @State private var payment: PaymentEditSheet.Payment = .init()
    @State private var paymentIndex: Int = -1
    
    init(asset: Asset) {
        self.asset = asset
    }
    
    var body: some View {
        VStack(spacing: 4) {
            headerView()
            Form {
                if let loan = asset.loan {
                    if loan.totalPaid.toCents() > 0 {
                        Section(loan.metaData.lender) {
                            loanPaymentSummary(loan)
                        }
                    }
                    paymentsView(loan)
                }
            }.scrollContentBackground(.hidden)
            footerActionsView()
        }.navigationTitle(asset.name)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.init(uiColor: UIColor.systemGroupedBackground))
            .confirmationDialog("Are you sure you want to delete this asset?", isPresented: $showDelete) {
                Button("Delete", role: .destructive, action: delete)
            } message: {
                Text("This cannot be undone")
            }
            .sheet(isPresented: $showPaymentSheet, content: paymentSheet)
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        Text(asset.totalCost.toString())
            .font(.system(size: 40, weight: .bold, design: .rounded))
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.metaData.category)
                        .textCase(.uppercase)
                        .font(.caption)
                        .fontWeight(.light)
                    Text(asset.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .bold()
                }
                Spacer()
                if let loan = asset.loan {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(loan.metaData.term.toString()) @ \(loan.metaData.rate.formatted())%")
                            .textCase(.uppercase)
                            .font(.caption)
                            .fontWeight(.light)
                        Text(loan.amount.toString())
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .bold()
                    }
                }
            }
            if !asset.metaData.notes.isEmpty {
                Text(asset.metaData.notes)
                    .lineLimit(3)
                    .font(.subheadline)
                    .italic()
            }
        }.padding([.leading, .trailing], 28)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func loanPaymentSummary(_ loan: Asset.Loan) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Total Paid")
                        .font(.subheadline)
                        .opacity(0.6)
                    Text(loan.totalPaid.toString())
                        .bold()
                }
                VStack(alignment: .leading) {
                    Text("Principal Paid")
                        .font(.subheadline)
                        .opacity(0.6)
                    Text(loan.principalPaid.toString())
                        .bold()
                }
                VStack(alignment: .leading) {
                    Text("Remaining")
                        .font(.subheadline)
                        .opacity(0.6)
                    Text(loan.remainingAmount.toString())
                        .bold()
                }
            }
            let data: [(category: String, price: Double)] = [
                (category: "Principal", loan.principalPaid.toUsd()),
                (category: "Interest", loan.interestPaid.toUsd()),
                (category: "Other", loan.payments.map({ $0.escrow + $0.other }).reduce(.Cents(0), +).toUsd()),
            ]
            let colorMap: [String : Color] = [
                "Principal": Color.blue,
                "Interest": Color.orange,
            ]
            Spacer()
            Chart(data, id: \.category) { item in
                SectorMark(
                    angle: .value("Price", item.price),
                    innerRadius: .ratio(0.65),
                    angularInset: 2
                ).foregroundStyle(by: .value("Category", item.category))
                    .cornerRadius(4)
            }.frame(width: 180, height: 150)
                .chartLegend(position: .top, alignment: .trailing, spacing: 4)
                .chartForegroundStyleScale { type in
                    colorMap[type] ?? .gray
                }
        }
    }
    
    @ViewBuilder
    private func paymentsView(_ loan: Asset.Loan) -> some View {
        Section("Payments") {
            ForEach(loan.payments, id: \.hashValue) { payment in
                paymentEntry(payment)
                    .contextMenu {
                        Button("Edit") {
                            self.payment = .fromAsset(payment)
                            paymentIndex = asset.loan!.payments.firstIndex(where: { $0 == payment })!
                            showPaymentSheet = true
                        }
                    }
            }
            Button {
                payment = .init()
                paymentIndex = -1
                showPaymentSheet = true
            } label: {
                Label("Add Payment", systemImage: "plus")
            }
        }
    }
    
    @ViewBuilder
    private func paymentEntry(_ payment: Asset.Loan.Payment) -> some View {
        switch payment.type {
        case .Regular(_):
            regularPaymentEntry(payment)
        case .Principal(_):
            principalPaymentEntry(payment)
        }
    }
    
    @ViewBuilder
    private func regularPaymentEntry(_ payment: Asset.Loan.Payment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Regular")
                    Spacer()
                    Text("Total")
                }.font(.subheadline)
                    .opacity(0.6)
                HStack {
                    Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                    Text(payment.amount.toString())
                }.bold()
            }
            HStack(spacing: 16) {
                stackedText(text: "Principal", amount: payment.principal)
                stackedText(text: "Interest", amount: payment.interest)
                stackedText(text: "Escrow", amount: payment.escrow)
                stackedText(text: "Other", amount: payment.other)
            }
            if !payment.notes.isEmpty {
                Text(payment.notes)
                    .font(.subheadline)
                    .italic()
            }
        }
    }
    
    @ViewBuilder
    private func stackedText(text: String, amount: Price) -> some View {
        if amount.toCents() > 0 {
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.caption)
                    .opacity(0.6)
                Text(amount.toString())
                    .font(.subheadline)
                    .bold()
            }
        }
    }
    
    @ViewBuilder
    private func principalPaymentEntry(_ payment: Asset.Loan.Payment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Principal")
                    Spacer()
                    Text("Total")
                }.font(.subheadline)
                    .opacity(0.6)
                HStack {
                    Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                    Text(payment.amount.toString())
                }.bold()
            }
            if !payment.notes.isEmpty {
                Text(payment.notes)
                    .font(.subheadline)
                    .italic()
            }
        }
    }
    
    @ViewBuilder
    private func footerActionsView() -> some View {
        Grid {
            GridRow {
                Button {
                    navigationStore.push(AssetViewType.edit(asset: asset))
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                        .bold()
                        .frame(maxWidth: .infinity, maxHeight: 30)
                }.tint(.blue)
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .bold()
                        .frame(maxWidth: .infinity, maxHeight: 30)
                }
            }.gridColumnAlignment(.center)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle)
        }.padding([.leading, .trailing], 20)
            .padding([.top, .bottom], 8)
    }
    
    @ViewBuilder
    private func paymentSheet() -> some View {
        NavigationStack {
            PaymentEditSheet(payment: $payment)
                .navigationTitle(paymentIndex < 0 ? "Add Payment" : "Edit Payment")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showPaymentSheet = false
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save", action: savePayment)
                    }
                }
        }.presentationDetents([.medium])
    }
    
    private func savePayment() {
        if paymentIndex < 0 {
            asset.loan!.payments.append(payment.toAsset())
        } else {
            asset.loan!.payments[paymentIndex] = payment.toAsset()
        }
        showPaymentSheet = false
    }
    
    private func delete() {
        modelContext.delete(asset)
        navigationStore.pop()
    }
}

struct PaymentEditSheet: View {
    @Binding private var payment: Payment
    
    init(payment: Binding<Payment>) {
        self._payment = payment
    }
    
    var body: some View {
        Form {
            DatePicker("Date:", selection: $payment.date, displayedComponents: .date)
            TextField("Notes", text: $payment.notes, axis: .vertical)
                .lineLimit(1...3)
            Picker("", selection: $payment.type) {
                Text("Regular").tag(PaymentType.regular)
                Text("Principal").tag(PaymentType.principal)
            }.pickerStyle(.segmented)
            HStack {
                Text("Principal:")
                CurrencyField(value: $payment.principal)
            }
            if payment.type == .regular {
                HStack {
                    Text("Interest:")
                    CurrencyField(value: $payment.interest)
                }
                HStack {
                    Text("Escrow:")
                    CurrencyField(value: $payment.escrow)
                }
                HStack {
                    Text("Other:")
                    CurrencyField(value: $payment.other)
                }
            }
        }
    }
    
    enum PaymentType {
        case regular
        case principal
    }
    
    struct Payment {
        var date: Date
        var notes: String
        var type: PaymentType
        var principal: Int
        var interest: Int
        var escrow: Int
        var other: Int
        
        init(date: Date = .now,
             notes: String = "",
             type: PaymentType = .regular,
             principal: Int = 0,
             interest: Int = 0,
             escrow: Int = 0,
             other: Int = 0) {
            self.date = date
            self.notes = notes
            self.type = type
            self.principal = principal
            self.interest = interest
            self.escrow = escrow
            self.other = other
        }
        
        static func fromAsset(_ payment: Asset.Loan.Payment) -> Payment {
            switch payment.type {
            case .Regular(let details):
                return .init(date: payment.date,
                             notes: payment.notes,
                             type: .regular,
                             principal: details.principal.toCents(),
                             interest: details.interest.toCents(),
                             escrow: details.escrow.toCents(),
                             other: details.other.toCents())
            case .Principal(let amount):
                return .init(date: payment.date,
                             notes: payment.notes,
                             type: .principal,
                             principal: amount.toCents())
            }
        }
        
        func toAsset() -> Asset.Loan.Payment {
            switch type {
            case .regular:
                return .init(
                    date: date,
                    type: .Regular(
                        details: .init(
                            principal: .Cents(principal),
                            interest: .Cents(interest),
                            escrow: .Cents(escrow),
                            other: .Cents(other))),
                    notes: notes)
            case .principal:
                return .init(
                    date: date,
                    type: .Principal(principal: .Cents(principal)),
                    notes: notes)
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        AssetView(asset: .init(name: "332 Dovington Drive Mortgage",
                               totalCost: .Cents(30523199),
                               metaData: .init(category: "Housing", notes: "First house"),
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
                                            notes: "November payment"),
                                      .init(type: .Principal(principal: .Cents(65500)),
                                            notes: "Additional november payment")],
                                  metaData: .init(
                                      lender: "NBKC Bank",
                                      rate: 6.625,
                                      term: .Years(num: 30)))))
            .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
