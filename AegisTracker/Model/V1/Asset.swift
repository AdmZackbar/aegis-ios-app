//
//  Asset.swift
//  AegisTracker
//
//  Created by Zach Wassynger on 12/10/24.
//

import Foundation
import SwiftData

typealias Asset = SchemaV1.Asset

extension SchemaV1 {
    @Model
    final class Asset {
        var name: String = ""
        var purchaseDate: Date = Date()
        var totalCost: Price = Price.Cents(0)
        var metaData: MetaData = MetaData()
        var valuations: [Valuation] = []
        var loan: Loan? = nil
        
        init(name: String = "",
             purchaseDate: Date = Date(),
             totalCost: Price = .Cents(0),
             metaData: MetaData = .init(),
             valuations: [Valuation] = [],
             loan: Loan? = nil) {
            self.name = name
            self.purchaseDate = purchaseDate
            self.totalCost = totalCost
            self.metaData = metaData
            self.valuations = valuations
            self.loan = loan
        }
        
        struct MetaData: Codable {
            var category: String
            var notes: String
            
            init(category: String = "", notes: String = "") {
                self.category = category
                self.notes = notes
            }
        }
        
        struct Valuation: Codable {
            var date: Date
            var amount: Price
        }
        
        struct Loan: Codable {
            var amount: Price = Price.Cents(0)
            var payments: [Payment] = []
            var metaData: MetaData = MetaData()
            // Computed values
            var totalPaid: Price {
                get {
                    payments.map({ $0.amount }).reduce(.Cents(0), +)
                }
            }
            var principalPaid: Price {
                get {
                    payments.map({ $0.principal }).reduce(.Cents(0), +)
                }
            }
            var interestPaid: Price {
                get {
                    payments.map({ $0.interest }).reduce(.Cents(0), +)
                }
            }
            var remainingAmount: Price {
                get {
                    amount - principalPaid
                }
            }
            
            init(amount: Price = .Cents(0), payments: [Payment] = [], metaData: MetaData = .init()) {
                self.amount = amount
                self.payments = payments
                self.metaData = metaData
            }
            
            struct MetaData: Codable {
                var lender: String
                var rate: Double
                var term: Term
                
                init(lender: String = "", rate: Double = 0.0, term: Term = .Years(num: 0)) {
                    self.lender = lender
                    self.rate = rate
                    self.term = term
                }
                
                enum Term: Codable {
                    case Years(num: Int)
                }
            }
            
            struct Payment: Codable, Hashable, Equatable {
                var date: Date = Date()
                var type: LoanType = LoanType.Principal(principal: .Cents(0))
                var notes: String = ""
                // Computed values
                var amount: Price {
                    get {
                        switch type {
                        case .Regular(let details):
                            return details.total
                        case .Principal(let principal):
                            return principal
                        }
                    }
                }
                var principal: Price {
                    get {
                        switch type {
                        case .Regular(let details):
                            return details.principal
                        case .Principal(let principal):
                            return principal
                        }
                    }
                }
                var interest: Price {
                    get {
                        switch type {
                        case .Regular(let details):
                            return details.interest
                        case .Principal(_):
                            return .Cents(0)
                        }
                    }
                }
                var escrow: Price {
                    get {
                        switch type {
                        case .Regular(let details):
                            return details.escrow
                        case .Principal(_):
                            return .Cents(0)
                        }
                    }
                }
                var other: Price {
                    get {
                        switch type {
                        case .Regular(let details):
                            return details.other
                        case .Principal(_):
                            return .Cents(0)
                        }
                    }
                }
                
                init(date: Date = Date(), type: LoanType = .Regular(details: .init()), notes: String = "") {
                    self.date = date
                    self.type = type
                    self.notes = notes
                }
                
                enum LoanType: Codable, Hashable, Equatable {
                    case Regular(details: RegularDetails)
                    case Principal(principal: Price)
                }
                
                struct RegularDetails: Codable, Hashable, Equatable {
                    var principal: Price
                    var interest: Price
                    var escrow: Price
                    var other: Price
                    var total: Price {
                        get {
                            principal + interest + escrow + other
                        }
                    }
                    
                    init(principal: Price = .Cents(0),
                         interest: Price = .Cents(0),
                         escrow: Price = .Cents(0),
                         other: Price = .Cents(0)) {
                        self.principal = principal
                        self.interest = interest
                        self.escrow = escrow
                        self.other = other
                    }
                }
            }
        }
    }
}
