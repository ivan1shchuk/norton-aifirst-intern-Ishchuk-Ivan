//
//  ScamAnalyzing.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

protocol ScamAnalyzing {
    func analyze(message: String) async throws -> ScamAnalysisResult
}
