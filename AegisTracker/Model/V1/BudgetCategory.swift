//
//  BudgetCategory.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/23/24.
//

import SwiftData
import SwiftUI

typealias BudgetCategory = SchemaV1.BudgetCategory

extension SchemaV1 {
    @Model
    final class BudgetCategory {
        var name: String = ""
        var amount: Price? = nil
        var monthlyBudget: Price? {
            let sum = (children ?? []).total
            if let sum {
                return amount != nil ? sum + amount! : sum
            }
            return amount
        }
        var colorValue: UInt? = nil
        var color: Color? {
            get {
                if let colorValue {
                    Color(hex: colorValue)
                } else {
                    nil
                }
            }
            set(value) {
                colorValue = value != nil ? value?.hexValue ?? nil : nil
            }
        }
        var assetType: String? = nil
        
        var parent: BudgetCategory? = nil
        @Relationship(deleteRule: .cascade, inverse: \BudgetCategory.parent)
        var children: [BudgetCategory]? = nil
        
        init(name: String = "",
             amount: Price? = nil,
             colorValue: UInt? = nil,
             assetType: String? = nil) {
            self.name = name
            self.amount = amount
            self.colorValue = colorValue
            self.assetType = assetType
        }
    }
}
