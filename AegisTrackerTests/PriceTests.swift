//
//  PriceTests.swift
//  AegisTrackerTests
//
//  Created by Zach Wassynger on 5/4/26.
//

import Testing
@testable import AegisTracker

struct PriceTests {
    @Test func shallDisplayString() {
        let x = Price.Cents(350)
        let actual = x.toString()
        #expect(actual == "$3.50")
    }
    
    @Test func shallDisplayTruncatedString() {
        let x = Price.Cents(350)
        // Remove trailing 0
        #expect(x.toString(maxDigits: 1) == "$3.5")
        // Round to $4, remove decimal
        #expect(x.toString(maxDigits: 0) == "$4")
    }
    
    @Test func shallCompareCorrectly() {
        let a = Price.Cents(50)
        let b = Price.Cents(51)
        #expect(a < b)
        #expect(b > a)
        #expect(a <= b)
        #expect(b >= a)
        #expect(b != a)
    }
    
    @Test func shallAbs() {
        let negative = Price.Cents(-50)
        let positive = Price.Cents(50)
        #expect(negative != positive)
        #expect(negative.abs() == positive)
        #expect(positive.abs() == positive.abs())
    }
    
    @Test func shallAddPrices() {
        let x = Price.Cents(100)
        let y = Price.Cents(50)
        let actual = x + y
        #expect(actual == .Cents(150))
    }
    
    @Test func shallSubtractPrices() {
        let x = Price.Cents(100)
        let y = Price.Cents(25)
        let actual = x - y
        #expect(actual == .Cents(75))
    }
    
    @Test func shallMultiplyPriceByFactor() {
        let x = Price.Cents(100)
        let y = 4.0
        let actual = x * y
        #expect(actual == .Cents(400))
    }
    
    @Test func shallDividePriceByFactor() {
        let x = Price.Cents(100)
        let y = 4.0
        let actual = x / y
        #expect(actual == .Cents(25))
    }
    
    @Test func shallMutateIncrement() {
        var x = Price.Cents(100)
        let y = Price.Cents(200)
        x += y
        #expect(x.toCents() == 300)
    }
    
    @Test func shallMutateDecrement() {
        var x = Price.Cents(200)
        let y = Price.Cents(150)
        x -= y
        #expect(x.toCents() == 50)
    }
    
    @Test func shallMutateMultiply() {
        var x = Price.Cents(200)
        let y = 3.0
        x *= y
        #expect(x.toCents() == 600)
    }
    
    @Test func shallMutateDivide() {
        var x = Price.Cents(200)
        let y = 4.0
        x /= y
        #expect(x.toCents() == 50)
    }
}
