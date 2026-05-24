//
//  ScamAnalysisState.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

enum ScamAnalysisState: Equatable, Sendable {
    case idle
    case analyzing
    case success(ScamAnalysisResult)
    case failed(String)

    var isAnalyzing: Bool {
        self == .analyzing
    }
}
