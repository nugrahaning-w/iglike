//
//  MediaRepository.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 24/04/25.
//

import Foundation
import Combine

struct MediaResponse: Decodable {
    let media: [Media]
    let page: Int
    let per_page: Int
    let total_results: Int
    let next_page: String?
    
    enum CodingKeys: String, CodingKey {
        case media
        case page
        case per_page
        case total_results
        case next_page
    }
}

protocol MediaRepository {
    func fetchMedia(page: Int, perPage: Int) -> AnyPublisher<[Media], Error>
}

final class MediaRepositoryImpl: MediaRepository {
    private let service: MediaService
    
    init(service: MediaService) {
        self.service = service
    }
    
    func fetchMedia(page: Int, perPage: Int) -> AnyPublisher<[Media], Error> {
        let request = MediaEndpoint.getMedia(page: page, perPage: perPage)
        return service.call(from: request)
            .map(\.media)
            .catch { error -> AnyPublisher<[Media], Error> in
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

enum MediaEndpoint {
    case getMedia(page: Int, perPage: Int)
}

extension MediaEndpoint: APIRequestType {
    typealias ModelType = MediaResponse
    
    var path: String {
        return "collections/d3factz" 
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getMedia(let page, let perPage): 
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)"),
                URLQueryItem(name: "sort", value: "asc")
            ]
        }
    }
    
    var headers: [String: String] {
        ["Authorization": "xE3ESnjm6UFoVb0N2uqgLCQA1rcFZ37pLRSUSeFuxvcRG7ikhlfQOhO7"]
    }
    
    var method: String { "GET" }
}
