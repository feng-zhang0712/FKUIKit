import Foundation

/// Tracks a simple 1-based page index for list APIs.
public struct FKRefreshPagination: Equatable, Sendable {
  public private(set) var page: Int

  public init(startingPage: Int = 1) {
    self.page = max(1, startingPage)
  }

  /// Call when the user pulls to refresh — resets to the first page.
  public mutating func resetForNewRequest() {
    page = 1
  }

  /// Call after a successful “next page” response.
  public mutating func advance() {
    page += 1
  }
}
