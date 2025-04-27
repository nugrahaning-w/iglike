import UIKit
import Foundation

enum MediaType: String, Codable {
    case photo = "Photo"
    case video = "Video"
}

struct Media: Codable, Identifiable {
    let type: String // "Photo" or "Video"
    let id: Int
    let width: Int
    let height: Int
    let url: String
    
    // Photo-specific fields
    let photographer: String?
    let photographer_url: String?
    let photographer_id: Int?
    let src: MediaSource?
    
    // Video-specific fields
    let duration: Int?
    let full_res: String?
    let tags: [String]?
    let image: String?
    let user: VideoUser? // Ensure VideoUser conforms to Codable
    let video_files: [VideoFile]? // Ensure VideoFile conforms to Codable
    let video_pictures: [VideoPicture]? // Ensure VideoPicture conforms to Codable
    
    // Common fields
    let avg_color: String?
    let liked: Bool?
    let alt: String?

    var isVideo: Bool {
        return type == "Video"
    }
    
    var isPhoto: Bool {
        return type == "Photo"
    }

    var contentHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        if type == "Photo" {
            return screenWidth / 3
        } else if type == "Video" {
            return width > height ? screenWidth / 3 : (2 * screenWidth) / 4
        }
        return screenWidth / 3
    }

    enum CodingKeys: String, CodingKey {
        case type, id, width, height, url, photographer
        case photographer_url = "photographer_url"
        case photographer_id = "photographer_id"
        case avg_color = "avg_color"
        case src, liked, alt, duration, full_res, tags, image, user, video_files, video_pictures
    }
}

struct MediaSource: Codable {
    let original: String
    let large2x: String
    let large: String
    let medium: String
    let small: String
    let portrait: String
    let landscape: String
    let tiny: String
}
