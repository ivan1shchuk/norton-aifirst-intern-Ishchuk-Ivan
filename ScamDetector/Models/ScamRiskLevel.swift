//
//  ScamRiskLevel.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

enum ScamRiskLevel: String, CaseIterable, Codable, Equatable, Sendable {
    case safe
    case suspicious
    case dangerous

    var displayName: String {
        switch self {
        case .safe:
            "Safe"
        case .suspicious:
            "Suspicious"
        case .dangerous:
            "Dangerous"
        }
    }
}
