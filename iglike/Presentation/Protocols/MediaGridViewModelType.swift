import SwiftUI

protocol MediaGridViewModelType: ObservableObject {
    var mediaColumns: [MediaColumn] { get }
    var isLoading: Bool { get }
    var error: String? { get }
}
