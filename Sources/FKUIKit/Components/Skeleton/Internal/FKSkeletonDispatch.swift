import Foundation

/// Shared main-queue marshaling for Skeleton UI mutations.
enum FKSkeletonDispatch {
  static func runOnMain(_ work: @escaping () -> Void) {
    final class Box: @unchecked Sendable {
      let work: () -> Void
      init(_ work: @escaping () -> Void) { self.work = work }
    }
    let box = Box(work)
    if Thread.isMainThread {
      box.work()
    } else {
      DispatchQueue.main.async { box.work() }
    }
  }
}
