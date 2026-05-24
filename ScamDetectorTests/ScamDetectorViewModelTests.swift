//
//  ScamDetectorViewModelTests.swift
//  ScamDetectorTests
//
//  Created by Ivan Ishchuk on 24.05.2026.
// AI-Generated Test Suite, reviewed by Ivan Ishchuk


import XCTest
@testable import ScamDetector

@MainActor
final class ScamDetectorViewModelTests: XCTestCase {

    func testInitialState() {
        let viewModel = ScamDetectorViewModel(analyzer: MockScamAnalyzer())
        
        XCTAssertTrue(viewModel.messageText.isEmpty)
        XCTAssertFalse(viewModel.canAnalyze)
        
        // Assert initial state is idle
        if case .idle = viewModel.analysisState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Initial state should be .idle")
        }
    }

    func testCanAnalyzeIsFalseWhenMessageIsEmptyOrWhitespace() {
        let viewModel = ScamDetectorViewModel(analyzer: MockScamAnalyzer())
        
        viewModel.messageText = ""
        XCTAssertFalse(viewModel.canAnalyze)
        
        viewModel.messageText = "    \n   "
        XCTAssertFalse(viewModel.canAnalyze)
    }

    func testCanAnalyzeIsTrueWhenMessageIsValid() {
        let viewModel = ScamDetectorViewModel(analyzer: MockScamAnalyzer())
        
        viewModel.messageText = "Here is a message"
        XCTAssertTrue(viewModel.canAnalyze)
    }

    func testSelectExampleUpdatesTextAndResetsState() {
        let viewModel = ScamDetectorViewModel(analyzer: MockScamAnalyzer())
        viewModel.messageText = "Random text"
        
        // Force the state to something other than idle
        viewModel.analysisState = .failed("Some error")
        
        guard let example = viewModel.exampleMessages.first else {
            XCTFail("No example messages found to test.")
            return
        }
        
        viewModel.selectExample(example)
        
        XCTAssertEqual(viewModel.messageText, example.message)
        if case .idle = viewModel.analysisState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Selecting an example should reset state to .idle")
        }
    }

    func testClearMessageResetsTextAndState() {
        let viewModel = ScamDetectorViewModel(analyzer: MockScamAnalyzer())
        viewModel.messageText = "Some text"
        viewModel.analysisState = .failed("Some error")
        
        viewModel.clearMessage()
        
        XCTAssertTrue(viewModel.messageText.isEmpty)
        if case .idle = viewModel.analysisState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Clearing message should reset state to .idle")
        }
    }

    func testAnalyzeWithEmptyTextSetsFailedState() async {
        let viewModel = ScamDetectorViewModel(analyzer: MockScamAnalyzer())
        viewModel.messageText = "   " // Just whitespace
        
        await viewModel.analyze()
        
        if case .failed(let errorMessage) = viewModel.analysisState {
            XCTAssertEqual(errorMessage, "Enter a message or URL to analyze.")
        } else {
            XCTFail("Expected .failed state for empty input")
        }
    }

    func testAnalyzeHappyPathTransitionsToSuccess() async {
        let expectedResult = ScamAnalysisResult(
            riskLevel: .suspicious,
            confidenceScore: 85,
            explanation: "Mock explanation",
            detectedSignals: ["Mock signal"]
        )
        
        let mockAnalyzer = MockScamAnalyzer(result: .success(expectedResult))
        let viewModel = ScamDetectorViewModel(analyzer: mockAnalyzer)
        
        viewModel.messageText = "Suspicious message here"
        
        // Execute the analyze function
        await viewModel.analyze()
        
        if case .success(let result) = viewModel.analysisState {
            XCTAssertEqual(result.riskLevel, .suspicious)
            XCTAssertEqual(result.confidenceScore, 85)
        } else {
            XCTFail("Expected .success state after successful analysis")
        }
        
        XCTAssertEqual(mockAnalyzer.capturedMessages.count, 1)
        XCTAssertEqual(mockAnalyzer.capturedMessages.first, "Suspicious message here")
    }

    func testAnalyzeFailureTransitionsToFailedState() async {
        let mockError = NSError(domain: "TestError", code: -1, userInfo: nil)
        let mockAnalyzer = MockScamAnalyzer(result: .failure(mockError))
        
        let viewModel = ScamDetectorViewModel(analyzer: mockAnalyzer)
        viewModel.messageText = "Will fail"
        
        await viewModel.analyze()
        
        if case .failed(let errorMessage) = viewModel.analysisState {
            XCTAssertEqual(errorMessage, mockError.localizedDescription)
        } else {
            XCTFail("Expected .failed state after analyzer throws an error")
        }
    }

}

// MARK: - Mock Analyzer

private final class MockScamAnalyzer: ScamAnalyzing {
    let result: Result<ScamAnalysisResult, Error>
    let delay: TimeInterval
    private(set) var capturedMessages: [String] = []
    
    init(delay: TimeInterval = 0.0, result: Result<ScamAnalysisResult, Error> = .success(ScamAnalysisResult(riskLevel: .safe, confidenceScore: 0, explanation: "", detectedSignals: []))) {
        self.delay = delay
        self.result = result
    }
    
    func analyze(message: String) async throws -> ScamAnalysisResult {
        capturedMessages.append(message)
        
        // Simulate network latency if a delay is provided
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Ensure we check for cancellation before returning, just like URLSession does natively
        try Task.checkCancellation()
        
        switch result {
        case .success(let analysis):
            return analysis
        case .failure(let error):
            throw error
        }
    }
}
