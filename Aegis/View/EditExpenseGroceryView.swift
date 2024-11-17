//
//  EditExpenseGroceryView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/17/24.
//

import SwiftUI

struct EditExpenseGroceryView: View {
    @Binding private var details: Details
    @State private var foodDetails: FoodDetails = FoodDetails()
    @State private var itemIndex: Int = -1
    @State private var sheetShowing: Bool = false
    
    init(details: Binding<Details>) {
        self._details = details
    }
    
    var body: some View {
        ForEach(details.foods, id: \.hashValue) { food in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(food.name).bold()
                        if food.quantity != 1.0 {
                            Text("(x\(food.quantity.formatted(.number.precision(.fractionLength(0...2)))))")
                                .font(.subheadline)
                        }
                    }
                    Text("\(food.category) | Total: \((Price.Cents(food.price) * food.quantity).toString())")
                        .font(.subheadline).italic()
                }
                Spacer()
                Button("Edit") {
                    itemIndex = details.foods.firstIndex(of: food)!
                    foodDetails = food
                    sheetShowing = true
                }
            }
        }
        Button("Add Food") {
            foodDetails = FoodDetails()
            itemIndex = -1
            sheetShowing = true
        }.sheet(isPresented: $sheetShowing) {
            NavigationStack {
                Form {
                    FoodDetailView(foodDetails: $foodDetails)
                }.navigationTitle(itemIndex < 0 ? "Add Food" : "Edit Food")
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
                                if itemIndex >= 0 && itemIndex < details.foods.count {
                                    details.foods[itemIndex] = foodDetails
                                } else {
                                    details.foods.append(foodDetails)
                                }
                                sheetShowing = false
                            }
                        }
                    }
            }.presentationDetents([.height(300)])
        }
    }
    
    struct FoodDetailView: View {
        private let categories: [String] = ["Carbs", "Dairy", "Fruits", "Ingredients", "Meal", "Meat", "Sweets", "Vegetables"]
        
        @Binding private var foodDetails: FoodDetails
        
        private let formatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.zeroSymbol = ""
            return formatter
        }()
        
        init(foodDetails: Binding<FoodDetails>) {
            self._foodDetails = foodDetails
        }
        
        var body: some View {
            HStack {
                Text("Name:")
                TextField("required", text: $foodDetails.name)
                    .textInputAutocapitalization(.words)
            }
            HStack {
                Text("Unit Price:")
                CurrencyTextField(numberFormatter: MainView.CurrencyFormatter, value: $foodDetails.price)
            }
            HStack {
                Text("Quantity:")
                Stepper() {
                    TextField("required", value: $foodDetails.quantity, formatter: formatter)
                        .keyboardType(.decimalPad)
                } onIncrement: {
                    foodDetails.quantity += 1
                } onDecrement: {
                    if foodDetails.quantity > 1 {
                        foodDetails.quantity -= 1
                    }
                }
            }
            Picker("Category:", selection: $foodDetails.category) {
                ForEach(categories, id: \.hashValue) { category in
                    Text(category).tag(category)
                }
            }
        }
    }
    
    struct FoodDetails: Codable, Hashable, Equatable {
        var name: String = ""
        var price: Int = 0
        var quantity: Double = 1.0
        var category: String = "Carbs"
    }
    
    struct Details {
        var foods: [FoodDetails] = []
        
        static func fromExpense(_ details: Expense.Details) -> Details {
            switch details {
            case .Groceries(let list):
                return Details(foods: list.foods.map(toFood))
            default:
                return Details()
            }
        }
        
        private static func toFood(_ food: Expense.GroceryList.Food) -> FoodDetails {
            switch food.unitPrice {
            case .Cents(let cents):
                FoodDetails(name: food.name, price: cents, quantity: food.quantity, category: food.category)
            }
        }
        
        func toExpense() -> Expense.Details {
            return .Groceries(list: .init(foods: foods.map(toExpenseFood)))
        }
        
        private func toExpenseFood(_ food: FoodDetails) -> Expense.GroceryList.Food {
            return .init(name: food.name, unitPrice: .Cents(food.price), quantity: food.quantity, category: food.category)
        }
    }
}

#Preview {
    NavigationStack {
        EditExpenseView(path: .constant([]), expense: .init(date: .now, payee: "Costco", amount: .Cents(60110), category: "Groceries", details: .Groceries(list: .init(foods: [.init(name: "Chicken Thighs", unitPrice: .Cents(2134), quantity: 2.0, category: "Meat")]))))
    }
}