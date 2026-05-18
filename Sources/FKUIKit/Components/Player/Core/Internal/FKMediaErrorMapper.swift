import AVFoundation
import Foundation

/// Maps system errors into ``FKMediaError``.
enum FKMediaErrorMapper {

  static func map(_ error: Error, engine: FKMediaEngineKind) -> FKMediaError {
    if let mediaError = error as? FKMediaError {
      return mediaError
    }

    let nsError = error as NSError
    if nsError.domain == NSURLErrorDomain {
      switch nsError.code {
      case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorDataNotAllowed:
        return .networkUnavailable
      case NSURLErrorCancelled:
        return .cancelled
      default:
        break
      }
    }

    if let httpCode = nsError.userInfo["HTTPStatusCode"] as? Int {
      return .httpStatus(code: httpCode)
    }

    if nsError.domain == AVFoundationErrorDomain,
       nsError.code == AVError.contentIsUnavailable.rawValue
        || nsError.code == AVError.contentIsNotAuthorized.rawValue {
      return .drmFailed(message: error.localizedDescription)
    }

    return .engineFailed(engine: engine, message: error.localizedDescription)
  }

  static func mapPlayerItemError(_ error: Error?) -> FKMediaError? {
    guard let error else { return nil }
    return map(error, engine: .avFoundation)
  }
}
