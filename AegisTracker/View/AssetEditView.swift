//
//  AssetEditView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/17/24.
//

import SwiftData
import SwiftUI

struct AssetEditView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    private let asset: Asset
    private let mode: Mode
    
    @State private var name: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var totalCost: Int = 0
    @State private var category: String = ""
    @State private var notes: String = ""
    // Loan
    @State private var hasLoan: Bool = false
    @State private var lender: String = ""
    @State private var loanAmount: Int = 0
    @State private var rate: Double = 0
    @State private var termYears: Int = 30
    
    init(asset: Asset? = nil) {
        self.asset = asset ?? .init()
        self.mode = asset == nil ? .Add : .Edit
    }
    
    var body: some View {
        Form {
            Section("Asset") {
                HStack {
                    Text("Name:")
                    TextField("required", text: $name)
                        .textInputAutocapitalization(.words)
                }
                DatePicker("Purchased:", selection: $purchaseDate, displayedComponents: .date)
                HStack {
                    Text("Total Price:")
                    CurrencyField(value: $totalCost)
                }
                HStack {
                    Text("Category:")
                    TextField("required", text: $category)
                        .textInputAutocapitalization(.words)
                }
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
                Toggle("Loan:", isOn: $hasLoan)
            }
            if hasLoan {
                Section("Loan") {
                    HStack {
                        Text("Amount:")
                        CurrencyField(value: $loanAmount)
                    }
                    HStack {
                        Text("Lender:")
                        TextField("required", text: $lender)
                            .textInputAutocapitalization(.words)
                    }
                    let formatter = {
                        let f = NumberFormatter()
                        f.maximumFractionDigits = 3
                        f.zeroSymbol = ""
                        return f
                    }()
                    HStack {
                        HStack {
                            Text("Rate:")
                            TextField("", value: $rate, formatter: formatter)
                                .keyboardType(.decimalPad)
                            Text("%")
                        }.frame(width: 150)
                        Divider()
                        Picker("Term", selection: $termYears) {
                            Text("15 Year").tag(15)
                            Text("30 Year").tag(30)
                        }.pickerStyle(.segmented)
                    }
                }
            }
        }.navigationTitle(mode.getTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear(perform: load)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        navigationStore.pop()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        save()
                        navigationStore.pop()
                    }.disabled(saveDisabled())
                }
            }
    }
    
    private func saveDisabled() -> Bool {
        mainInvalid() || loanInvalid()
    }
    
    private func mainInvalid() -> Bool {
        name.isEmpty || purchaseDate > .now || totalCost <= 0 || category.isEmpty
    }
    
    private func loanInvalid() -> Bool {
        guard hasLoan else {
            return false
        }
        return loanAmount <= 0 || lender.isEmpty || rate <= 0 || termYears <= 0
    }
    
    private func load() {
        self.name = asset.name
        self.purchaseDate = asset.purchaseDate
        self.totalCost = asset.totalCost.toCents()
        self.category = asset.metaData.category
        self.notes = asset.metaData.notes
        // Loan
        self.hasLoan = asset.loan != nil
        self.loanAmount = asset.loan?.amount.toCents() ?? 0
        self.lender = asset.loan?.metaData.lender ?? ""
        self.rate = asset.loan?.metaData.rate ?? 0
        self.termYears = {
            switch asset.loan?.metaData.term {
            case .Years(let num):
                num
            case nil:
                0
            }
        }()
    }
    
    private func save() {
        asset.name = name
        asset.purchaseDate = purchaseDate
        asset.totalCost = .Cents(totalCost)
        asset.metaData = .init(category: category, notes: notes)
        // Loan
        if hasLoan {
            if asset.loan == nil {
                asset.loan = .init()
            }
            asset.loan = .init(
                amount: .Cents(loanAmount),
                metaData: .init(lender: lender, rate: rate, term: .Years(num: termYears)))
        } else {
            asset.loan = nil
        }
        if mode == .Add {
            modelContext.insert(asset)
        }
    }
    
    enum Mode {
        case Add
        case Edit
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Asset"
            case .Edit:
                "Edit Asset"
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        AssetEditView()
            .navigationDestination(for: ViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RecordType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
