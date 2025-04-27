//
//  MediaService.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 25/04/25.
//

import Foundation
import Combine

protocol MediaServiceType {
    func call<Request: APIRequestType>(from endpoint: Request) -> AnyPublisher<Request.ModelType, Error>
}

final class MediaService: MediaServiceType {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "https://api.pexels.com/v1/", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
 
    func call<Request>(from endpoint: Request) -> AnyPublisher<Request.ModelType, Error> where Request: APIRequestType {
        do {
            let request = try endpoint.buildRequest(baseURL: baseURL)
            print("Making request to: \(request.url?.absoluteString ?? "unknown")")
            
            return session.dataTaskPublisher(for: request)
                .retry(1)
                .tryMap { output -> Data in
                    guard let code = (output.response as? HTTPURLResponse)?.statusCode else {
                        throw APIServiceError.unexpectedResponse
                    }
                    guard HTTPCodes.success.contains(code) else {
                        throw APIServiceError.httpError(code)
                    }
                    return output.data
                }
                .decode(type: Request.ModelType.self, decoder: JSONDecoder())
                .mapError { _ in APIServiceError.parseError }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
