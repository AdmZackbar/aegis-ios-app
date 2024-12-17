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
    
    init(asset: Asset) {
        self.asset = asset
    }
    
    var body: some View {
        VStack(spacing: 4) {
            headerView()
            Form {
                if let loan = asset.loan {
                    Section {
                        paymentHeader(loan)
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
            }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        Text(asset.totalCost.toString())
            .font(.system(size: 40, weight: .bold, design: .rounded))
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                if let loan = asset.loan {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loan.metaData.category)
                            .textCase(.uppercase)
                            .font(.caption)
                            .fontWeight(.light)
                        Text(loan.metaData.lender)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .bold()
                    }
                }
                Spacer()
                Text(asset.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            if let loan = asset.loan {
                HStack {
                    Text("Loan: \(loan.amount.toString())")
                    Spacer()
                    Text("\(loan.metaData.term.toString()) @ \(loan.metaData.rate.formatted())%")
                }.font(.subheadline)
                    .italic()
            }
        }.padding([.leading, .trailing], 28)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func paymentHeader(_ loan: Asset.Loan) -> some View {
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
                (category: "Escrow", loan.payments.map({ $0.getEscrow() }).reduce(.Cents(0), +).toUsd()),
                (category: "Other", loan.payments.map({ $0.getOther() }).reduce(.Cents(0), +).toUsd())
            ]
            let colorMap: [String : Color] = [
                "Principal": Color.blue,
                "Interest": Color.orange,
                "Escrow": Color.yellow,
            ]
            Spacer()
            Chart(data, id: \.category) { item in
                SectorMark(
                    angle: .value("Price", item.price),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                ).foregroundStyle(by: .value("Category", item.category))
                    .cornerRadius(4)
            }.frame(width: 170, height: 100)
                .chartLegend(position: .trailing, alignment: .topTrailing, spacing: 4)
                .chartForegroundStyleScale { type in
                    colorMap[type] ?? .gray
                }
        }
    }
    
    @ViewBuilder
    private func paymentsView(_ loan: Asset.Loan) -> some View {
        Section("Payments") {
            ForEach(loan.payments, id: \.date.hashValue) { payment in
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                            .bold()
                        Text(payment.notes)
                            .font(.subheadline)
                            .italic()
                    }
                    Spacer()
                    Text(payment.getAmount().toString())
                        .bold()
                }
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
    
    private func delete() {
        modelContext.delete(asset)
        navigationStore.pop()
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        AssetView(asset: .init(name: "332 Dovington Drive Mortgage",
                               purchaseDate: Date(), totalCost: .Cents(30523199),
                               valuations: [.init(date: Date(), amount: .Cents(31023199))],
                               loan: .init(
                                  amount: .Cents(24531223),
                                  payments: [
                                      .init(date: .now,
                                            type: .Regular(
                                              details: .init(
                                                  principal: .Cents(30141),
                                                  interest: .Cents(158323),
                                                  escrow: .Cents(53623),
                                                  other: .Cents(0))),
                                            notes: "November payment"),
                                      .init(date: .now,
                                            type: .Principal(principal: .Cents(65500)),
                                            notes: "Additional november payment")],
                                  metaData: .init(
                                      lender: "NBKC Bank",
                                      rate: 6.625,
                                      term: .Years(num: 30),
                                      category: "Housing"))))
            .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
