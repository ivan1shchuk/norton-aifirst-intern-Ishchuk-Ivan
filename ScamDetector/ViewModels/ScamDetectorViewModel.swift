//
//  ScamDetectorViewModel.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation
import Observation

@MainActor
@Observable final class ScamDetectorViewModel {
    var messageText: String
    internal(set) var analysisState: ScamAnalysisState

    let exampleMessages: [ScamExampleMessage]
    private let analyzer: any ScamAnalyzing

    var canAnalyze: Bool {
        !trimmedMessage.isEmpty && !analysisState.isAnalyzing
    }

    init(
        messageText: String = "",
        analysisState: ScamAnalysisState = .idle,
        exampleMessages: [ScamExampleMessage]? = nil,
        analyzer: (any ScamAnalyzing)? = nil
    ) {
        self.messageText = messageText
        self.analysisState = analysisState
        self.exampleMessages = exampleMessages ?? Self.defaultExampleMessages
        self.analyzer = analyzer ?? GeminiScamAnalyzer()
    }

    func analyze() async {
        let message = trimmedMessage

        guard !message.isEmpty else {
            analysisState = .failed("Enter a message or URL to analyze.")
            return
        }

        analysisState = .analyzing

        do {
            let result = try await analyzer.analyze(message: message)
            analysisState = .success(result)
        } catch is CancellationError {
            analysisState = .idle
        } catch {
            analysisState = .failed(error.localizedDescription)
        }
    }

    func selectExample(_ example: ScamExampleMessage) {
        messageText = example.message
        analysisState = .idle
    }

    func clearMessage() {
        messageText = ""
        analysisState = .idle
    }

    private var trimmedMessage: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let defaultExampleMessages = [
        ScamExampleMessage(
            id: "package-delivery",
            title: "Package",
            message: "Your package is on hold due to an unpaid delivery fee. Pay $1.99 here to release it: https://delivery-update.example/pay",
            expectedRiskLevel: .dangerous
        ),
        ScamExampleMessage(
            id: "bank-account",
            title: "Bank",
            message: "URGENT: Your bank account has been locked. Verify your identity now at http://secure-bank-login.example to avoid closure.",
            expectedRiskLevel: .dangerous
        ),
        ScamExampleMessage(
            id: "job-opportunity",
            title: "Job",
            message: "We found your resume and want to offer you a remote job paying $850 per week. Send your full name, address, and banking details to start today.",
            expectedRiskLevel: .suspicious
        ),
        ScamExampleMessage(
            id: "subscription-renewal",
            title: "Renewal",
            message: "Your subscription will renew today for $399.99. If this was not you, call 1-800-555-0148 immediately to cancel and receive a refund.",
            expectedRiskLevel: .suspicious
        )
    ]
}
