import Foundation

/// Shared main-queue marshaling for Skeleton UI mutations.
enum FKSkeletonDispatch {
  static func runOnMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async(execute: work)
    }
  }
}
