//
//  ScamAnalysisResult.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

struct ScamAnalysisResult: Codable, Equatable, Sendable {
    let riskLevel: ScamRiskLevel
    let confidenceScore: Int
    let explanation: String
    let detectedSignals: [String]

    init(
        riskLevel: ScamRiskLevel,
        confidenceScore: Int,
        explanation: String,
        detectedSignals: [String] = []
    ) {
        self.riskLevel = riskLevel
        self.confidenceScore = min(max(confidenceScore, 0), 100)
        self.explanation = explanation
        self.detectedSignals = detectedSignals
    }
}
