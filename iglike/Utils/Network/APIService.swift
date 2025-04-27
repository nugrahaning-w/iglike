//
//  APIService.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 25/04/25.
//

import Foundation
import Combine

protocol APIServiceType {
    var session: URLSession { get }
    var baseURL: String { get }
    func call<Request>(from endpoint: Request) -> AnyPublisher<Request.ModelType, Error> where Request: APIRequestType
}

final class APIService: APIServiceType {
    internal let baseURL: String
    internal let session: URLSession

    init(baseURL: String = "https://api.pexels.com/v1/", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func call<Request>(from endpoint: Request) -> AnyPublisher<Request.ModelType, Error> where Request: APIRequestType {
        do {
            let request = try endpoint.buildRequest(baseURL: baseURL)
            
            return session.dataTaskPublisher(for: request)
                .tryMap { data, response -> Data in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIServiceError.unexpectedResponse
                    }
                    
                    guard HTTPCodes.success.contains(httpResponse.statusCode) else {
                        throw APIServiceError.httpError(httpResponse.statusCode)
                    }
                    return data
                }
                .decode(type: Request.ModelType.self, decoder: JSONDecoder())
                .mapError { error in
                    return error
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func logCurlCommand(for request: URLRequest) {
        guard let url = request.url else { return }
        var components = ["curl -v"]
        
        components.append("'\(url.absoluteString)'")
        
        if let method = request.httpMethod {
            components.append("-X \(method)")
        }
        
        request.allHTTPHeaderFields?.forEach { key, value in
            components.append("-H '\(key): \(value)'")
        }
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            components.append("-d '\(bodyString)'")
        }
        
        print(components.joined(separator: " "))
    }
}
