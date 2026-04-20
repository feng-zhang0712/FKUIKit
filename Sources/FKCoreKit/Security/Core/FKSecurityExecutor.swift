import Foundation

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
    try await withCheckedThrowingContinuation { continuation in
      queue.async {
        do {
          continuation.resume(returning: try work())
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

