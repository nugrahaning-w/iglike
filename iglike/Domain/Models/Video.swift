import Foundation

struct Video: Codable, Identifiable {
    let id: Int
    let width: Int
    let height: Int
    let duration: Int
    let full_res: String?
    let tags: [String]
    let url: String
    let image: String
    let avg_color: String?
    let user: VideoUser
    let video_files: [VideoFile]
    let video_pictures: [VideoPicture]
}

struct VideoUser: Codable {
    let id: Int
    let name: String
    let url: String
}

struct VideoFile: Codable {
    let id: Int
    let quality: String? // Make quality optional since it can be null
    let file_type: String
    let width: Int
    let height: Int
    let fps: Double?
    let link: String
    let size: Int
}

struct VideoPicture: Codable {
    let id: Int
    let nr: Int
    let picture: String
}
