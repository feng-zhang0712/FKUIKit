import Foundation
import CommonCrypto

/// Default HMAC and parameter signing implementation.
public final class FKSignatureService: FKSecuritySigning, @unchecked Sendable {
  private let executor: FKSecurityExecuting
  private let coder: FKSecurityCoding

  public init(executor: FKSecurityExecuting, coder: FKSecurityCoding) {
    self.executor = executor
    self.coder = coder
  }

  public func hmac(_ data: Data, key: Data, algorithm: FKHMACAlgorithm) async throws -> Data {
    try await executor.run {
      var out = [UInt8](repeating: 0, count: Self.digestLength(algorithm))
      data.withUnsafeBytes { dataBuf in
        key.withUnsafeBytes { keyBuf in
          CCHmac(
            Self.ccAlgorithm(algorithm),
            keyBuf.baseAddress!,
            key.count,
            dataBuf.baseAddress!,
            data.count,
            &out
          )
        }
      }
      return Data(out)
    }
  }

  public func hmacHex(_ data: Data, key: Data, algorithm: FKHMACAlgorithm) async throws -> String {
    let mac = try await hmac(data, key: key, algorithm: algorithm)
    return coder.hexString(from: mac, uppercase: false)
  }

  public func signParameters(
    _ parameters: [String: Any],
    secret: String,
    algorithm: FKHMACAlgorithm
  ) async throws -> String {
    let canonical = canonicalQuery(parameters)
    guard let data = canonical.data(using: .utf8), let key = secret.data(using: .utf8) else {
      throw FKSecurityError.invalidInput("Parameters or secret cannot be encoded as UTF-8.")
    }
    return try await hmacHex(data, key: key, algorithm: algorithm)
  }

  public func verifyParameters(
    _ parameters: [String: Any],
    secret: String,
    signatureHex: String,
    algorithm: FKHMACAlgorithm
  ) async throws -> Bool {
    let computed = try await signParameters(parameters, secret: secret, algorithm: algorithm)
    return computed.caseInsensitiveCompare(signatureHex) == .orderedSame
  }
}

extension FKSignatureService {
  private func canonicalQuery(_ parameters: [String: Any]) -> String {
    let pairs: [(String, String)] = parameters.map { key, value in
      (key, Self.stringValue(value))
    }.sorted { $0.0 < $1.0 }

    return pairs
      .map { "\(escape($0.0))=\(escape($0.1))" }
      .joined(separator: "&")
  }

  private func escape(_ string: String) -> String {
    let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
  }

  private static func stringValue(_ value: Any) -> String {
    if let v = value as? String { return v }
    if let v = value as? CustomStringConvertible { return v.description }
    if JSONSerialization.isValidJSONObject(value),
       let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
       let s = String(data: data, encoding: .utf8) {
      return s
    }
    return "\(value)"
  }

  private static func ccAlgorithm(_ algorithm: FKHMACAlgorithm) -> CCHmacAlgorithm {
    switch algorithm {
    case .sha256: return CCHmacAlgorithm(kCCHmacAlgSHA256)
    case .sha512: return CCHmacAlgorithm(kCCHmacAlgSHA512)
    }
  }

  private static func digestLength(_ algorithm: FKHMACAlgorithm) -> Int {
    switch algorithm {
    case .sha256: return Int(CC_SHA256_DIGEST_LENGTH)
    case .sha512: return Int(CC_SHA512_DIGEST_LENGTH)
    }
  }
}

