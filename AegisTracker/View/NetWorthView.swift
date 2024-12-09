//
//  NetWorthView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/29/24.
//

import SwiftData
import SwiftUI

struct NetWorthView: View {
    @Query(sort: \Loan.startDate, order: .reverse) var loans: [Loan]
    
    @Binding private var path: [ViewType]
    
    init(path: Binding<[ViewType]>) {
        self._path = path
    }
    
    var body: some View {
        let net = .Cents(0) - loans.map({ $0.remainingAmount }).reduce(.Cents(0), +)
        ScrollView {
            VStack {
                Text(net.toString())
                    .font(.title).bold()
                    .foregroundStyle(net.toUsd() >= 0 ? .green : .red)
                    .padding()
                HStack {
                    Text("Liabilities")
                        .font(.title2).bold()
                    Spacer()
                }
                ForEach(loans, id: \.hashValue) { loan in
                    Button {
                        path.append(.ViewLoan(loan: loan))
                    } label: {
                        HStack(alignment: .top) {
                            Text(loan.name)
                            Spacer()
                            Text(loan.amount.toString()).italic()
                        }.padding()
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }.padding()
        }.navigationTitle("Net Worth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        path.append(.AddLoan)
                    } label: {
                        Label("Add Loan", systemImage: "plus")
                    }
                }
            }
    }
}

#Preview {
    let container = createTestModelContainer()
    addTestLoan(container.mainContext)
    return NavigationStack {
        NetWorthView(path: .constant([]))
    }.modelContainer(container)
}
