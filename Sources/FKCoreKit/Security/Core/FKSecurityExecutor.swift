import Foundation

private final class FKSecurityWorkBox<T>: @unchecked Sendable {
  let work: () throws -> T
  init(_ work: @escaping () throws -> T) { self.work = work }
}

/// Default executor for FKSecurity operations.
public final class FKSecurityExecutor: FKSecurityExecuting {
  private let queue: DispatchQueue

  /// Creates an executor with a dedicated concurrent queue.
  ///
  /// - Parameter label: Queue label for debugging and profiling.
  public init(label: String = "com.fkkit.security.executor") {
    self.queue = DispatchQueue(label: label, qos: .userInitiated, attributes: .concurrent)
  }

  public func run<T>(_ work: @escaping () throws -> T) async throws -> T {
    let box = FKSecurityWorkBox(work)
    return try await withCheckedThrowingContinuation { continuation in
      queue.async {
        do {
          continuation.resume(returning: try box.work())
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
