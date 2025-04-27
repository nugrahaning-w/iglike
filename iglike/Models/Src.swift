//
//  Src.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 25/04/25.
//
import Foundation

// MARK: - Src
struct Src : Codable {
    let original : String?
    let large2x : String?
    let large : String?
    let medium : String?
    let small : String?
    let portrait : String?
    let landscape : String?
    let tiny : String?

    enum CodingKeys: String, CodingKey {

        case original = "original"
        case large2x = "large2x"
        case large = "large"
        case medium = "medium"
        case small = "small"
        case portrait = "portrait"
        case landscape = "landscape"
        case tiny = "tiny"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        original = try values.decodeIfPresent(String.self, forKey: .original)
        large2x = try values.decodeIfPresent(String.self, forKey: .large2x)
        large = try values.decodeIfPresent(String.self, forKey: .large)
        medium = try values.decodeIfPresent(String.self, forKey: .medium)
        small = try values.decodeIfPresent(String.self, forKey: .small)
        portrait = try values.decodeIfPresent(String.self, forKey: .portrait)
        landscape = try values.decodeIfPresent(String.self, forKey: .landscape)
        tiny = try values.decodeIfPresent(String.self, forKey: .tiny)
    }

}
