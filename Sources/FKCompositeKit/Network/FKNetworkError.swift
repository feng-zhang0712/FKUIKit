//
// FKNetworkError.swift
//

import Foundation

public enum FKNetworkError: Error, Sendable {
  case invalidURL
  case encodingFailed(Error)
  case noResponse
  case httpError(statusCode: Int, data: Data?)
  case decodingFailed(Error)
  case networkFailure(Error)
  case cancelled
  case timeout
  case unknown
}

extension FKNetworkError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .invalidURL:                    return "Invalid URL"
    case .encodingFailed(let e):         return "Encoding failed: \(e.localizedDescription)"
    case .noResponse:                    return "No response from server"
    case .httpError(let code, _):        return "HTTP error \(code)"
    case .decodingFailed(let e):         return "Decoding failed: \(e.localizedDescription)"
    case .networkFailure(let e):         return "Network failure: \(e.localizedDescription)"
    case .cancelled:                     return "Request cancelled"
    case .timeout:                       return "Request timed out"
    case .unknown:                       return "Unknown error"
    }
  }
}
