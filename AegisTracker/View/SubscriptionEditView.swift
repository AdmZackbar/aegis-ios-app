//
//  SubscriptionEditView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import SwiftData
import SwiftUI

extension [SubscriptionEditView.Period] {
    var invalid: Bool {
        self.isEmpty || self.contains(where: { $0.invalid }) || (self.filter({ $0.active }).count > 1)
    }
}

struct SubscriptionEditView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    private let subscription: Subscription
    private let mode: Mode
    
    // Main
    @State private var payee: String = ""
    @State private var category: String = ""
    @State private var periods: [Period] = []
    @State private var notes: String = ""
    
    init(subscription: Subscription? = nil, mode: Mode? = nil) {
        self.subscription = subscription ?? .init()
        self.mode = mode ?? (subscription == nil ? .Add : .Edit)
    }
    
    var body: some View {
        let categories = Set(MainView.MainExpenseCategories + expenses.map({ $0.category })).sorted()
        Form {
            Section("Details") {
                HStack {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Payee:")
                    TextField("required", text: $payee)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
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
            periodsView()
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
                        .disabled(payee.isEmpty || periods.invalid || category.isEmpty)
                }
            }
    }
    
    private func categoryDropDownMenu() -> some View {
        Menu {
            ForEach(MainView.MainExpenseCategories, id: \.hashValue) { category in
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
    
    @ViewBuilder
    func periodsView() -> some View {
        Button {
            periods.append(.init())
        } label: {
            Label("Add Period", systemImage: "plus")
        }
        ForEach($periods.reversed()) { $period in
            Section {
                DatePicker(selection: $period.start, displayedComponents: .date) {
                    HStack {
                        Image(systemName: "calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("Start Date:")
                    }
                }
                if !period.active {
                    DatePicker(selection: $period.end, displayedComponents: .date) {
                        HStack {
                            Image(systemName: "calendar")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("End Date:")
                        }
                    }
                }
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Amount:")
                    CurrencyField(value: $period.amount)
                }
                TextField("Notes", text: $period.notes, axis: .vertical)
                    .lineLimit(1...6)
                    .textInputAutocapitalization(.sentences)
            } header: {
                Toggle("Active", isOn: $period.active)
            }
        }
    }
    
    private func back() {
        navigationStore.pop()
    }
    
    private func load() {
        payee = subscription.payee
        category = subscription.category
        notes = subscription.notes
        periods = subscription.periods.map(Period.init)
    }
    
    private func save() {
        subscription.payee = payee
        subscription.category = category
        subscription.notes = notes
        subscription.periods = periods.map({ $0.toModel() })
            .sorted(by: { $0.startDate < $1.startDate })
        if mode == .Add {
            modelContext.insert(subscription)
        }
        back()
    }
    
    enum Mode {
        case Add
        case Edit
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Subscription"
            case .Edit:
                "Edit Subscription"
            }
        }
    }
    
    struct Period: Identifiable, Hashable, Equatable {
        let id: UUID = .init()
        var start: Date
        var active: Bool
        var end: Date
        var type: Subscription.PeriodType
        var amount: Int
        var notes: String
        
        init() {
            self.start = .now
            self.end = .now
            self.active = true
            self.type = .monthly
            self.amount = 0
            self.notes = ""
        }
        
        init(period: Subscription.Period) {
            start = period.startDate
            end = period.endDate ?? .now
            active = period.endDate == nil
            type = period.type
            amount = period.amount.toCents()
            notes = period.notes
        }
        
        var invalid: Bool {
            (!active && start > end) || amount <= 0
        }
        
        func toModel() -> Subscription.Period {
            .init(startDate: start, endDate: active ? nil : end, type: type, amount: .Cents(amount), notes: notes)
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionEditView()
    }
}
