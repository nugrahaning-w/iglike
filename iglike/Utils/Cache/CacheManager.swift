import Foundation
import UIKit

final class CacheManager {
    static let shared = CacheManager()
    private let imageCache = NSCache<NSString, UIImage>()
    private let videoCache = NSCache<NSString, NSData>()
    private let maxCacheSize = 100 * 1024 * 1024  // 100MB
    private let cacheQueue = DispatchQueue(label: "com.iglike.cacheQueue", attributes: .concurrent)
    
    // Track cache sizes manually
    private var imageCacheSize: Int = 0
    private var videoCacheSize: Int = 0

    private init() {
        setupCache()
    }
    
    private func setupCache() {
        imageCache.countLimit = 100
        videoCache.countLimit = 50
    }

    // MARK: - Image Caching
    func cacheImage(_ image: UIImage, forKey key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.imageCache.setObject(image, forKey: key as NSString)
            let imageSize = Int(image.size.width * image.size.height * 4) // Estimate size
            self.imageCacheSize += imageSize
            self.checkCacheSize()
        }
    }

    func getImage(forKey key: String) -> UIImage? {
        return cacheQueue.sync { imageCache.object(forKey: key as NSString) }
    }

    // MARK: - Video Caching
    func cacheVideo(_ data: Data, forKey key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.videoCache.setObject(data as NSData, forKey: key as NSString)
            self.videoCacheSize += data.count
            self.checkCacheSize()
        }
    }

    func getVideo(forKey key: String) -> Data? {
        return cacheQueue.sync { videoCache.object(forKey: key as NSString) as Data? }
    }

    private func checkCacheSize() {
        let totalSize = imageCacheSize + videoCacheSize
        if totalSize > maxCacheSize {
            clearOldCache()
        }
    }

    func clearOldCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.imageCache.removeAllObjects()
            self?.videoCache.removeAllObjects()
            self?.imageCacheSize = 0
            self?.videoCacheSize = 0
        }
    }
}
