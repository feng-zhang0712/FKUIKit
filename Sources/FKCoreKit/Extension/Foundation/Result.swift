import Foundation

public extension Result {
  /// Wrapped success value or `nil` when `.failure`.
  var fk_successValue: Success? {
    switch self {
    case let .success(value):
      return value
    case .failure:
      return nil
    }
  }

  /// Wrapped failure value or `nil` when `.success`.
  var fk_failureValue: Failure? {
    switch self {
    case .success:
      return nil
    case let .failure(error):
      return error
    }
  }

  /// Maps success using `transform`.
  func fk_map<NewSuccess>(_ transform: (Success) throws -> NewSuccess) rethrows -> Result<NewSuccess, Failure> {
    switch self {
    case let .success(value):
      return .success(try transform(value))
    case let .failure(error):
      return .failure(error)
    }
  }

  /// Maps failure using `transform`.
  func fk_mapError<NewFailure>(_ transform: (Failure) throws -> NewFailure) rethrows -> Result<Success, NewFailure> {
    switch self {
    case let .success(value):
      return .success(value)
    case let .failure(error):
      return .failure(try transform(error))
    }
  }
}
