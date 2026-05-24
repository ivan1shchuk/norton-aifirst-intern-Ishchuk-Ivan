//
//  GeminiResponseParser.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

struct GeminiResponseParser {
    private let decoder = JSONDecoder()

    func parse(_ response: GeminiGenerateContentResponse) throws -> ScamAnalysisResult {
        guard let text = response.candidates?.first?.content?.parts.first?.text,
              let data = text.data(using: .utf8) else {
            throw GeminiScamAnalyzerError.emptyResponse
        }

        let assessment = try decoder.decode(GeminiScamAssessmentDTO.self, from: data)
        let riskLevel = try parseRiskLevel(assessment.riskLevel)

        return ScamAnalysisResult(
            riskLevel: riskLevel,
            confidenceScore: assessment.confidenceScore,
            explanation: assessment.explanation,
            detectedSignals: assessment.detectedSignals
        )
    }

    private func parseRiskLevel(_ value: String) throws -> ScamRiskLevel {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "safe":
            return .safe
        case "suspicious":
            return .suspicious
        case "dangerous":
            return .dangerous
        default:
            throw GeminiScamAnalyzerError.invalidModelOutput
        }
    }
}
