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
                        path.append(.EditPurchase(purchase: purchase))
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                }
        }
    }
    
    @ViewBuilder
    private func purchaseItem(_ purchase: Purchase) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(purchase.category.getName()).bold()
                Spacer()
                Text(purchase.price.toString()).bold()
            }
            switch purchase.category {
            case .Basic(_, let details):
                Text(purchase.seller).font(.subheadline).italic()
                if !details.isEmpty {
                    Text(details).font(.caption)
                }
            case .Gas(let numGallons, let costPerGallon, let octane):
                let formatter: NumberFormatter = {
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 1
                    return formatter
                }()
                HStack(alignment: .top) {
                    Text(purchase.seller).font(.subheadline).italic()
                    Spacer()
                    Text("\(formatter.string(for: numGallons)!) gal (\(formatter.string(for: octane)!)) @ \(costPerGallon.toString())")
                        .font(.subheadline).italic()
                }
            case .Groceries(let items):
                DisclosureGroup {
                    Text("Test")
                } label: {
                    Text("Temp")
                }
            case .Restaurant(_, let tip):
                HStack(alignment: .top) {
                    Text(purchase.seller).font(.subheadline).italic()
                    Spacer()
                    Text("\(tip.toString()) tip").font(.subheadline).italic()
                }
            case .Hardware(let name):
                Text("\(purchase.seller) | \(name)").font(.subheadline).italic()
            case .Software(let name):
                Text("\(purchase.seller) | \(name)").font(.subheadline).italic()
            default:
                Text(purchase.seller).font(.subheadline).italic()
            }
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    container.mainContext.insert(Purchase(date: Date(), category: .Gas(numGallons: 9.1, costPerGallon: .Cents(254), octane: 87), seller: "Costco", price: .Cents(3591)))
    container.mainContext.insert(Purchase(date: Date(), category: .Hardware(name: "4 TB M.2 SSD"), seller: "Amazon", price: .Cents(39127)))
    container.mainContext.insert(Purchase(date: Date(), category: .Software(name: "Photoshop"), seller: "Adobe", price: .Cents(999)))
    container.mainContext.insert(Purchase(date: Date(), category: .Restaurant(details: "Day trip to Rocktown", tip: .Cents(250)), seller: "Mentone Cafe", price: .Cents(980)))
    container.mainContext.insert(Purchase(date: Date(), category: .Basic(name: "Other", details: "Testing the other category"), seller: "Amazon", price: .Cents(1391)))
    return NavigationStack {
        PurchaseListView(path: .constant([]))
    }.modelContainer(container)
}

//.Groceries(items: [
//    .init(name: "Frozen Chicken Breasts", category: .Meat, price: .Cents(2399), quantity: 2),
//    .init(name: "Mission Tortilla", category: .Carbs, price: .Cents(599), quantity: 1)
//])
