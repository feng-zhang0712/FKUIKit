import Foundation
import FKCoreKit

// MARK: - DTOs
//
// FKKitExamples sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which makes
// synthesized `Codable` conformances main-actor-isolated. `Requestable.Response`
// must be `Decodable & Sendable` for use from networking callbacks, so we use
// manual `nonisolated` decoding (and keep types `Sendable`).

/// Sample user payload from JSONPlaceholder `/users/:id`.
struct FKNetworkDemoUser: Sendable {
  let id: Int
  let name: String
  let username: String?
  let email: String?
}

extension FKNetworkDemoUser: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(Int.self, forKey: .id)
    name = try c.decode(String.self, forKey: .name)
    username = try c.decodeIfPresent(String.self, forKey: .username)
    email = try c.decodeIfPresent(String.self, forKey: .email)
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, username, email
  }
}

/// Sample post payload from JSONPlaceholder `/posts`.
struct FKNetworkDemoPost: Sendable {
  let userId: Int
  let id: Int?
  let title: String
  let body: String
}

extension FKNetworkDemoPost: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    userId = try c.decode(Int.self, forKey: .userId)
    id = try c.decodeIfPresent(Int.self, forKey: .id)
    title = try c.decode(String.self, forKey: .title)
    body = try c.decode(String.self, forKey: .body)
  }

  private enum CodingKeys: String, CodingKey {
    case userId
    case id
    case title
    case body
  }
}

/// Decodes a top-level JSON array of posts (API returns `[{...}, ...]`).
struct FKNetworkDemoPostList: Sendable {
  let posts: [FKNetworkDemoPost]
}

extension FKNetworkDemoPostList: Decodable {
  nonisolated init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var items: [FKNetworkDemoPost] = []
    while !container.isAtEnd {
      items.append(try container.decode(FKNetworkDemoPost.self))
    }
    posts = items
  }
}

// MARK: - Requests

struct FKNetworkGETRequest: Requestable {
  typealias Response = FKNetworkDemoUser

  let userID: Int

  var path: String { "/users/\(userID)" }
  var method: HTTPMethod { .get }
}

struct FKNetworkPOSTRequest: Requestable {
  typealias Response = FKNetworkDemoPost

  let title: String
  let body: String
  let userID: Int

  var path: String { "/posts" }
  var method: HTTPMethod { .post }
  var encoding: ParameterEncoding { .json }
  var bodyParameters: [String: Any] {
    ["title": title, "body": body, "userId": userID]
  }
}

struct FKNetworkCommonQueryRequest: Requestable {
  typealias Response = FKNetworkDemoPostList

  var path: String { "/posts" }
  var method: HTTPMethod { .get }
  var queryItems: [String: String] { ["_limit": "5"] }
}

struct FKNetworkCustomHeaderRequest: Requestable {
  typealias Response = FKNetworkDemoPostList

  var path: String { "/posts" }
  var method: HTTPMethod { .get }
  var queryItems: [String: String] { ["_limit": "3"] }
  var headers: [String: String] { ["X-Demo-Header": "FKNetworkExample"] }
}

struct FKNetworkCachedRequest: Requestable {
  typealias Response = FKNetworkDemoUser

  let userID: Int

  var path: String { "/users/\(userID)" }
  var method: HTTPMethod { .get }
  var cachePolicy: NetworkCachePolicy { .memoryAndDisk(ttl: 120) }
}

struct FKNetworkCancellableRequest: Requestable {
  typealias Response = FKNetworkDemoPostList

  var path: String { "/posts" }
  var method: HTTPMethod { .get }
  var queryItems: [String: String] { ["_limit": "100"] }
}
