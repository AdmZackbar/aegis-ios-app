//
//  PurchasesView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/10/24.
//

import SwiftData
import SwiftUI

struct PurchaseListView: View {
    @Query(sort: \Purchase.date, order: .reverse) var purchases: [Purchase]
    
    @Binding private var path: [ViewType]
    
    init(path: Binding<[ViewType]>) {
        self._path = path
    }
    
    var body: some View {
        let purchasesDict = {
            var dict: [Date: [Purchase]] = [:]
            for purchase in purchases {
                dict[Calendar.current.startOfDay(for: purchase.date), default: []].append(purchase)
            }
            return dict
        }()
        Form {
            ForEach(purchasesDict.sorted(by: { $0.key > $1.key }), id: \.key) { date, purchases in
                Section(date.formatted(date: .long, time: .omitted)) {
                    purchaseList(purchases)
                }
            }
        }.navigationTitle("Purchases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(value: ViewType.AddPurchase) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
    }
    
    @ViewBuilder
    private func purchaseList(_ purchases: [Purchase]) -> some View {
        ForEach(purchases.sorted(by: { $0.seller < $1.seller }), id: \.hashValue) { purchase in
            purchaseItem(purchase)
                .contextMenu {
                    Button {
                        
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                }
        }
    }
    
    @ViewBuilder
    private func purchaseItem(_ purchase: Purchase) -> some View {
        switch purchase.category {
        case .Basic(let name, _):
            HStack(alignment: .top) {
                nameInfoView(category: name, seller: purchase.seller)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(purchase.price.toString()).bold()
                }
            }
        case .Gas(let numGallons, let costPerGallon, let octane):
            let formatter: NumberFormatter = {
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 1
                return formatter
            }()
            HStack(alignment: .top) {
                nameInfoView(category: "Gas", seller: purchase.seller)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(purchase.price.toString()).bold()
                    Text("\(formatter.string(for: numGallons)!) gal (\(formatter.string(for: octane)!)) @ \(costPerGallon.toString())").font(.subheadline).italic()
                }
            }
        case .Groceries(let items):
            DisclosureGroup {
                Text("Test")
            } label: {
                Text("Temp")
            }
        case .Restaurant(_, let tip):
            HStack(alignment: .top) {
                nameInfoView(category: "Restaurant", seller: purchase.seller)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(purchase.price.toString()).bold()
                    Text("\(tip.toString()) tip").font(.subheadline).italic()
                }
            }
        case .Software(let name):
            HStack(alignment: .top) {
                nameInfoView(category: "Computer Software", seller: "\(purchase.seller) | \(name)")
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(purchase.price.toString()).bold()
                }
            }
        case .Hardware(let name):
            HStack(alignment: .top) {
                nameInfoView(category: "Computer Hardware", seller: "\(name) @ \(purchase.seller)")
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(purchase.price.toString()).bold()
                }
            }
        default:
            HStack(alignment: .top) {
                nameInfoView(category: "Unknown", seller: purchase.seller)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(purchase.price.toString()).bold()
                }
            }
        }
    }
    
    @ViewBuilder
    private func nameInfoView(category: String, seller: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category).bold()
            Text(seller).font(.subheadline).italic()
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    return NavigationStack {
        PurchaseListView(path: .constant([]))
    }.modelContainer(container)
}

//.Groceries(items: [
//    .init(name: "Frozen Chicken Breasts", category: .Meat, price: .Cents(2399), quantity: 2),
//    .init(name: "Mission Tortilla", category: .Carbs, price: .Cents(599), quantity: 1)
//])
