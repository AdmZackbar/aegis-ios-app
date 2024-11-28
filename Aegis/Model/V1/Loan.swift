//
//  Loan.swift
//  Aegis
//
//  Created by Zach Wassynger on 11/28/24.
//

import Foundation
import SwiftData

typealias Loan = SchemaV1.Loan
typealias LoanPayment = SchemaV1.LoanPayment

extension SchemaV1 {
    @Model
    final class Loan {
        var name: String
        var startDate: Date
        var originalAmount: Price
        var remainingAmount: Price
        var metaData: MetaData
        
        @Relationship(deleteRule: .cascade, inverse: \LoanPayment.loan)
        var payments: [LoanPayment] = []
        
        init(name: String, startDate: Date, originalAmount: Price, remainingAmount: Price, metaData: MetaData) {
            self.name = name
            self.startDate = startDate
            self.originalAmount = originalAmount
            self.remainingAmount = remainingAmount
            self.metaData = metaData
        }
        
        struct MetaData: Codable {
            var lender: String
            var rate: Double
            var term: Term
            var category: String
            
            enum Term: Codable {
                case Years(num: Int)
            }
        }
    }
    
    @Model
    final class LoanPayment {
        var loan: Loan!
        var date: Date
        var type: LoanType
        var details: String
        
        init(loan: Loan, date: Date, type: LoanType, details: String) {
            self.loan = loan
            self.date = date
            self.type = type
            self.details = details
        }
        
        func getAmount() -> Price {
            switch type {
            case .Regular(let principal, let interest):
                return principal + interest
            case .Principal(let principal):
                return principal
            }
        }
        
        func getPrincipal() -> Price {
            switch type {
            case .Regular(let principal, _):
                return principal
            case .Principal(let principal):
                return principal
            }
        }
        
        enum LoanType: Codable {
            case Regular(principal: Price, interest: Price)
            case Principal(principal: Price)
        }
    }
}
