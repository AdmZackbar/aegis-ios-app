//
//  EditLoanView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/28/24.
//

import SwiftData
import SwiftUI

struct EditLoanView: View {
    @Environment(\.modelContext) var modelContext
    
    private let mode: Mode
    private let loan: Loan
    
    @Binding private var path: [ViewType]
    @State private var name: String = ""
    @State private var startDate: Date = .now
    @State private var amount: Int = 0
    @State private var lender: String = ""
    @State private var rate: Double = 0.0
    @State private var years: Int = 30
    @State private var category: String = ""
    
    init(path: Binding<[ViewType]>, loan: Loan? = nil) {
        self._path = path
        self.loan = loan ?? .init(name: "", startDate: .now, amount: .Cents(0), metaData: .init(lender: "", rate: 0.0, term: .Years(num: 30), category: ""))
        mode = loan == nil ? .Add : .Edit
    }
    
    var body: some View {
        Form {
            TextField("Name", text: $name)
            HStack {
                Text("Amount:")
                CurrencyField(value: $amount)
            }
            DatePicker("Start Date:", selection: $startDate, displayedComponents: .date)
            TextField("Lender", text: $lender)
            let percentFormatter = {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 3
                formatter.zeroSymbol = ""
                return formatter
            }()
            HStack {
                TextField("Rate:", value: $rate, formatter: percentFormatter)
                if rate > 0 {
                    Text("%")
                }
            }
            let intFormatter = {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 0
                return formatter
            }()
            HStack {
                TextField("Term Length", value: $years, formatter: intFormatter)
                Text("Years")
            }
        }.navigationTitle(mode.getTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear(perform: load)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: back)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: save)
                        .disabled(name.isEmpty || amount <= 0 || lender.isEmpty || rate <= 0 || years <= 0)
                }
            }
    }
    
    private func load() {
        if mode == .Edit {
            name = loan.name
            startDate = loan.startDate
            switch loan.amount {
            case .Cents(let cents):
                amount = cents
            }
            lender = loan.metaData.lender
            rate = loan.metaData.rate
            switch loan.metaData.term {
            case .Years(let num):
                years = num
            }
            category = loan.metaData.category
        }
    }
    
    private func back() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    private func save() {
        loan.name = name
        loan.startDate = startDate
        loan.amount = .Cents(amount)
        loan.metaData = .init(lender: lender, rate: rate, term: .Years(num: years), category: category)
        if mode == .Add {
            modelContext.insert(loan)
        }
        back()
        path.append(.ViewLoan(loan: loan))
    }
    
    private enum Mode {
        case Add, Edit
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Loan"
            case .Edit:
                "Edit Loan"
            }
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let loan = addTestLoan(container.mainContext)
    return NavigationStack {
        EditLoanView(path: .constant([]), loan: loan)
    }.modelContainer(container)
}
