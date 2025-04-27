//
//  APIRequestType.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 24/04/25.
//

import Foundation

enum HTTPCodes {
    static let success = 200...299
}

enum APIServiceError: Error {
    case httpError(Int)
    case parseError
    case unexpectedResponse
}

protocol RequestBuilder {
    func buildRequest(baseURL: String) throws -> URLRequest
}

protocol APIRequestType: RequestBuilder {
    associatedtype ModelType: Decodable
    var path: String { get }
    var method: String { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
}

extension APIRequestType {
    func buildRequest(baseURL: String) throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        // Append path
        urlComponents.path += path
        
        // Add query items
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add headers
        headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
}
