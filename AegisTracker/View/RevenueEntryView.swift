//
//  RevenueEntryView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/20/24.
//

import SwiftUI

struct RevenueEntryView: View {
    let revenue: Revenue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(revenue.date.formatted(date: .abbreviated, time: .omitted))
                    .multilineTextAlignment(.leading)
                Spacer()
                Text(revenue.amount.toString())
                    .multilineTextAlignment(.trailing)
            }.bold()
            Text("\(revenue.payer) \(revenue.category)")
                .font(.subheadline)
                .italic()
                .multilineTextAlignment(.leading)
            if !revenue.notes.isEmpty {
                Text(revenue.notes)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

#Preview {
    Form {
        RevenueEntryView(revenue: .init(payer: "RMCI", amount: .Cents(233187), category: "Paycheck"))
        RevenueEntryView(revenue: .init(payer: "Carmax", amount: .Cents(250000), category: "Sale", notes: "Sold 2002 MDX"))
    }
}
