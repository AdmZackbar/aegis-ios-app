//
//  RevenueEditView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/20/24.
//

import SwiftData
import SwiftUI

struct RevenueEditView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Revenue.date, order: .reverse) var revenues: [Revenue]
    
    private let revenue: Revenue
    private let mode: Mode
    
    @State private var date: Date = .now
    @State private var amount: Int = 0
    @State private var payer: String = ""
    @State private var category: String = ""
    @State private var notes: String = ""
    
    init(revenue: Revenue? = nil, mode: Mode? = nil) {
        self.revenue = revenue ?? .init()
        self.mode = mode ?? (revenue == nil ? .Add : .Edit)
    }
    
    var body: some View {
        let payers = Set(revenues.map({ $0.payer })).sorted()
        let categories = Set(revenues.map({ $0.category })).sorted()
        Form {
            Section("Details") {
                DatePicker(selection: $date, displayedComponents: .date) {
                    HStack {
                        Image(systemName: "calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("Date:")
                    }
                }
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Amount:")
                    CurrencyField(value: $amount)
                }
                HStack {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Payer:")
                    TextField("required", text: $payer)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                payerAutoCompleteView(payers)
                HStack {
                    Image(systemName: "tag.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Category:")
                    TextField("required", text: $category)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    categoryDropDownMenu()
                }
                categoryAutoCompleteView(categories)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...9)
                    .textInputAutocapitalization(.sentences)
            }
        }.navigationTitle(mode.getTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear(perform: load)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back", action: back)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: save)
                }
            }
    }
    
    @ViewBuilder
    private func payerAutoCompleteView(_ payers: [String]) -> some View {
        if !payer.isEmpty && !payers.contains(payer) {
            let options = getFilteredEntries(payer, payers)
            if !options.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(options, id: \.self) { name in
                            Button(name) {
                                self.payer = name
                            }.padding([.leading, .trailing], 4)
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private func categoryDropDownMenu() -> some View {
        Menu {
            ForEach(MainView.RevenueCategories, id: \.hashValue) { category in
                Button(category) {
                    self.category = category
                }
            }
        } label: {
            VStack(spacing: 5){
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
    }
    
    @ViewBuilder
    private func categoryAutoCompleteView(_ categories: [String]) -> some View {
        if !category.isEmpty && !categories.contains(category) {
            let options = getFilteredEntries(category, categories)
            if !options.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(options, id: \.self) { name in
                            Button(name) {
                                self.category = name
                            }.padding([.leading, .trailing], 4)
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private func getFilteredEntries(_ text: String, _ entries: [String]) -> [String] {
        entries.filter({ $0.localizedCaseInsensitiveContains(text) }).sorted()
    }
    
    private func back() {
        navigationStore.pop()
    }
    
    private func load() {
        date = revenue.date
        payer = revenue.payer
        amount = revenue.amount.toCents()
        category = revenue.category
        notes = revenue.notes
    }
    
    private func save() {
        revenue.date = date
        revenue.payer = payer
        revenue.amount = .Cents(amount)
        revenue.category = category
        revenue.notes = notes
        if mode == .Add {
            modelContext.insert(revenue)
        }
        back()
    }
    
    enum Mode {
        case Add
        case Edit
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Revenue"
            case .Edit:
                "Edit Revenue"
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    return NavigationStack(path: $navigationStore.path) {
        RevenueEditView(revenue: .init(payer: "RMCI", amount: .Cents(2345), category: "Paycheck"))
            .navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
