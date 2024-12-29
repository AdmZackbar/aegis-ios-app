//
//  NavigationStore.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/15/24.
//

import SwiftUI

@MainActor
final class NavigationStore: ObservableObject {
    @Published var path = NavigationPath()
    @Published var dashboardConfig = DashboardConfig()
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    func encoded() -> Data? {
        try? path.codable.map(encoder.encode)
    }
    
    func restore(from data: Data) {
        do {
            let codable = try decoder.decode(
                NavigationPath.CodableRepresentation.self, from: data
            )
            path = NavigationPath(codable)
        } catch {
            path = NavigationPath()
        }
    }
    
    func push(_ value: any Hashable) {
        path.append(value)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func replace(_ value: any Hashable) {
        pop()
        push(value)
    }
}

struct DashboardConfig: Hashable, Equatable {
    var date: Date
    var dateRangeType: DateRangeType
    
    init(date: Date = .now, dateRangeType: DateRangeType = .month) {
        self.date = date
        self.dateRangeType = dateRangeType
    }
    
    func contains(_ date: Date) -> Bool {
        switch dateRangeType {
        case .month:
            return self.date.year == date.year && self.date.month == date.month
        case .ytd:
            return self.date.year == date.year && self.date.month >= date.month
        case .year:
            return self.date.year == date.year
        }
    }
    
    mutating func prev() {
        switch dateRangeType {
        case .month, .ytd:
            date = .from(year: date.year, month: date.month - 1, day: 1)
        case .year:
            date = .from(year: date.year - 1, month: date.month, day: 1)
        }
    }
    
    mutating func next() {
        switch dateRangeType {
        case .month, .ytd:
            date = .from(year: date.year, month: date.month + 1, day: 1)
        case .year:
            date = .from(year: date.year + 1, month: date.month, day: 1)
        }
    }
    
    enum DateRangeType: String, Hashable, Equatable, CaseIterable {
        case month
        case ytd
        case year
    }
}
