//
//  ScamExampleMessage.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

struct ScamExampleMessage: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let expectedRiskLevel: ScamRiskLevel
}
