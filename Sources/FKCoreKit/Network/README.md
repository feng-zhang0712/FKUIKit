# FKNetwork

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Architecture](#architecture)
- [Supported Features](#supported-features)
- [Requirements](#requirements)
- [Installation \& Integration](#installation--integration)
- [Quick Start (Basic Usage)](#quick-start-basic-usage)
- [Detailed Usage Guide](#detailed-usage-guide)
  - [Global Configuration](#global-configuration)
  - [GET Request](#get-request)
  - [POST Request](#post-request)
  - [async/await](#asyncawait)
  - [File Upload](#file-upload)
  - [File Download](#file-download)
  - [Cache Policy](#cache-policy)
  - [Request Cancellation](#request-cancellation)
  - [Error Handling](#error-handling)
  - [Token Auto Refresh](#token-auto-refresh)
  - [API Signing](#api-signing)
- [Logging and Debugging](#logging-and-debugging)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Changelog](#changelog)

## Introduction

`FKNetwork` is the native networking module under `FKCoreKit`. It is built on top of system `URLSession`, follows protocol-oriented design, and has zero third-party dependencies.

It is designed for medium and large iOS projects with a focus on:

- Maintainability: clear layering and single responsibility
- Testability: protocol-first architecture and dependency injection
- Extensibility: interceptors, signing, caching, token refresh, and custom hooks
- Practicality: both Closure and async/await APIs

---

## Features

- Pure native implementation using Foundation / Network / URLSession
- Protocol-based core abstractions: `Requestable`, `Networkable`, `Cacheable`, `RequestSigner`, `TokenRefresher`
- Multi-environment configuration: development / testing / production
- Full HTTP method support: `GET/POST/PUT/PATCH/DELETE/HEAD/OPTIONS`
- Parameter encoding: `query`, `json`, `formURLEncoded`
- Business enhancements: request deduplication, token auto-refresh retry, MD5 signing, parameter encryption hook
- Two-level cache: memory + disk with TTL policies
- File capabilities: upload / download with progress, resumable download support
- Debug support: logging, reachability integration, mock data
- Unified error model: `NetworkError`

---

## Architecture

Module layout (`Sources/FKCoreKit/Network`):

- `Core`: protocols, network client, request/response pipeline, upload/download
- `Config`: global runtime configuration and environments
- `Model`: HTTP definitions, cache policies, endpoint and error models
- `Tool`: cache, logger, deduplicator, reachability, service helpers
- `Extension`: utility extensions (for example MD5)
- `Examples`: ready-to-use sample code

Request flow:

1. Define a request conforming to `Requestable`
2. `FKNetworkClient` builds `URLRequest` (base URL, query, headers, body)
3. Apply request interceptors and request signer
4. Execute via `URLSession`
5. Apply response interceptors and validate status code
6. Auto refresh token and retry once on `401` (if configured)
7. Decode response and callback (main queue by default)

---

## Supported Features

- Global environment switching and runtime config
- Unified request building and shared parameter injection
- Closure + async/await dual API
- Request cancellation via `Cancellable`
- Request deduplication with `idempotentDeduplicated`
- Cache policies: `.none`, `.memory`, `.disk`, `.memoryAndDisk`
- Unified error handling with `NetworkError`
- Token auto-refresh and transparent retry
- API signing with `MD5RequestSigner`
- Upload/download with progress and resume data support
- Basic SSL challenge handling with host strategy hook
- Mock response data and debug logging

---

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 15+

> The current repository package platform is set to iOS 15+ in `Package.swift`, while `FKNetwork` code is written with iOS 13+ compatibility in mind.
>
> In short: runtime APIs are designed for iOS 13+, but this repository currently declares iOS 15+ as the package platform.

---

## Installation & Integration

### Swift Package Manager

After integrating `FKKit`, import:

```swift
import FKCoreKit
```

### Local Source Integration

`FKNetwork` source is located at:

`Sources/FKCoreKit/Network`

No third-party library is required.

---

## Quick Start (Basic Usage)

### 1) Configure environments and create client

```swift
import Foundation
import FKCoreKit

let config = FKNetworkConfiguration.shared
config.environmentMap = [
  .development: .init(
    baseURL: URL(string: "https://dev-api.example.com")!,
    timeout: 20,
    defaultHeaders: ["Accept": "application/json"]
  ),
  .testing: .init(baseURL: URL(string: "https://test-api.example.com")!),
  .production: .init(baseURL: URL(string: "https://api.example.com")!)
]
config.environment = .development
config.commonQueryItems = ["platform": "iOS", "appVersion": "1.0.0"]

let network = FKNetworkClient(config: config)
```

### 2) Define request model

```swift
import FKCoreKit

struct UserDTO: Codable, Sendable {
  let id: Int
  let name: String
}

struct UserDetailRequest: Requestable {
  typealias Response = UserDTO

  let userID: Int
  var path: String { "/v1/user/profile" }
  var method: HTTPMethod { .get }
  var queryItems: [String: String] { ["id": "\(userID)"] }
  var cachePolicy: NetworkCachePolicy { .memoryAndDisk(ttl: 60) }
}
```

### 3) Send request (Closure)

```swift
let task = network.send(UserDetailRequest(userID: 1001)) { result in
  switch result {
  case let .success(user):
    print("user:", user)
  case let .failure(error):
    print("error:", error.localizedDescription)
  }
}

// Cancel if needed
task.cancel()
```

---

## Detailed Usage Guide

### Global Configuration

```swift
let config = FKNetworkConfiguration.shared
config.environment = .production
config.commonQueryItems = ["device": "iPhone"]
config.callbackOnMainQueue = true
config.enableMock = false
```

### GET Request

```swift
struct ProductListRequest: Requestable {
  typealias Response = [String]

  var path: String { "/v1/product/list" }
  var method: HTTPMethod { .get }
  var queryItems: [String: String] { ["page": "1", "size": "20"] }
  var encoding: ParameterEncoding { .query }
}

network.send(ProductListRequest()) { print($0) }
```

### POST Request

```swift
struct UpdateNameRequest: Requestable {
  struct ResponseModel: Codable, Sendable {
    let success: Bool
  }
  typealias Response = ResponseModel

  let userID: Int
  let name: String

  var path: String { "/v1/user/update" }
  var method: HTTPMethod { .post }
  var encoding: ParameterEncoding { .json }
  var bodyParameters: [String: Any] {
    ["id": userID, "name": name]
  }
}
```

### async/await

```swift
@available(iOS 13.0, *)
func loadUser() async {
  do {
    let user = try await network.send(UserDetailRequest(userID: 1001))
    print(user)
  } catch {
    print(error)
  }
}
```

### File Upload

```swift
var request = URLRequest(url: URL(string: "https://api.example.com/v1/file/upload")!)
request.httpMethod = "POST"

let uploadTask = network.upload(request, fileURL: localFileURL, progress: { p in
  print("upload progress:", p)
}) { result in
  print(result)
}

// uploadTask.cancel()
```

### File Download

```swift
var request = URLRequest(url: URL(string: "https://api.example.com/v1/file/download")!)
request.httpMethod = "GET"

let downloadTask = network.download(request, resumeData: nil, progress: { p in
  print("download progress:", p)
}) { result in
  switch result {
  case let .success((fileURL, resumeData)):
    print("temp file:", fileURL, "resume:", resumeData as Any)
  case let .failure(error):
    print(error)
  }
}
```

### Cache Policy

```swift
struct CachedRequest: Requestable {
  typealias Response = UserDTO
  var path: String { "/v1/user/profile" }
  var method: HTTPMethod { .get }
  var cachePolicy: NetworkCachePolicy { .memoryAndDisk(ttl: 120) }
}
```

Available policies:

- `.none`
- `.memory(ttl:)`
- `.disk(ttl:)`
- `.memoryAndDisk(ttl:)`

### Request Cancellation

```swift
let task = network.send(UserDetailRequest(userID: 1001)) { _ in }
task.cancel()
```

### Error Handling

`FKNetwork` uses unified `NetworkError` values, including:

- `invalidURL`
- `invalidResponse`
- `requestCancelled`
- `noData`
- `decodingFailed`
- `serverError(statusCode:message:)`
- `businessError(code:message:)`
- `offline`
- `tokenRefreshFailed`

Example:

```swift
network.send(UserDetailRequest(userID: 1001)) { result in
  if case let .failure(error) = result {
    switch error {
    case .offline:
      print("No network connection")
    case let .serverError(code, message):
      print("Server error:", code, message ?? "")
    default:
      print(error.localizedDescription)
    }
  }
}
```

### Token Auto Refresh

Implement `TokenStore` and `TokenRefresher`, then inject them:

```swift
final class AppTokenStore: TokenStore {
  var accessToken: String?
  var refreshToken: String?
}

struct AppTokenRefresher: TokenRefresher {
  func refreshToken(
    using currentRefreshToken: String?,
    completion: @escaping (Result<String, NetworkError>) -> Void
  ) {
    // Call refresh API and return new token
    completion(.success("new_access_token"))
  }
}

let store = AppTokenStore()
let config = FKNetworkConfiguration.shared
config.tokenStore = store
config.tokenRefresher = AppTokenRefresher()
config.requestInterceptors = [AuthHeaderInterceptor(tokenStore: store)]
```

When a response status is `401`, `FKNetworkClient` automatically triggers refresh and retries once.

### API Signing

Use built-in `MD5RequestSigner`:

```swift
let config = FKNetworkConfiguration.shared
config.signer = MD5RequestSigner(secret: "your-secret")
```

Default headers injected by signer:

- `X-Timestamp`
- `X-Signature`

---

## Logging and Debugging

- Default logger: `FKDefaultNetworkLogger` (outputs in Debug builds)
- Reachability provider: `FKNetworkReachability` (inject into `networkStatusProvider`)
- Mock mode: set `enableMock = true` and return `mockData` from request

```swift
struct MockUserRequest: Requestable {
  typealias Response = UserDTO
  var path: String { "/mock/user" }
  var method: HTTPMethod { .get }
  var mockData: Data? { #"{"id":1,"name":"MockUser"}"#.data(using: .utf8) }
}
```

---

## Best Practices

- Group APIs by business domain with `Requestable` types
- Add a service layer on top of `Networkable` (`NetworkServiceProvidable`)
- Use cache TTL intentionally for list/detail endpoints
- Enable deduplication for idempotent requests
- Centralize auth/signing/logging in global config
- Handle errors by `NetworkError` cases instead of string matching

---

## Notes

- `callbackOnMainQueue` defaults to `true`; if disabled, switch to main thread before UI updates
- Download `fileURL` is a temporary file path; move it to your desired location
- Resume download requires persisting `resumeData`
- `encryptParameters` is an extension hook; ensure backend compatibility
- SSL handling is basic challenge handling; extend it for strict certificate pinning if needed

---

## Roadmap

- Add stricter SSL pinning examples
- Add multipart upload helper utilities
- Add unit test fixtures and mock session templates
- Add more production-ready retry policy presets

---

## Contributing

Contributions are welcome. Please open an issue first for feature proposals or significant changes.

Recommended steps:

1. Fork the repository and create a feature branch
2. Keep changes focused and well-documented
3. Add or update tests/examples where appropriate
4. Open a pull request with clear context and test notes

---

## License

This project is released under the MIT License. See the root `LICENSE` file for details.

---

## Changelog

### 0.1.0

- Initial release of `FKNetwork`
- URLSession-based protocol-oriented networking core
- Closure + async/await dual API
- Environment config, interceptors, MD5 signing, token refresh retry
- Two-level cache, request deduplication, upload/download with progress
- Unified error model, reachability support, mock support

