//
// FKRequest.swift
//

import Foundation

public enum FKRequestBody: Sendable {
  case json([String: any Sendable])
  case encodable(any (Encodable & Sendable))
  case raw(Data, contentType: String)
  case formData([String: String])
}

/// A chainable request builder.
public final class FKRequest: @unchecked Sendable {

  // MARK: - Properties

  var method: FKHTTPMethod = .get
  var path: String = ""
  var queryItems: [URLQueryItem] = []
  var body: FKRequestBody?
  var headers: [String: String] = [:]
  var timeoutInterval: TimeInterval?
  var cachePolicy: URLRequest.CachePolicy?
  var retryCount: Int?
  var tag: String?

  // MARK: - Init

  public init(_ method: FKHTTPMethod = .get, path: String = "") {
    self.method = method
    self.path = path
  }

  // MARK: - Chain

  @discardableResult
  public func method(_ method: FKHTTPMethod) -> Self {
    self.method = method; return self
  }

  @discardableResult
  public func path(_ path: String) -> Self {
    self.path = path; return self
  }

  @discardableResult
  public func query(_ key: String, _ value: String?) -> Self {
    guard let value else { return self }
    queryItems.append(URLQueryItem(name: key, value: value))
    return self
  }

  @discardableResult
  public func query(_ params: [String: String?]) -> Self {
    params.forEach { k, v in _ = query(k, v) }
    return self
  }

  @discardableResult
  public func body(_ body: FKRequestBody) -> Self {
    self.body = body; return self
  }

  @discardableResult
  public func json(_ dict: [String: any Sendable]) -> Self {
    body = .json(dict); return self
  }

  @discardableResult
  public func encode<T: Encodable & Sendable>(_ value: T) -> Self {
    body = .encodable(value); return self
  }

  @discardableResult
  public func header(_ key: String, _ value: String) -> Self {
    headers[key] = value; return self
  }

  @discardableResult
  public func headers(_ dict: [String: String]) -> Self {
    dict.forEach { headers[$0] = $1 }; return self
  }

  @discardableResult
  public func timeout(_ interval: TimeInterval) -> Self {
    timeoutInterval = interval; return self
  }

  @discardableResult
  public func cache(_ policy: URLRequest.CachePolicy) -> Self {
    cachePolicy = policy; return self
  }

  @discardableResult
  public func retry(_ count: Int) -> Self {
    retryCount = count; return self
  }

  @discardableResult
  public func tag(_ tag: String) -> Self {
    self.tag = tag; return self
  }
}
