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
    var dateTag: Date {
        get {
            Date.from(year: date.year, month: date.month, day: 1)
        }
        set(value) {
            date = value
        }
    }
    
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
        }
    }
    
    enum DateRangeType: String, Hashable, Equatable, CaseIterable {
        case month
        case ytd
    }
}
