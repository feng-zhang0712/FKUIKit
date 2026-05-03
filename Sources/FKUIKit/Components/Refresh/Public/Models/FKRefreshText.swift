import UIKit

/// User-visible strings for the built-in ``FKDefaultRefreshContentView``.
///
/// Localize these strings at app launch, or override them per screen (e.g. for feature-specific copy).
public struct FKRefreshText: Equatable, Sendable {

  // MARK: Pull header

  public var pullToRefresh: String
  public var releaseToRefresh: String
  public var headerLoading: String
  public var headerFinished: String
  public var headerListEmpty: String
  public var headerFailed: String

  // MARK: Load-more footer

  public var footerLoading: String
  public var footerFinished: String
  public var footerNoMoreData: String
  public var footerFailed: String
  public var footerTapToRetry: String

  public init(
    pullToRefresh: String = "Pull to refresh",
    releaseToRefresh: String = "Release to refresh",
    headerLoading: String = "Loading…",
    headerFinished: String = "Up to date",
    headerListEmpty: String = "No content",
    headerFailed: String = "Couldn’t refresh",
    footerLoading: String = "Loading…",
    footerFinished: String = "Loaded",
    footerNoMoreData: String = "No more data",
    footerFailed: String = "Couldn’t load",
    footerTapToRetry: String = "Tap to retry"
  ) {
    self.pullToRefresh = pullToRefresh
    self.releaseToRefresh = releaseToRefresh
    self.headerLoading = headerLoading
    self.headerFinished = headerFinished
    self.headerListEmpty = headerListEmpty
    self.headerFailed = headerFailed
    self.footerLoading = footerLoading
    self.footerFinished = footerFinished
    self.footerNoMoreData = footerNoMoreData
    self.footerFailed = footerFailed
    self.footerTapToRetry = footerTapToRetry
  }

  public static let `default` = FKRefreshText()
}
