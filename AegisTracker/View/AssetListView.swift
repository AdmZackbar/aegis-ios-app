//
//  AssetListView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/16/24.
//

import SwiftData
import SwiftUI

extension Asset.Loan.MetaData.Term {
    func toString() -> String {
        switch self {
        case .Years(let num):
            return "\(num) years"
        }
    }
}

struct AssetListView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Asset.purchaseDate, order: .reverse) var assets: [Asset]
    
    var body: some View {
        Form {
            ForEach(assets, id: \.hashValue) { asset in
                Button {
                    // TODO
                } label: {
                    assetView(asset).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }.navigationTitle("Assets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // TODO
                    } label: {
                        Label("Add Asset", systemImage: "plus")
                    }
                }
            }
    }
    
    @ViewBuilder
    func assetView(_ asset: Asset) -> some View {
        if let loan = asset.loan {
            assetLoanView(asset, loan)
        } else {
            VStack(alignment: .leading) {
                Text(asset.name).bold()
                Text(asset.totalCost.toString())
                    .font(.subheadline)
            }.bold()
        }
    }
    
    @ViewBuilder
    func assetLoanView(_ asset: Asset, _ loan: Asset.Loan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(asset.name)
                .font(.title3)
                .bold()
            Divider()
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Image(systemName: "tag.fill")
                        Text(loan.metaData.category)
                            .bold()
                    }
                    Text(loan.metaData.lender)
                        .italic()
                    Text("\(loan.metaData.term.toString()) @ \(loan.metaData.rate.formatted())%")
                        .italic()
                }.font(.subheadline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(asset.totalCost.toString())
                    Text("-\(loan.remainingAmount.toString())")
                        .foregroundStyle(.red)
                    Text((asset.totalCost - loan.remainingAmount).toString())
                }.font(.subheadline).bold()
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        AssetListView()
            .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
