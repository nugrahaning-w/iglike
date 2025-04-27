//
//  HomeView.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 24/04/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var isLoadingNextPage: Bool = false
    @State private var hasReachedBottom: Bool = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                if viewModel.isLoading && viewModel.mediaColumns.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 50)
                } else {
                    LazyVStack(spacing: 0) {
                        PostGridView(viewModel: viewModel, spacing: 1)
                        
                        if !viewModel.mediaColumns.isEmpty && !hasReachedBottom {
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        if isNearBottom(geometry: geometry) && !isLoadingNextPage {
                                            isLoadingNextPage = true
                                            viewModel.loadNextPage()
                                            checkIfLastPage()
                                        }
                                    }
                            }
                            .frame(height: 20)
                        }
                        
                        if viewModel.isLoading && !viewModel.mediaColumns.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
            }
            .refreshable {
                hasReachedBottom = false
                isLoadingNextPage = false
                viewModel.refresh()
            }
        }
    }

    private func isNearBottom(geometry: GeometryProxy) -> Bool {
        let scrollViewHeight = UIScreen.main.bounds.height
        let offset = geometry.frame(in: .global).maxY
        return offset < scrollViewHeight + 100
    }
    
    private func checkIfLastPage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !viewModel.isLoading {
                hasReachedBottom = !viewModel.hasMorePages
                isLoadingNextPage = false
            }
        }
    }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

