//
//  NetworkingTests.swift
//  ScamDetectorTests
//
//  Created by Ivan Ishchuk on 23.05.2026.
// AI-Generated Test Suite, reviewed by Ivan Ishchuk


import XCTest
@testable import ScamDetector

@MainActor
final class NetworkingTests: XCTestCase {
    override func tearDown() {
            // reset the mock handler after each test to prevent bleed-over
            MockURLProtocol.requestHandler = nil
            super.tearDown()
        }

        func testSend_ReturnsDataAndHTTPResponseOnSuccess() async throws {
            let expectedData = "{\"status\": \"ok\"}".data(using: .utf8)!
            let expectedResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            MockURLProtocol.requestHandler = { request in
                return (expectedResponse, expectedData)
            }
            
            let sut = makeSUT()
            let request = URLRequest(url: anyURL())
            
            let (receivedData, receivedResponse) = try await sut.send(request)
            
            XCTAssertEqual(receivedData, expectedData)
            XCTAssertEqual(receivedResponse.statusCode, 200)
            XCTAssertEqual(receivedResponse.url, expectedResponse.url)
        }

        //non-http response edge case test
        func testSend_ThrowsInvalidResponse_WhenResponseIsNotHTTPURLResponse() async {
            let nonHTTPResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            
            MockURLProtocol.requestHandler = { request in
                return (nonHTTPResponse, Data())
            }
            
            let sut = makeSUT()
            let request = URLRequest(url: anyURL())
            
            do {
                _ = try await sut.send(request)
                XCTFail("Expected send() to throw GeminiScamAnalyzerError.invalidResponse, but it succeeded.")
            } catch GeminiScamAnalyzerError.invalidResponse {
                // Success: the guard statement worked correctly
                XCTAssertTrue(true)
            } catch {
                XCTFail("Expected GeminiScamAnalyzerError.invalidResponse, got \(error).")
            }
        }

        // network failure edge case test
        func testSend_BubblesUpURLError_OnNetworkFailure() async {
            let expectedError = URLError(.notConnectedToInternet)
            
            MockURLProtocol.requestHandler = { request in
                throw expectedError
            }
            
            let sut = makeSUT()
            let request = URLRequest(url: anyURL())
            
            do {
                _ = try await sut.send(request)
                XCTFail("Expected send() to throw an error, but it succeeded.")
            } catch let error as URLError {
                // Success: the URLSession correctly threw the underlying hardware error
                XCTAssertEqual(error.code, .notConnectedToInternet)
            } catch {
                XCTFail("Expected URLError, got \(error).")
            }
        }

        // helpers
        private func makeSUT() -> URLSessionHTTPClient {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: configuration)
            return URLSessionHTTPClient(session: session)
        }
        
        private func anyURL() -> URL {
            return URL(string: "https://any-url.com")!
        }
    }

    // mock url protocol

    private class MockURLProtocol: URLProtocol {
        
        static var requestHandler: ((URLRequest) throws -> (URLResponse, Data))?
        
        override class func canInit(with request: URLRequest) -> Bool {
            // Intercept all requests
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let handler = MockURLProtocol.requestHandler else {
                fatalError("Handler is not set.")
            }
            
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        override func stopLoading() {
            // Required method, but no implementation needed for this mock
        }
}
