//
//  FinancedExpenseEditView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import SwiftData
import SwiftUI

struct FinancedExpenseEditView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    @Query(sort: \ExpenseTag.name) var existingTags: [ExpenseTag]
    
    private let expense: FinancedExpense
    private let mode: Mode
    
    // Main
    @State private var date: Date = .now
    @State private var amount: Int = 0
    @State private var payee: String = ""
    @State private var category: String = ""
    @State private var notes: String = ""
    @State private var tags: [ExpenseTag] = []
    @State private var tag: String = ""
    @State private var showTag: Bool = false
    @State private var paymentPlan: PaymentPlan = .acmi
    @State private var numMonths: Int = 12
    
    init(expense: FinancedExpense? = nil, mode: Mode? = nil) {
        self.expense = expense ?? .init()
        self.mode = mode ?? (expense == nil ? .Add : .Edit)
    }
    
    var body: some View {
        let payees = Set(expenses.map({ $0.payee })).sorted()
        let categories = Set(MainView.MainExpenseCategories + expenses.map({ $0.category })).sorted()
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
                    Text("Payee:")
                    TextField("required", text: $payee)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                payeeAutoCompleteView(payees)
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
                tagsView()
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...9)
                    .textInputAutocapitalization(.sentences)
            }
            paymentPlanView()
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
                        .disabled(payee.isEmpty || amount <= 0 || category.isEmpty)
                }
            }
    }
    
    @ViewBuilder
    private func payeeAutoCompleteView(_ payees: [String]) -> some View {
        if !payee.isEmpty && !payees.contains(payee) {
            let options = getFilteredEntries(payee, payees)
            if !options.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(options, id: \.self) { name in
                            Button(name) {
                                self.payee = name
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
    private func tagsView() -> some View {
        if !tags.isEmpty {
            HStack {
                Image(systemName: "rectangle.3.group.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags) { tag in
                            Text(tag.name)
                                .bold()
                            Divider()
                        }
                    }
                }.contextMenu {
                    ForEach(tags) { tag in
                        Button("Remove '\(tag.name)'") {
                            tags.removeAll(where: { $0 == tag })
                        }
                    }
                    if tags.count > 1 {
                        Divider()
                        Button("Remove All") {
                            tags.removeAll()
                        }
                    }
                }
                Button {
                    showTag = true
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }.disabled(showTag)
            }
            if (showTag) {
                tagView()
            }
        } else {
            tagView()
        }
    }
    
    @ViewBuilder
    private func tagView() -> some View {
        VStack {
            HStack {
                if (tags.isEmpty) {
                    Image(systemName: "rectangle.3.group.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                Text(tags.isEmpty ? "Group:" : "New Group:")
                TextField("optional", text: $tag)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        if tag.isEmpty {
                            return
                        }
                        let t = existingTags.first(where: { $0.name == tag }) ?? ExpenseTag(name: tag)
                        tags.insert(t, at: 0)
                        showTag = false
                        tag = ""
                    }
            }
            if !tag.isEmpty {
                let filteredTags = getFilteredTags(tag)
                if !filteredTags.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(filteredTags, id: \.self) { t in
                                Button {
                                    tags.insert(t, at: 0)
                                    showTag = false
                                    tag = ""
                                } label: {
                                    Text(t.name)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getFilteredTags(_ text: String) -> [ExpenseTag] {
        existingTags.filter({ $0.name.localizedCaseInsensitiveContains(text) }).sorted { $0.name < $1.name }
    }
    
    @ViewBuilder
    func paymentPlanView() -> some View {
        Section {
            Picker("Type:", selection: $paymentPlan) {
                ForEach(PaymentPlan.allCases, id: \.text) { plan in
                    Text(plan.text).tag(plan)
                }
            }
            switch paymentPlan {
            case .acmi:
                Stepper("\(numMonths) Months", value: $numMonths, in: 1...72)
            }
        } header: {
            Text("Payment Plan")
        } footer: {
            switch paymentPlan {
            case .acmi:
                Text("Monthly Payment: \((Price.Cents(amount) / Double(numMonths)).toString())")
            }
        }
    }
    
    private func back() {
        navigationStore.pop()
    }
    
    private func load() {
        date = expense.date
        payee = expense.payee
        amount = expense.amount.toCents()
        category = expense.category
        notes = expense.notes
        tags = expense.tags
        switch expense.paymentPlan {
        case .acmi(let n):
            paymentPlan = .acmi
            numMonths = n
        }
    }
    
    private func save() {
        expense.date = date
        expense.payee = payee
        expense.amount = .Cents(amount)
        expense.category = category
        expense.notes = notes
        expense.tags = tags
        switch paymentPlan {
        case .acmi:
            expense.paymentPlan = .acmi(numMonths: numMonths)
        }
        if mode == .Add {
            modelContext.insert(expense)
        }
        back()
    }
    
    enum Mode {
        case Add
        case Edit
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Expense"
            case .Edit:
                "Edit Expense"
            }
        }
    }
    
    enum PaymentPlan: CaseIterable {
        case acmi
        
        var text: String {
            switch self {
            case .acmi:
                return "Apple Card Monthly Installments"
            }
        }
    }
}

#Preview {
    FinancedExpenseEditView()
}
