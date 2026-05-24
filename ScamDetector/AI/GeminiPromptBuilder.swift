//
//  GeminiPromptBuilder.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

struct GeminiPromptBuilder {
    func buildPrompt(for message: String) -> String {
        """
        You are a cybersecurity scam detection assistant for a mobile security app.

        Analyze the user-provided message, email snippet, or URL for scam risk.
        Return only the structured JSON requested by the API schema.

        Classification guidance:
        - Safe: no meaningful signs of fraud, phishing, impersonation, or coercive action.
        - Suspicious: some warning signs exist, but the message is not clearly malicious.
        - Dangerous: strong signs of phishing, fraud, credential theft, payment pressure, or impersonation.

        The confidenceScore must be an integer from 0 to 100 that reflects your confidence in the selected riskLevel.
        The explanation must be short and user-friendly.
        The detectedSignals array must contain concise labels, not full sentences.

        Message to analyze:
        \(message)
        """
    }

    func responseSchema() -> GeminiJSONSchema {
        GeminiJSONSchema(
            type: "object",
            properties: [
                "riskLevel": GeminiJSONSchema(
                    type: "string",
                    description: "The overall scam risk classification.",
                    enumValues: ScamRiskLevel.allCases.map(\.displayName)
                ),
                "confidenceScore": GeminiJSONSchema(
                    type: "integer",
                    description: "Confidence in the selected risk level, from 0 to 100.",
                    minimum: 0,
                    maximum: 100
                ),
                "explanation": GeminiJSONSchema(
                    type: "string",
                    description: "A short user-friendly explanation of why this result was selected."
                ),
                "detectedSignals": GeminiJSONSchema(
                    type: "array",
                    description: "Short labels for the signals detected in the message.",
                    items: GeminiJSONSchema(type: "string")
                )
            ],
            required: [
                "riskLevel",
                "confidenceScore",
                "explanation",
                "detectedSignals"
            ]
        )
    }
}
