//
//  CategoryData.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/24/24.
//

extension [CategoryData] {
    var total: Price {
        self.map({ $0.amount }).reduce(.Cents(0), +)
    }
}

struct CategoryData: Hashable, Equatable {
    var category: String
    var amount: Price
}
