//
// FKCarouselImageLoader.swift
//

import UIKit

/// Lightweight image loader built with `URLSession` and memory cache.
///
/// The loader is intentionally simple and optimized for carousel scenarios where fast
/// repeated reads of a small image set are common.
final class FKCarouselImageLoader: @unchecked Sendable {
  /// Shared singleton instance.
  static let shared = FKCarouselImageLoader()

  /// In-memory image cache keyed by URL.
  private let cache = NSCache<NSURL, UIImage>()
  /// Running tasks dictionary keyed by cancel token.
  private var tasks: [UUID: URLSessionDataTask] = [:]
  /// Lock protecting access to `tasks`.
  private let lock = NSLock()
  /// Internal session configured with system URL cache.
  private lazy var session: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.requestCachePolicy = .returnCacheDataElseLoad
    configuration.timeoutIntervalForRequest = 20
    configuration.urlCache = URLCache.shared
    return URLSession(configuration: configuration)
  }()

  /// Creates the loader and sets cache limits.
  private init() {
    cache.countLimit = 300
  }

  /// Loads image from remote URL.
  ///
  /// - Parameters:
  ///   - url: Remote URL.
  ///   - completion: Main-actor callback used to deliver decoded image.
  /// - Returns: Cancel token for request.
  @discardableResult
  func loadImage(url: URL, completion: @escaping @MainActor (UIImage?) -> Void) -> UUID? {
    // Return cached image immediately to avoid unnecessary network and decode work.
    if let cached = cache.object(forKey: url as NSURL) {
      Task { @MainActor in
        completion(cached)
      }
      return nil
    }

    let id = UUID()
    let task = session.dataTask(with: url) { [weak self] data, response, _ in
      defer { self?.removeTask(for: id) }

      let image: UIImage?
      // Only accept successful HTTP responses with decodable image payload.
      if
        let response = response as? HTTPURLResponse,
        200 ... 299 ~= response.statusCode,
        let data,
        let decoded = UIImage(data: data)
      {
        self?.cache.setObject(decoded, forKey: url as NSURL)
        image = decoded
      } else {
        image = nil
      }

      Task { @MainActor in
        completion(image)
      }
    }

    lock.lock()
    tasks[id] = task
    lock.unlock()
    task.resume()
    return id
  }

  /// Cancels running request.
  ///
  /// - Parameter token: Token returned by `loadImage(url:completion:)`.
  func cancel(_ token: UUID?) {
    guard let token else { return }
    lock.lock()
    let task = tasks[token]
    tasks[token] = nil
    lock.unlock()
    task?.cancel()
  }

  /// Removes completed or cancelled task bookkeeping.
  ///
  /// - Parameter id: Internal request token.
  private func removeTask(for id: UUID) {
    lock.lock()
    tasks[id] = nil
    lock.unlock()
  }
}
