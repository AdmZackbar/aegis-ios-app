//
//  MainUtilitiesTests.swift
//  AegisTrackerTests
//
//  Created by Zach Wassynger on 5/4/26.
//

import Testing
@testable import AegisTracker

struct MainUtilitiesTests {
    @Test func shallDisplayCorrectMonth() {
        // March
        let month: Int = 3
        #expect(month.monthText() == "March")
        #expect(month.shortMonthText() == "Mar")
    }
    
    @Test func shallDisplayCorrectYear() {
        let month: Int = 2004
        // No commas or groupings
        #expect(month.yearText() == "2004")
    }
}
