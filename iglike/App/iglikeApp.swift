//
//  iglikeApp.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 24/04/25.
//

import SwiftUI

@main
struct iglikeApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel(repository: MediaRepositoryImpl(service: MediaService())))
        }
    }
}

