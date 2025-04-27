//
//  MediaListResponse.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 25/04/25.
//
import Foundation

// MARK: - MediaListResponse
struct MediaResponse: Codable {
    let page: Int
    let perPage: Int
    let media: [Media]
    let totalResults: Int
    let nextPage: String
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case page = "page"
        case perPage = "per_page"
        case media = "media"
        case totalResults = "total_results"
        case nextPage = "next_page"
        case id = "id"
    }
}
