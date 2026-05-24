//
//  GeminiScamAnalyzerTests.swift
//  ScamDetectorTests
//
//  Created by Ivan Ishchuk on 24.05.2026.
// AI-Generated Test Suite, reviewed by Ivan Ishchuk

import Foundation
import XCTest
@testable import ScamDetector

@MainActor
final class GeminiScamAnalyzerTests: XCTestCase {
    func testAnalyzeThrowsMissingAPIKeyWhenConfigurationHasEmptyKey() async throws {
        let httpClient = MockHTTPClient(
            result: .success(Self.successHTTPResult(modelJSON: Self.validAssessmentJSON()))
        )
        let analyzer = makeAnalyzer(apiKey: "", httpClient: httpClient)

        do {
            _ = try await analyzer.analyze(message: "Suspicious message")
            XCTFail("Expected missingAPIKey error.")
        } catch GeminiScamAnalyzerError.missingAPIKey {
            XCTAssertTrue(httpClient.requests.isEmpty)
        } catch {
            XCTFail("Expected missingAPIKey, got \(error).")
        }
    }

    func testAnalyzeThrowsMissingAPIKeyWhenConfigurationHasWhitespaceKey() async throws {
        let httpClient = MockHTTPClient(
            result: .success(Self.successHTTPResult(modelJSON: Self.validAssessmentJSON()))
        )
        let analyzer = makeAnalyzer(apiKey: "   \n", httpClient: httpClient)

        do {
            _ = try await analyzer.analyze(message: "Suspicious message")
            XCTFail("Expected missingAPIKey error.")
        } catch GeminiScamAnalyzerError.missingAPIKey {
            XCTAssertTrue(httpClient.requests.isEmpty)
        } catch {
            XCTFail("Expected missingAPIKey, got \(error).")
        }
    }

    func testAnalyzeBuildsGeminiRequestAndParsesSuccessfulAssessment() async throws {
        let httpClient = MockHTTPClient(
            result: .success(Self.successHTTPResult(modelJSON: Self.validAssessmentJSON()))
        )
        let analyzer = makeAnalyzer(apiKey: "test-key", modelName: "gemini-test-model", httpClient: httpClient)

        let result = try await analyzer.analyze(message: "Verify your bank account now.")

        XCTAssertEqual(result.riskLevel, .dangerous)
        XCTAssertEqual(result.confidenceScore, 91)
        XCTAssertEqual(result.explanation, "The message pressures the user to verify an account through a link.")
        XCTAssertEqual(result.detectedSignals, ["Urgent tone", "Account pressure", "External link"])

        let request = try XCTUnwrap(httpClient.requests.first)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.com/v1beta/models/gemini-test-model:generateContent")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), "test-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let generationConfig = try XCTUnwrap(json["generationConfig"] as? [String: Any])
        XCTAssertEqual(generationConfig["responseMimeType"] as? String, "application/json")

        let schema = try XCTUnwrap(generationConfig["responseJsonSchema"] as? [String: Any])
        let requiredFields = try XCTUnwrap(schema["required"] as? [String])
        XCTAssertTrue(requiredFields.contains("riskLevel"))
        XCTAssertTrue(requiredFields.contains("confidenceScore"))
        XCTAssertTrue(requiredFields.contains("explanation"))
        XCTAssertTrue(requiredFields.contains("detectedSignals"))

        let contents = try XCTUnwrap(json["contents"] as? [[String: Any]])
        let firstContent = try XCTUnwrap(contents.first)
        let parts = try XCTUnwrap(firstContent["parts"] as? [[String: Any]])
        let prompt = try XCTUnwrap(parts.first?["text"] as? String)
        XCTAssertTrue(prompt.contains("Verify your bank account now."))
    }

    func testAnalyzeThrowsRequestFailedForServerError() async throws {
        let serverErrorBody = #"{"error":{"message":"Quota exceeded"}}"#.data(using: .utf8)!
        let httpClient = MockHTTPClient(
            result: .success((
                serverErrorBody,
                Self.httpResponse(statusCode: 500)
            ))
        )
        let analyzer = makeAnalyzer(apiKey: "test-key", httpClient: httpClient)

        do {
            _ = try await analyzer.analyze(message: "Suspicious message")
            XCTFail("Expected requestFailed error.")
        } catch GeminiScamAnalyzerError.requestFailed(let statusCode, let message) {
            XCTAssertEqual(statusCode, 500)
            XCTAssertTrue(message.contains("Quota exceeded"))
        } catch {
            XCTFail("Expected requestFailed, got \(error).")
        }
    }

