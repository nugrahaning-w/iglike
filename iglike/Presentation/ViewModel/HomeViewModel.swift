//
//  HomeViewModel.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 25/04/25.
//

import Foundation
import Combine
import SwiftUI

struct MediaColumn: Identifiable {
    let id = UUID()
    var gridItems = [Media]()
}

protocol HomeViewModelInput {
    func refresh()
    func loadNextPageIfNeeded(currentItem: Media?)
    func loadNextPage()
}

protocol HomeViewModelOutput {
    var mediaColumns: [MediaColumn] { get }
    var isLoading: Bool { get }
    var error: String? { get }
    var hasMorePages: Bool { get }
}

protocol HomeViewModelType: HomeViewModelInput, HomeViewModelOutput {}

extension HomeViewModel: MediaGridViewModelType {}

final class HomeViewModel: ObservableObject, HomeViewModelType {
    @Published private(set) var mediaColumns: [MediaColumn] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var hasMorePages: Bool = true
    
    private var mediaData: [Media] = []
    private let repository: MediaRepository
    private var cancellables = Set<AnyCancellable>()
    private var paginationState: PaginationStateType

    init(repository: MediaRepository, paginationState: PaginationStateType = PaginationState()) {
        self.repository = repository
        self.paginationState = paginationState
        loadMedia()
    }

    func refresh() {
        loadMedia()
    }

    func loadNextPageIfNeeded(currentItem: Media?) {
        guard let currentItem = currentItem,
              let lastItem = mediaData.last,
              currentItem.id == lastItem.id,
              !paginationState.isLoading,
              paginationState.hasMorePages else {
            return
        }
        loadMedia(page: paginationState.currentPage + 1)
    }

    func loadNextPage() {
        guard !paginationState.isLoading && paginationState.hasMorePages else { return }
        loadMedia(page: paginationState.currentPage + 1)
    }

    private func loadMedia(page: Int = 1) {
        guard !paginationState.isLoading else { return }
        paginationState.isLoading = true
        isLoading = page == 1
        
        repository.fetchMedia(page: page, perPage: paginationState.itemsPerPage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.paginationState.isLoading = false
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.error = error.localizedDescription
                }
            } receiveValue: { [weak self] media in
                guard let self = self else { return }
                if page == 1 {
                    self.mediaData = media
                } else {
                    self.mediaData.append(contentsOf: media)
                }
                self.paginationState.currentPage = page
                self.hasMorePages = !media.isEmpty && media.count >= self.paginationState.itemsPerPage
                self.paginationState.hasMorePages = self.hasMorePages
                self.organizeMediaIntoColumns(mediaItems: self.mediaData, numOfColumns: 3)
            }
            .store(in: &cancellables)
    }

    private func organizeMediaIntoColumns(mediaItems: [Media], numOfColumns: Int) {
        guard !mediaItems.isEmpty else {
            self.mediaColumns = []
            return
        }
        var columns = [MediaColumn](repeating: MediaColumn(), count: numOfColumns)
        var columnsHeight = Array(repeating: CGFloat(0), count: numOfColumns)
        
        for mediaItem in mediaItems {
            let smallestColumnIndex = columnsHeight.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[smallestColumnIndex].gridItems.append(mediaItem)
            columnsHeight[smallestColumnIndex] += CGFloat(mediaItem.contentHeight)
        }
        self.mediaColumns = columns
    }
}
