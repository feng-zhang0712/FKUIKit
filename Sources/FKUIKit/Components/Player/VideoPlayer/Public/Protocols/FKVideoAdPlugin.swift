import Foundation
import UIKit

/// Hooks for pre/mid/post-roll ads (Phase 3 integrations).
@MainActor
public protocol FKVideoAdPlugin: AnyObject {
  func prepareAdBreak(kind: FKVideoAdBreakKind, for item: FKVideoItem) async throws
  func playAdBreak(from viewController: UIViewController?) async
  func teardownAdBreak()
}

public enum FKVideoAdBreakKind: Sendable {
  case preroll
  case midroll(index: Int)
  case postroll
}
