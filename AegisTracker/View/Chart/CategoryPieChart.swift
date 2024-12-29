//
//  CategoryPieChart.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/24/24.
//

import Charts
import SwiftUI

struct CategoryPieChart: View {
    @Binding private var selectedCategory: BudgetCategory?
    @State private var selectedAngle: Double? = nil
    
    let categories: [BudgetCategory]
    let data: [CategoryData]
    let dataCategoryMap: [CategoryData : BudgetCategory]
    private let categoryRanges: [(category: String, range: Range<Double>)]
    
    init(categories: [BudgetCategory], data: [CategoryData], selectedCategory: Binding<BudgetCategory?>) {
        let main: BudgetCategory? = categories.filter({ $0.parent != nil }).first?.parent
        if let main {
            self.categories = categories + [main]
        } else {
            self.categories = categories
        }
        (self.data, self.dataCategoryMap) = {
            let map: [BudgetCategory : Int] = {
                var map: [BudgetCategory : Int] = [:]
                let other: BudgetCategory = categories.filter({ $0.name.lowercased() == "other" }).first ?? .init(name: "Other")
                for item in data {
                    if let main, main.name == item.category {
                        map[main, default: 0] += item.amount.toCents()
                    } else {
                        let actual = categories.find(item.category) ?? other
                        map[actual, default: 0] += item.amount.toCents()
                    }
                }
                return map
            }()
            var categoryMap: [CategoryData : BudgetCategory] = [:]
            map.forEach({ category, amount in
                let data = CategoryData(category: category.name, amount: .Cents(amount))
                categoryMap[data] = category
            })
            return (categoryMap.keys.sorted(by: { $0.category < $1.category }), categoryMap)
        }()
        var total: Double = 0
        self.categoryRanges = self.data.map {
            let newTotal = total + $0.amount.toUsd()
            let result = (category: $0.category,
                          range: total ..< newTotal)
            total = newTotal
            return result
        }
        self._selectedCategory = selectedCategory
    }
    
    var body: some View {
        Chart(data, id: \.category.hashValue) { item in
            SectorMark(angle: .value(item.category, item.amount.toUsd()),
                       innerRadius: .ratio(0.65),
                       outerRadius: item.category == selectedCategory?.name ? .inset(0) : .inset(10),
                       angularInset: 1)
                .cornerRadius(4)
                .foregroundStyle(by: .value(Text(verbatim: item.category), item.category))
        }.chartForegroundStyleScale { item in
            categories.filter({ $0.name == item }).first?.color ?? Color.gray
        }.chartLegend(position: .trailing, alignment: .top)
            .chartAngleSelection(value: $selectedAngle)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        chartOverlay(frame)
                    }
                }
            }
            .onChange(of: selectedAngle, onSelectedAngleChanged)
    }
    
    @ViewBuilder
    private func chartOverlay(_ frame: CGRect) -> some View {
        VStack(spacing: 0) {
            Text(selectedCategory?.name ?? "Total")
                .font(selectedCategory != nil ? .caption : .subheadline)
                .opacity(0.6)
            let amount: Price = {
                if let selectedCategory {
                    return data.filter({ $0.category == selectedCategory.name }).total
                }
                return data.total
            }()
            Text(amount.toString(maxDigits: 0))
                .font(.title3)
                .bold()
        }.position(x: frame.midX, y: frame.midY)
            .foregroundStyle(selectedCategory != nil ? categories.filter({ $0.name == selectedCategory!.name }).first?.color ?? Color.primary : Color.primary)
    }
    
    private func onSelectedAngleChanged(oldValue: Double?, newValue: Double?) {
        withAnimation {
            selectedCategory = {
                guard let newValue else { return nil }
                if let selection = categoryRanges.firstIndex(where: {
                    $0.range.contains(newValue)
                }) {
                    return dataCategoryMap[data[selection]]
                }
                return nil
            }()
        }
    }
}

#Preview {
    @Previewable @State var selectedCategory: BudgetCategory? = nil
    Form {
        Text(selectedCategory?.name ?? "No Selection")
        let budget = BudgetCategory(name: "Main Budget", children: [
            .init(name: "Housing", amount: .Cents(300000), colorValue: Color.init(hex: "#0056D6").hexValue, children: [
                .init(name: "Housing Maintenance")
            ]),
            .init(name: "Food", amount: .Cents(60000), colorValue: Color.init(hex: "#99244F").hexValue, children: [
                .init(name: "Fast Food"),
                .init(name: "Groceries")
            ]),
            .init(name: "Transportation", amount: .Cents(15000), colorValue: Color.init(hex: "#D38301").hexValue),
            .init(name: "Healthcare", amount: .Cents(18000), colorValue: Color.init(hex: "#01C7FC").hexValue),
            .init(name: "Personal", amount: .Cents(20000), colorValue: Color.init(hex: "#FF6250").hexValue),
            .init(name: "Entertainment", amount: .Cents(25000), colorValue: Color.init(hex: "#D357FE").hexValue),
            .init(name: "Other", colorValue: Color.gray.hexValue)
        ])
        CategoryPieChart(
            categories: budget.children!,
            data: [.init(category: "Groceries", amount: .Cents(15401)),
                   .init(category: "Transportation", amount: .Cents(45211)),
                   .init(category: "Housing", amount: .Cents(430123)),
                   .init(category: "Housing Maintenance", amount: .Cents(230123)),
                   .init(category: "Fast Food", amount: .Cents(4501)),
                   .init(category: "Fast Food", amount: .Cents(90023)),
                   .init(category: "Something", amount: .Cents(90023)),
                   .init(category: "Main Budget", amount: .Cents(150023)),
                   .init(category: "Personal", amount: .Cents(232202))],
            selectedCategory: $selectedCategory)
        .frame(height: 220)
    }
}
