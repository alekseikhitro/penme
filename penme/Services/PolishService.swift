//
//  PolishService.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import Foundation

struct RewriteRequest: Codable {
    let transcript: String
    let locale: String
    let format: String
}

struct RewriteResponse: Codable {
    let title: String
    let polished_text: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case polished_text
    }
}

enum PolishServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

actor PolishService {
    private let baseURL: String
    private let apiKey: String?
    
    init(baseURL: String? = nil, apiKey: String? = nil) {
        // Check Info.plist first, then fall back to provided values or environment variables
        if let plistBaseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !plistBaseURL.isEmpty {
            self.baseURL = plistBaseURL
        } else if let providedBaseURL = baseURL, !providedBaseURL.isEmpty {
            self.baseURL = providedBaseURL
        } else if let envBaseURL = ProcessInfo.processInfo.environment["API_BASE_URL"], !envBaseURL.isEmpty {
            self.baseURL = envBaseURL
        } else {
            self.baseURL = "https://example.com"
        }
        
        if let plistAPIKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String, !plistAPIKey.isEmpty {
            self.apiKey = plistAPIKey
        } else if let providedAPIKey = apiKey, !providedAPIKey.isEmpty {
            self.apiKey = providedAPIKey
        } else if let envAPIKey = ProcessInfo.processInfo.environment["API_KEY"], !envAPIKey.isEmpty {
            self.apiKey = envAPIKey
        } else {
            self.apiKey = nil
        }
    }
    
    func rewrite(transcript: String, locale: String = Locale.current.identifier) async throws -> RewriteResponse {
        guard let url = URL(string: "\(baseURL)/rewrite") else {
            throw PolishServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = RewriteRequest(
            transcript: transcript,
            locale: locale,
            format: "title_and_polished_text"
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw PolishServiceError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            // Note: CodingKeys handles the snake_case mapping, so we don't need keyDecodingStrategy
            let rewriteResponse = try decoder.decode(RewriteResponse.self, from: data)
            return rewriteResponse
        } catch let error as PolishServiceError {
            throw error
        } catch let error as DecodingError {
            throw PolishServiceError.decodingError(error)
        } catch {
            throw PolishServiceError.networkError(error)
        }
    }
}
