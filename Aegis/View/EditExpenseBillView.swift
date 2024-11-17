//
//  EditExpenseBillView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/17/24.
//

import SwiftUI

struct EditExpenseBillView: View {
    enum BillType: Codable, Equatable, Hashable {
        case Flat
        case Variable
    }
    
    let detailPlaceholder: String
    
    @Binding private var details: Details
    @State private var typeDetails: TypeDetails = TypeDetails()
    @State private var itemIndex: Int = -1
    @State private var sheetShowing: Bool = false
    
    init(details: Binding<Details>, detailPlaceholder: String) {
        self._details = details
        self.detailPlaceholder = detailPlaceholder
    }
    
    var body: some View {
        HStack {
            Text("Tax:")
            CurrencyTextField(numberFormatter: MainView.CurrencyFormatter, value: $details.tax)
        }
        TextField(detailPlaceholder, text: $details.details, axis: .vertical)
            .lineLimit(3...9)
        ForEach(details.types, id: \.hashValue, content: billTypeEntry)
        Button("Add Charge") {
            typeDetails = TypeDetails()
            itemIndex = -1
            sheetShowing = true
        }.sheet(isPresented: $sheetShowing, content: billTypeSheet)
    }
    
    private func billTypeEntry(_ type: TypeDetails) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(type.name).bold()
                Text("Base Charge: \(Price.Cents(type.base).toString())")
                    .font(.subheadline).italic()
                if type.type == .Variable {
                    Text("Amount: \(type.amount.formatted())").font(.caption).italic()
                    Text("Rate: \(type.rate.formatted())").font(.caption).italic()
                }
            }
            Spacer()
            Button("Edit") {
                itemIndex = details.types.firstIndex(of: type)!
                typeDetails = type
                sheetShowing = true
            }
        }
    }
    
    private func billTypeSheet() -> some View {
        NavigationStack {
            Form {
                BillTypeView(typeDetails: $typeDetails)
            }.navigationTitle(itemIndex < 0 ? "Add Bill" : "Edit Bill")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            sheetShowing = false
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            if itemIndex >= 0 && itemIndex < details.types.count {
                                details.types[itemIndex] = typeDetails
                            } else {
                                details.types.append(typeDetails)
                            }
                            sheetShowing = false
                        }
                    }
                }
        }.presentationDetents([.height(340)])
    }
    
    struct BillTypeView: View {
        @Binding private var typeDetails: TypeDetails
        
        private let formatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 7
            formatter.zeroSymbol = ""
            return formatter
        }()
        private let names: [String] = ["Electric", "Water", "Sewer", "Trash", "Internet", "Other"]
        
        init(typeDetails: Binding<TypeDetails>) {
            self._typeDetails = typeDetails
        }
        
        var body: some View {
            HStack {
                Text("Type:")
                Picker("", selection: $typeDetails.type) {
                    Text("Flat").tag(BillType.Flat)
                    Text("Variable").tag(BillType.Variable)
                }.pickerStyle(.segmented)
            }
            Picker("Name:", selection: $typeDetails.name) {
                ForEach(names, id: \.hashValue) { name in
                    Text(name).tag(name)
                }
            }
            HStack {
                Text("Base Charge:")
                CurrencyTextField(numberFormatter: MainView.CurrencyFormatter, value: $typeDetails.base)
            }
            if typeDetails.type == .Variable {
                HStack {
                    Text("Usage:")
                    TextField("", value: $typeDetails.amount, formatter: formatter)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Rate:")
                    TextField("", value: $typeDetails.rate, formatter: formatter)
                        .keyboardType(.decimalPad)
                }
            }
        }
    }
    
    struct TypeDetails: Codable, Hashable, Equatable {
        var type: BillType = .Flat
        var name: String = "Electric"
        var base: Int = 0
        var amount: Double = 0.0
        var rate: Double = 0.0
    }
    
    struct Details {
        var types: [TypeDetails] = []
        var tax: Int = 0
        var details: String = ""
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Bill(let details):
                switch details.tax {
                case .Cents(let cents):
                    return Details(types: details.types.map(toType), tax: cents, details: details.details)
                }
            default:
                return Details()
            }
        }
        
        private static func toType(_ type: Expense.BillType) -> TypeDetails {
            switch type {
            case .Flat(let name, let base):
                switch base {
                case .Cents(let cents):
                    return .init(type: .Flat, name: name, base: cents)
                }
            case .Variable(let name, let base, let amount, let rate):
                switch base {
                case .Cents(let cents):
                    return .init(type: .Variable, name: name, base: cents, amount: amount, rate: rate)
                }
            }
        }
        
        func toExpense() -> Expense.Details {
            return .Bill(details: .init(types: types.map(toBillType), tax: .Cents(tax), details: details))
        }
        
        private func toBillType(_ type: TypeDetails) -> Expense.BillType {
            switch type.type {
            case .Flat:
                return .Flat(name: type.name, base: .Cents(type.base))
            case .Variable:
                return .Variable(name: type.name, base: .Cents(type.base), amount: type.amount, rate: type.rate)
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditExpenseView(path: .constant([]), expense: .init(date: .now, payee: "HSV Utils", amount: .Cents(10234), category: "Utility Bill", details: .Bill(details: .init(types: [.Variable(name: "Electric", base: .Cents(3552), amount: 462, rate: 0.00231), .Flat(name: "Trash", base: .Cents(1423))], tax: .Cents(255),details: "November bill"))))
    }
}
