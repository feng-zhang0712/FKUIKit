import Foundation

/// Fetches the latest App Store version using Apple's iTunes Lookup API.
///
/// - Important: This provider only works for apps published on the App Store.
public final class FKAppStoreRemoteVersionProvider: FKRemoteVersionProviding, @unchecked Sendable {
  /// Target application bundle identifier.
  private let bundleID: String
  /// Optional store country code.
  private let countryCode: String?
  /// URL session used for network requests.
  private let session: URLSession
  /// Whether returned metadata should mark update as mandatory.
  private let isForceUpdate: Bool

  /// Creates a provider.
  ///
  /// - Parameters:
  ///   - bundleID: Target app bundle identifier.
  ///   - countryCode: Optional App Store country code (for example `us`, `cn`).
  ///   - session: URLSession used for requests.
  ///   - isForceUpdate: When `true`, returns `FKRemoteVersionInfo(isForceUpdate: true)` regardless of version delta.
  public init(
    bundleID: String,
    countryCode: String? = nil,
    session: URLSession = .shared,
    isForceUpdate: Bool = false
  ) {
    self.bundleID = bundleID
    self.countryCode = countryCode
    self.session = session
    self.isForceUpdate = isForceUpdate
  }

  @available(iOS 13.0, *)
  public func fetchRemoteVersion() async throws -> FKRemoteVersionInfo {
    // Build iTunes Lookup URL for the target bundle identifier.
    guard var components = URLComponents(string: "https://itunes.apple.com/lookup") else {
      throw FKBusinessError.invalidArgument("Invalid iTunes lookup base URL.")
    }

    var items: [URLQueryItem] = [URLQueryItem(name: "bundleId", value: bundleID)]
    if let countryCode, !countryCode.isEmpty {
      items.append(URLQueryItem(name: "country", value: countryCode))
    }
    components.queryItems = items

    guard let url = components.url else {
      throw FKBusinessError.invalidArgument("Failed to build lookup URL.")
    }

    // Validate HTTP response before decoding payload.
    let (data, response) = try await session.data(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw FKBusinessError.networkFailed(underlying: "Non-200 response.")
    }

    // Decode first matching app item as remote version source.
    let decoded = try JSONDecoder().decode(LookupResponse.self, from: data)
    guard let first = decoded.results.first, let version = first.version else {
      throw FKBusinessError.networkFailed(underlying: "No App Store version found for bundleId.")
    }

    let updateURL = URL(string: first.trackViewUrl ?? "")
    return FKRemoteVersionInfo(
      version: version,
      build: nil,
      releaseNotes: first.releaseNotes,
      updateURL: updateURL,
      isForceUpdate: isForceUpdate
    )
  }

  /// Decodable payload root returned by iTunes Lookup API.
  private struct LookupResponse: Decodable {
    /// Lookup result list.
    let results: [LookupResult]
  }

  /// Decodable app item fields used by FKBusinessKit.
  private struct LookupResult: Decodable {
    /// App Store marketing version string.
    let version: String?
    /// Optional release notes text.
    let releaseNotes: String?
    /// Optional App Store product URL.
    let trackViewUrl: String?
  }
}

