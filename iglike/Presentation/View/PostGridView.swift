//
//  PostGridView.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 24/04/25.
//

import SwiftUI
import AVKit
import UIKit

struct Player: UIViewControllerRepresentable {
    var player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let view = AVPlayerViewController()
        view.player = player
        view.videoGravity = .resizeAspectFill
        
        // Add observer for video completion
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        return view
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
    
    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        NotificationCenter.default.removeObserver(uiViewController)
    }
}

struct PostGridView<ViewModel: MediaGridViewModelType>: View {
    @ObservedObject var viewModel: ViewModel
    let spacing: CGFloat
    @State private var currentlyPlayingVideoID: Int? // Track the currently playing video
    @State private var loadingStates: [Int: Bool] = [:] // Add this to track loading states by item ID
    @State private var players: [Int: AVPlayer] = [:] // Add this to track players for each video
    @State private var imageCache: NSCache<NSString, UIImage> = NSCache<NSString, UIImage>()
    @Environment(\.scenePhase) private var scenePhase
    @State private var scrollPosition: CGPoint = .zero
    @State private var viewAppeared = [Int: Bool]()
    
    var body: some View {
        let columns = viewModel.mediaColumns
        return ScrollView {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(columns.indices, id: \.self) { index in
                    createColumnView(column: columns[index])
                }
            }
            .background(Color.white)
            .padding(.horizontal, spacing)
        }
        .scrollDisabled(false)
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onDisappear {
            cleanupUnusedPlayers()
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .inactive || newPhase == .background {
            pauseAllVideos()
        }
    }
    
    private func createColumnView(column: MediaColumn) -> some View {
        LazyVStack(spacing: spacing) {
            ForEach(column.gridItems) { gridItem in
                createMediaItemView(for: gridItem)
                    .id("\(gridItem.id)-\(gridItem.type)")  // Stable identifier
                    .onAppear {
                        viewAppeared[gridItem.id] = true
                    }
                    .onDisappear {
                        if viewModel.mediaColumns.flatMap({ $0.gridItems }).first(where: { $0.id == gridItem.id }) == nil {
                            viewAppeared[gridItem.id] = false
                            if gridItem.type == "Video" {
                                players[gridItem.id]?.pause()
                                players[gridItem.id] = nil
                            }
                        }
                    }
            }
        }
    }

    private func createMediaItemView(for gridItem: Media) -> some View {
        Group {
            if gridItem.type == "Photo" {
                getImageView(gridItem: gridItem)
            } else if gridItem.type == "Video" {
                getVideoView(gridItem: gridItem)
            } else {
                EmptyView()
            }
        }
    }
    
    private func initializePlayer(for gridItem: Media, url: URL) -> AVPlayer {
        if let existingPlayer = players[gridItem.id] {
            return existingPlayer
        } else {
            let newPlayer = AVPlayer(url: url)
            newPlayer.actionAtItemEnd = .none
            DispatchQueue.main.async {
                players[gridItem.id] = newPlayer
            }
            return newPlayer
        }
    }

    private func getVideoView(gridItem: Media) -> some View {
        Group {
            if let videoFiles = gridItem.video_files,
               let sdVideo = videoFiles.first(where: { ($0.quality ?? "").lowercased() == "sd" }),
               let url = URL(string: sdVideo.link) {
                videoPlayerView(gridItem: gridItem, url: url)
                    .id(gridItem.id)
            } else {
                fallbackVideoView(gridItem: gridItem)
            }
        }
    }

    private func videoPlayerView(gridItem: Media, url: URL) -> some View {
        let player = initializePlayer(for: gridItem, url: url)
        
        return ZStack {
            if loadingStates[gridItem.id, default: true] {
                ShimmerView()
                    .frame(height: CGFloat(gridItem.height) / CGFloat(gridItem.width) * UIScreen.main.bounds.width / 3)
            }
            
            Player(player: player)
                .opacity(loadingStates[gridItem.id, default: true] ? 0 : 1)
                .onAppear {
                    if viewAppeared[gridItem.id] == true {
                        player.play()
                    }
                    DispatchQueue.main.async {
                        loadingStates[gridItem.id] = false
                    }
                }
                .onDisappear {
                    player.pause()
                }
        }
        .animation(.easeInOut, value: loadingStates[gridItem.id])
        .frame(height: CGFloat(gridItem.height) / CGFloat(gridItem.width) * UIScreen.main.bounds.width / 3)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(Rectangle())
    }

    private func fallbackVideoView(gridItem: Media) -> some View {
        Group {
            if let imageUrl = URL(string: gridItem.image ?? "") {
                thumbnailImageView(url: imageUrl, height: gridItem.contentHeight)
            } else {
                ShimmerView()
                    .frame(height: gridItem.contentHeight)
            }
        }
    }

