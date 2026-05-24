//
//  GeminiScamAnalyzer.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

enum GeminiScamAnalyzerError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case emptyResponse
    case invalidModelOutput

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing Gemini API key. Add GEMINI_API_KEY to the app scheme environment."
        case .invalidResponse:
            return "Gemini returned an invalid response."
        case .requestFailed(let statusCode, let message):
            return "Gemini request failed (\(statusCode)): \(message)"
        case .emptyResponse:
            return "Gemini returned an empty response."
        case .invalidModelOutput:
            return "Gemini returned a result the app could not understand."
        }
    }
}

struct GeminiScamAnalyzer: ScamAnalyzing {
    private let configuration: APIConfiguration
    private let httpClient: HTTPClient
    private let promptBuilder: GeminiPromptBuilder
    private let responseParser: GeminiResponseParser
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        configuration: APIConfiguration = APIConfiguration(),
        httpClient: HTTPClient = URLSessionHTTPClient(),
        promptBuilder: GeminiPromptBuilder = GeminiPromptBuilder(),
        responseParser: GeminiResponseParser = GeminiResponseParser(),
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.configuration = configuration
        self.httpClient = httpClient
        self.promptBuilder = promptBuilder
        self.responseParser = responseParser
        self.encoder = encoder
        self.decoder = decoder
    }

    func analyze(message: String) async throws -> ScamAnalysisResult {
        guard !configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiScamAnalyzerError.missingAPIKey
        }

        let prompt = promptBuilder.buildPrompt(for: message)
        let requestBody = GeminiGenerateContentRequest(
            contents: [
                GeminiContent(
                    role: "user",
                    parts: [
                        GeminiPart(text: prompt)
                    ]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                responseMimeType: "application/json",
                responseJsonSchema: promptBuilder.responseSchema()
            )
        )

        var request = URLRequest(url: endpointURL())
        request.httpMethod = "POST"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await httpClient.send(request)

        guard (200...299).contains(response.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "No error body."
            throw GeminiScamAnalyzerError.requestFailed(
                statusCode: response.statusCode,
                message: message
            )
        }

        let geminiResponse = try decoder.decode(GeminiGenerateContentResponse.self, from: data)
        return try responseParser.parse(geminiResponse)
    }

    private func endpointURL() -> URL {
        configuration.baseURL
            .appendingPathComponent("v1beta")
            .appendingPathComponent("models")
            .appendingPathComponent("\(configuration.modelName):generateContent")
    }
}
