//
//  ExpenseView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/12/24.
//

import SwiftData
import SwiftUI

struct ExpenseView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    
    let expense: Expense
    
    @Binding private var path: [ViewType]
    @State private var showDelete: Bool = false
    
    init(path: Binding<[ViewType]>, expense: Expense) {
        self._path = path
        self.expense = expense
    }
    
    var body: some View {
        VStack(spacing: 4) {
            headerView()
            Form {
                detailView()
                let relatedExpenses = expenses.filter({ $0.payee == expense.payee && $0 != expense })
                if !relatedExpenses.isEmpty {
                    payeeExpenseList(relatedExpenses)
                }
            }.scrollContentBackground(.hidden)
            footerActionsView()
        }.navigationTitle("View Expense")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.init(uiColor: UIColor.systemGroupedBackground))
            .confirmationDialog("Are you sure you want to delete this expense?", isPresented: $showDelete) {
                Button("Delete", role: .destructive, action: delete)
            } message: {
                Text("You cannot undo this action")
            }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        Text(expense.amount.toString())
            .font(.system(size: 48, weight: .bold, design: .rounded))
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(expense.category)
                            .textCase(.uppercase)
                            .font(.caption)
                            .fontWeight(.light)
                    }
                    Text(expense.payee)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .bold()
                }
                Spacer()
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            if !expense.notes.isEmpty {
                Text(expense.notes)
                    .font(.subheadline)
                    .lineLimit(5)
            }
        }.padding([.leading, .trailing], 28)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func detailView() -> some View {
        switch expense.details {
        case .Tag(let name):
            HStack {
                Text("Tag:").bold()
                Spacer()
                Text(name).italic()
            }
        case .Tip(let amount):
            HStack {
                Text("Tip:").bold()
                Spacer()
                Text(amount.toString()).italic()
            }
        case .Fuel(let details):
            VStack(alignment: .leading, spacing: 4) {
                Text(details.user).bold()
                HStack {
                    Text("\(details.amount.formatted()) gallons")
                    Spacer()
                    Text("\(details.rate.formatted()) $/gal").italic()
                }
            }
        case .Foods(let list):
            if !list.foods.isEmpty {
                Section("Foods") {
                    ForEach(list.foods, id: \.hashValue) { food in
                        HStack {
                            Text(food.name).bold()
                            Spacer()
                            Text(food.totalPrice.toString()).italic()
                        }
                    }
                }
            }
        case .Bill(let details):
            if !details.bills.isEmpty {
                Section("Bills") {
                    ForEach(details.bills, id: \.hashValue) { bill in
                        HStack {
                            Text(bill.getName()).bold()
                            Spacer()
                            Text(bill.getTotal().toString()).italic()
                        }
                    }
                }
            }
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func payeeExpenseList(_ expenses: [Expense]) -> some View {
        Section("\(expense.payee) Expenses") {
            ForEach(expenses, id: \.hashValue) { e in
                Button {
                    path.append(.ViewExpense(expense: e))
                } label: {
                    HStack {
                        Text(e.date.formatted(date: .abbreviated, time: .omitted))
                            .bold()
                        Spacer()
                        Text(e.amount.toString())
                            .italic()
                    }
                }.foregroundStyle(.primary)
            }
        }
    }
    
    @ViewBuilder
    private func footerActionsView() -> some View {
        Grid {
            GridRow {
                Button {
                    path.append(.EditExpense(expense: expense))
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                        .bold()
                        .frame(maxWidth: .infinity, maxHeight: 30)
                }.tint(.blue)
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .bold()
                        .frame(maxWidth: .infinity, maxHeight: 30)
                }
            }.gridColumnAlignment(.center)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle)
        }.padding([.leading, .trailing], 20)
            .padding([.top, .bottom], 8)
    }
    
    private func delete() {
        modelContext.delete(expense)
        if !path.isEmpty {
            path.removeLast()
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    addTestExpenses(container.mainContext)
    return NavigationStack {
        ExpenseView(path: .constant([]), expense: .init(date: .now, payee: "Publix", amount: .Cents(34189), category: "Groceries", notes: "November grocery run", details: .Fuel(details: .init(amount: 12.01, rate: 2.569, user: "Mazda CX-5"))))
    }.modelContainer(container)
}
