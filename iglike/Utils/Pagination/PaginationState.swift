import Foundation

protocol PaginationStateType {
    var currentPage: Int { get set }
    var isLoading: Bool { get set }
    var hasMorePages: Bool { get set }
    var itemsPerPage: Int { get set }
}

struct PaginationState: PaginationStateType {
    var currentPage: Int = 1
    var isLoading: Bool = false
    var hasMorePages: Bool = true
    var itemsPerPage: Int = 50
}