    func testAnalyzePropagatesNetworkFailure() async throws {
        let httpClient = MockHTTPClient(
            result: .failure(URLError(.notConnectedToInternet))
        )
        let analyzer = makeAnalyzer(apiKey: "test-key", httpClient: httpClient)

        do {
            _ = try await analyzer.analyze(message: "Suspicious message")
            XCTFail("Expected network error.")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Expected URLError.notConnectedToInternet, got \(error).")
        }
    }

    func testAnalyzeThrowsEmptyResponseWhenGeminiReturnsNoCandidates() async throws {
        let httpClient = MockHTTPClient(
            result: .success((
                #"{"candidates":[]}"#.data(using: .utf8)!,
                Self.httpResponse(statusCode: 200)
            ))
        )
        let analyzer = makeAnalyzer(apiKey: "test-key", httpClient: httpClient)

        do {
            _ = try await analyzer.analyze(message: "Suspicious message")
            XCTFail("Expected emptyResponse error.")
        } catch GeminiScamAnalyzerError.emptyResponse {
            XCTAssertEqual(httpClient.requests.count, 1)
        } catch {
            XCTFail("Expected emptyResponse, got \(error).")
        }
    }

    func testAnalyzeThrowsInvalidModelOutputForUnknownRiskLevel() async throws {
        let modelJSON = """
        {
          "riskLevel": "Severe",
          "confidenceScore": 88,
          "explanation": "Unexpected label.",
          "detectedSignals": ["Unknown label"]
        }
        """
        let httpClient = MockHTTPClient(
            result: .success(Self.successHTTPResult(modelJSON: modelJSON))
        )
        let analyzer = makeAnalyzer(apiKey: "test-key", httpClient: httpClient)

        do {
            _ = try await analyzer.analyze(message: "Suspicious message")
            XCTFail("Expected invalidModelOutput error.")
        } catch GeminiScamAnalyzerError.invalidModelOutput {
            XCTAssertEqual(httpClient.requests.count, 1)
        } catch {
            XCTFail("Expected invalidModelOutput, got \(error).")
        }
    }

    func testAnalyzeThrowsDecodingErrorForMalformedModelJSON() async throws {
        let httpClient = MockHTTPClient(
            result: .success(Self.successHTTPResult(modelJSON: "not json"))
        )
        let analyzer = makeAnalyzer(apiKey: "test-key", httpClient: httpClient)

        do {
            _ = try await analyzer.analyze(message: "Suspicious message")
            XCTFail("Expected decoding error.")
        } catch is DecodingError {
            XCTAssertEqual(httpClient.requests.count, 1)
        } catch {
            XCTFail("Expected DecodingError, got \(error).")
        }
    }

    func testAnalyzeClampsConfidenceScoreFromModelOutput() async throws {
        let modelJSON = """
        {
          "riskLevel": "Suspicious",
          "confidenceScore": 140,
          "explanation": "The message has some warning signs.",
          "detectedSignals": ["Unusual request"]
        }
        """
        let httpClient = MockHTTPClient(
            result: .success(Self.successHTTPResult(modelJSON: modelJSON))
        )
        let analyzer = makeAnalyzer(apiKey: "test-key", httpClient: httpClient)

        let result = try await analyzer.analyze(message: "Suspicious message")

        XCTAssertEqual(result.riskLevel, .suspicious)
        XCTAssertEqual(result.confidenceScore, 100)
        XCTAssertEqual(result.detectedSignals, ["Unusual request"])
    }
    
    private func makeAnalyzer(
        apiKey: String,
        modelName: String = "gemini-test",
        httpClient: MockHTTPClient
    ) -> GeminiScamAnalyzer {
        GeminiScamAnalyzer(
            configuration: APIConfiguration(
                apiKey: apiKey,
                modelName: modelName,
                baseURL: URL(string: "https://example.com")!
            ),
            httpClient: httpClient
        )
    }

    private static func validAssessmentJSON() -> String {
        """
        {
          "riskLevel": "Dangerous",
          "confidenceScore": 91,
          "explanation": "The message pressures the user to verify an account through a link.",
          "detectedSignals": ["Urgent tone", "Account pressure", "External link"]
        }
        """
    }

    private static func successHTTPResult(modelJSON: String) -> (Data, HTTPURLResponse) {
        let escapedModelJSON = modelJSON
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let responseJSON = """
        {
          "candidates": [
            {
              "content": {
                "role": "model",
                "parts": [
                  {
                    "text": "\(escapedModelJSON)"
                  }
                ]
              }
            }
          ]
        }
        """

        return (
            responseJSON.data(using: .utf8)!,
            httpResponse(statusCode: 200)
        )
    }

    private static func httpResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}

private final class MockHTTPClient: HTTPClient {
    private let result: Result<(Data, HTTPURLResponse), Error>
    private(set) var requests: [URLRequest] = []

    init(result: Result<(Data, HTTPURLResponse), Error>) {
        self.result = result
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        return try result.get()
    }
}
