//
//  GeminiAPIModels.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

struct GeminiGenerateContentRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let role: String?
    let parts: [GeminiPart]

    init(role: String? = nil, parts: [GeminiPart]) {
        self.role = role
        self.parts = parts
    }
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Encodable {
    let responseMimeType: String
    let responseJsonSchema: GeminiJSONSchema
}

final class GeminiJSONSchema: Encodable {
    let type: String
    let description: String?
    let properties: [String: GeminiJSONSchema]?
    let items: GeminiJSONSchema?
    let enumValues: [String]?
    let required: [String]?
    let minimum: Int?
    let maximum: Int?

    init(
        type: String,
        description: String? = nil,
        properties: [String: GeminiJSONSchema]? = nil,
        items: GeminiJSONSchema? = nil,
        enumValues: [String]? = nil,
        required: [String]? = nil,
        minimum: Int? = nil,
        maximum: Int? = nil
    ) {
        self.type = type
        self.description = description
        self.properties = properties
        self.items = items
        self.enumValues = enumValues
        self.required = required
        self.minimum = minimum
        self.maximum = maximum
    }

    enum CodingKeys: String, CodingKey {
        case type
        case description
        case properties
        case items
        case enumValues = "enum"
        case required
        case minimum
        case maximum
    }
}

struct GeminiGenerateContentResponse: Decodable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Decodable {
    let content: GeminiContent?
}

struct GeminiScamAssessmentDTO: Decodable {
    let riskLevel: String
    let confidenceScore: Int
    let explanation: String
    let detectedSignals: [String]
}
