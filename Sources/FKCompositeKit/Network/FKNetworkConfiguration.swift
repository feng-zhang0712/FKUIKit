//
// FKNetworkConfiguration.swift
//

import Foundation

public struct FKNetworkConfiguration: Sendable {

  public var baseURL: String
  public var defaultHeaders: [String: String]
  public var timeoutInterval: TimeInterval
  public var retryCount: Int
  public var retryDelay: TimeInterval
  public var cachePolicy: URLRequest.CachePolicy
  public var urlCacheMemoryCapacity: Int
  public var urlCacheDiskCapacity: Int
  public var logLevel: FKNetworkLogLevel

  public init(
    baseURL: String = "",
    defaultHeaders: [String: String] = ["Content-Type": "application/json", "Accept": "application/json"],
    timeoutInterval: TimeInterval = 30,
    retryCount: Int = 0,
    retryDelay: TimeInterval = 1,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    urlCacheMemoryCapacity: Int = 20 * 1024 * 1024,
    urlCacheDiskCapacity: Int = 100 * 1024 * 1024,
    logLevel: FKNetworkLogLevel = .none
  ) {
    self.baseURL = baseURL
    self.defaultHeaders = defaultHeaders
    self.timeoutInterval = timeoutInterval
    self.retryCount = retryCount
    self.retryDelay = retryDelay
    self.cachePolicy = cachePolicy
    self.urlCacheMemoryCapacity = urlCacheMemoryCapacity
    self.urlCacheDiskCapacity = urlCacheDiskCapacity
    self.logLevel = logLevel
  }
}

public enum FKNetworkLogLevel: Int, Sendable, Comparable {
  case none    = 0
  case error   = 1
  case info    = 2
  case verbose = 3

  public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
