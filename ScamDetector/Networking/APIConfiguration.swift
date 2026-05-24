//
//  APIConfiguration.swift
//  ScamDetector
//
//  Created by Ivan Ishchuk on 23.05.2026.
//

import Foundation

struct APIConfiguration {
    let apiKey: String
    let modelName: String
    let baseURL: URL

    init(
        apiKey: String = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "",
        modelName: String = ProcessInfo.processInfo.environment["GEMINI_MODEL"] ?? "gemini-3.5-flash",
        baseURL: URL = URL(string: "https://generativelanguage.googleapis.com")!
    ) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.baseURL = baseURL
    }
}