    private func thumbnailImageView(url: URL, height: CGFloat) -> some View {
        CachedAsyncImage(url: url, cache: imageCache) { phase in
            Group { // Use Group to ensure consistent return type
                switch phase {
                case .empty:
                    ShimmerView()
                        .frame(height: height)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: height)
                        .clipped()
                case .failure:
                    Color.gray
                        .frame(height: height)
                @unknown default:
                    Color.clear // Ensure a consistent fallback view
                        .frame(height: height)
                }
            }
        }
    }

    private func prepareVideo(url: URL, for gridItem: Media) {
        guard players[gridItem.id] == nil else { return }
        
        let asset = AVURLAsset(url: url)
        
        if #available(iOS 16.0, *) {
            Task {
                do {
                    let isPlayable = try await asset.load(.isPlayable)
                    if isPlayable {
                        DispatchQueue.main.async {
                            let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                            player.automaticallyWaitsToMinimizeStalling = true
                            players[gridItem.id] = player
                        }
                    }
                } catch {
                    print("Failed to load asset: \(error.localizedDescription)")
                }
            }
        } else {
            asset.loadValuesAsynchronously(forKeys: ["playable"]) {
                DispatchQueue.main.async {
                    let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                    player.automaticallyWaitsToMinimizeStalling = true
                    players[gridItem.id] = player
                }
            }
        }
    }

    private func pauseAllVideos() {
        players.values.forEach { $0.pause() }
    }

    private func cleanupUnusedPlayers() {
        let currentIds = Set(viewModel.mediaColumns.flatMap { $0.gridItems }.map { $0.id })
        players.forEach { id, player in
            if !currentIds.contains(id) {
                player.pause()
                players[id] = nil
                loadingStates[id] = nil
                viewAppeared[id] = nil
            }
        }
    }

    private func cacheVideo(from url: URL, withKey key: String, retries: Int = 3) async {
        var currentRetry = 0
        while currentRetry < retries {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                CacheManager.shared.cacheVideo(data, forKey: key)
                return
            } catch {
                currentRetry += 1
                if currentRetry < retries {
                    try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(currentRetry)) * 1_000_000_000))
                } else {
                    print("Failed to cache video after multiple retries: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getImageView(gridItem: Media) -> some View {
        Group {
            if let url = URL(string: gridItem.src?.medium ?? "") {
                CachedAsyncImage(url: url, cache: imageCache) { phase in
                    switch phase {
                    case .empty:
                        ShimmerView()
                            .frame(height: CGFloat(gridItem.height) / CGFloat(gridItem.width) * UIScreen.main.bounds.width / 3)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: CGFloat(gridItem.height) / CGFloat(gridItem.width) * UIScreen.main.bounds.width / 3)
                            .clipped()
                    case .failure(_):
                        Color.gray
                            .frame(height: CGFloat(gridItem.height) / CGFloat(gridItem.width) * UIScreen.main.bounds.width / 3)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                EmptyView()
            }
        }
    }

    private func cacheImage(from url: URL, withKey key: String, retries: Int = 3) async {
        var currentRetry = 0
        while currentRetry < retries {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    CacheManager.shared.cacheImage(uiImage, forKey: key)
                    return
                } else {
                    throw URLError(.cannotDecodeContentData)
                }
            } catch {
                currentRetry += 1
                if currentRetry < retries {
                    try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(currentRetry)) * 1_000_000_000))
                } else {
                    print("Failed to cache image after multiple retries: \(error.localizedDescription)")
                }
            }
        }
    }
}

// Add CachedAsyncImage view
struct CachedAsyncImage<Content: View>: View {
    private let url: URL
    private let cache: NSCache<NSString, UIImage>
    private let content: (AsyncImagePhase) -> Content
    
    init(url: URL, cache: NSCache<NSString, UIImage>, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.cache = cache
        self.content = content
    }
    
    var body: some View {
        Group {
            if let cached = cache.object(forKey: url.absoluteString as NSString) {
                content(.success(Image(uiImage: cached)))
            } else {
                AsyncImage(url: url, content: { phase in
                    if case .success(let image) = phase {
                        content(phase)
                            .onAppear {
                                Task {
                                    await cacheImage(image) // Added 'await' to fix the error
                                }
                            }
                    } else {
                        content(phase)
                    }
                })
            }
        }
    }
    
    private func cacheImage(_ image: Image) async {
        await Task.detached(priority: .background) {
            if let uiImage = await MainActor.run(body: { image.asUIImage() }) {
                await MainActor.run {
                    cache.setObject(uiImage, forKey: url.absoluteString as NSString) // Confined to main actor
                }
            }
        }.value
    }
}

// Add Image extension
extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self.resizable()) // Ensure the Image is resizable
        let view = controller.view

        // Set the bounds and background color
        let targetSize = CGSize(width: 100, height: 100) // Adjust size as needed
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        // Render the view into a UIImage
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}

