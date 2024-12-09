//
//  EditExpenseGroceryView.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/17/24.
//

import SwiftData
import SwiftUI

struct EditExpenseGroceryView: View {
    @Query(filter: #Predicate<Expense> { expense in
        expense.category == "Groceries"
    }, sort: \Expense.date, order: .reverse) var groceryExpenses: [Expense]
    
    @Binding private var details: Details
    @State private var foodDetails: FoodDetails = FoodDetails()
    @State private var itemIndex: Int = -1
    @State private var sheetShowing: Bool = false
    @State private var deleteAlertShowing: Bool = false
    @State private var deleteFood: FoodDetails? = nil
    
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
            }.swipeActions {
                Button {
                    deleteFood = food
                    deleteAlertShowing = true
                } label: {
                    Label("Delete", systemImage: "trash").tint(.red)
                }
            }
        }.alert("Delete this food?", isPresented: $deleteAlertShowing) {
            Button("Delete", role: .destructive) {
                if let selectedFood = deleteFood {
                    withAnimation {
                        details.foods.removeAll(where: { $0 == selectedFood })
                    }
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
                    FoodDetailView(foodDetails: $foodDetails, groceryExpenses: groceryExpenses)
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
            }.presentationDetents([.medium])
        }
    }
    
    struct FoodDetailView: View {
        private let categories: [String] = ["Carbs", "Dairy", "Fruits", "Ingredients", "Meal", "Meat", "Sweets", "Vegetables"]
        
        let groceryExpenses: [Expense]
        
        @Binding private var foodDetails: FoodDetails
        
        private let formatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.zeroSymbol = ""
            return formatter
        }()
        
        init(foodDetails: Binding<FoodDetails>, groceryExpenses: [Expense]) {
            self._foodDetails = foodDetails
            self.groceryExpenses = groceryExpenses
        }
        
        var body: some View {
            HStack {
                Text("Name:")
                TextField("required", text: $foodDetails.name)
                    .textInputAutocapitalization(.words)
            }
            let nameSuggestions = foodDetails.name.isEmpty ? [] : Array(Set(groceryExpenses.map(toFoods).joined().filter(isFoodSuggested)))
            if !nameSuggestions.isEmpty && nameSuggestions[0].name != foodDetails.name {
                ForEach(nameSuggestions, id: \.hashValue) { suggestion in
                    Button(suggestion.name) {
                        foodDetails.name = suggestion.name
                        foodDetails.brand = suggestion.brand
                        foodDetails.category = suggestion.category
                        switch suggestion.unitPrice {
                        case .Cents(let cents):
                            foodDetails.price = cents
                        }
                    }
                }
            }
            HStack {
                Text("Brand:")
                TextField("required", text: $foodDetails.brand)
                    .textInputAutocapitalization(.words)
            }
            let brandSuggestions = foodDetails.brand.isEmpty ? [] : Array(Set(groceryExpenses.map(toFoods).joined().filter(isBrandSuggested).map({ $0.brand })))
            if !brandSuggestions.isEmpty && brandSuggestions[0] != foodDetails.brand {
                ForEach(brandSuggestions, id: \.hashValue) { suggestion in
                    Button(suggestion) {
                        foodDetails.brand = suggestion
                    }
                }
            }
            HStack {
                Text("Unit Price:")
                CurrencyField(value: $foodDetails.price)
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
        
        private func toFoods(_ expense: Expense) -> [Expense.GroceryList.Food] {
            switch expense.details {
            case .Groceries(let list):
                return list.foods
            default:
                return []
            }
        }
        
        private func isFoodSuggested(_ food: Expense.GroceryList.Food) -> Bool {
            food.name.localizedCaseInsensitiveContains(foodDetails.name) ||
            food.brand.localizedCaseInsensitiveContains(foodDetails.name)
        }
        
        private func isBrandSuggested(_ food: Expense.GroceryList.Food) -> Bool {
            food.brand.localizedStandardContains(foodDetails.brand)
        }
    }
    
    struct FoodDetails: Codable, Hashable, Equatable {
        var name: String = ""
        var brand: String = ""
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
                FoodDetails(name: food.name, brand: food.brand, price: cents, quantity: food.quantity, category: food.category)
            }
        }
        
        func toExpense() -> Expense.Details {
            return .Groceries(list: .init(foods: foods.map(toExpenseFood)))
        }
        
        private func toExpenseFood(_ food: FoodDetails) -> Expense.GroceryList.Food {
            return .init(name: food.name, brand: food.brand, unitPrice: .Cents(food.price), quantity: food.quantity, category: food.category)
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    addExpenses(container.mainContext)
    return NavigationStack {
        EditExpenseView(path: .constant([]), expense: .init(date: .now, payee: "Costco", amount: .Cents(60110), category: "Groceries", notes: "", detailType: nil, details: .Groceries(list: .init(foods: [.init(name: "Chicken Thighs", brand: "Kirkland Signature",unitPrice: .Cents(2134), quantity: 2.0, category: "Meat")]))))
    }.modelContainer(container)
}
