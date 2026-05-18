import Foundation

/// FairPlay streaming configuration carried on ``FKMediaItem/metadata`` or injected via DRM plugin.
public struct FKMediaFairPlayConfiguration: Sendable, Equatable {
  public var certificateURL: URL
  public var licenseURL: URL
  public var headers: [String: String]

  public init(
    certificateURL: URL,
    licenseURL: URL,
    headers: [String: String] = [:]
  ) {
    self.certificateURL = certificateURL
    self.licenseURL = licenseURL
    self.headers = headers
  }

  public enum MetadataKey {
    public static let certificateURL = "fk.fairplay.certificate"
    public static let licenseURL = "fk.fairplay.license"
  }
}

extension FKMediaItem {

  public var fairPlayConfiguration: FKMediaFairPlayConfiguration? {
    guard
      let cert = metadata[FKMediaFairPlayConfiguration.MetadataKey.certificateURL].flatMap(URL.init(string:)),
      let license = metadata[FKMediaFairPlayConfiguration.MetadataKey.licenseURL].flatMap(URL.init(string:))
    else { return nil }
    return FKMediaFairPlayConfiguration(certificateURL: cert, licenseURL: license)
  }
}
