//
//  FinancedExpenseView.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 9/10/26.
//

import SwiftData
import SwiftUI

struct FinancedExpenseView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    let expense: FinancedExpense
   
    @State private var showDelete: Bool = false
    
    init(expense: FinancedExpense) {
        self.expense = expense
    }
    
    var body: some View {
        VStack(spacing: 4) {
            headerView()
            Form {
                detailView()
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
        Text(expense.total.toString())
            .font(.system(size: 48, weight: .bold, design: .rounded))
        VStack(alignment: .leading, spacing: 6) {
            categoryHeaderView()
            HStack(alignment: .bottom) {
                Text(expense.payee)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .bold()
                Spacer()
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            if expense.interest > .zero {
                Text("Principal: \(expense.amount.toString())")
                    .font(.subheadline)
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
    private func categoryHeaderView() -> some View {
        if !expense.tags.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    Text(expense.category)
                    Divider().frame(height: 16)
                    HStack(spacing: 4) {
                        ForEach(expense.tags.dropLast()) { tag in
                            Text(tag.name).fontWeight(.regular).italic()
                            Text("•")
                        }
                        Text(expense.tags.last!.name).fontWeight(.regular).italic()
                    }
                }.textCase(.uppercase).font(.caption).fontWeight(.light)
            }
        } else {
            Text(expense.category)
                .textCase(.uppercase)
                .font(.caption)
                .fontWeight(.light)
        }
    }
    
    @ViewBuilder
    func detailView() -> some View {
        Section {
            Gauge(value: expense.amountPaid.toUsd(), in: 0...expense.total.toUsd()) {
                
            }.gaugeStyle(.linearCapacity)
        } header: {
            HStack {
                Text("\(expense.paidDates.count) payment(s)")
                Spacer()
                Text(expense.amountPaid.toString())
            }.fontWeight(.semibold)
        }
        Section {
            ForEach(expense.dates.sorted(), id: \.self) { date in
                FinancedExpenseEntryView(expense: expense, date: date, omitted: [.Notes, .Category, .Payee])
            }
        } header: {
            switch expense.paymentPlan {
            case .acmi(let numMonths):
                Text("Apple Card: \(numMonths) Monthly Installments")
            }
        }
    }
    
    @ViewBuilder
    private func footerActionsView() -> some View {
        Grid {
            GridRow {
                Button {
                    navigationStore.push(ExpenseViewType.editFinanced(expense: expense))
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
        navigationStore.pop()
    }
}

#Preview {
    @Previewable @StateObject var navigationStore = NavigationStore()
    let expense = FinancedExpense(amount: .Cents(79999), payee: "Apple", category: "Tech Devices", notes: "Apple Watch Ultra 4", tags: [.init(name: "Binge Shopping 2026")], paymentPlan: .acmi(numMonths: 6))
    return NavigationStack(path: $navigationStore.path) {
        FinancedExpenseView(expense: expense).navigationDestination(for: ExpenseViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: RevenueViewType.self, destination: MainView.computeDestination)
            .navigationDestination(for: AssetViewType.self, destination: MainView.computeDestination)
    }.environmentObject(navigationStore)
}
