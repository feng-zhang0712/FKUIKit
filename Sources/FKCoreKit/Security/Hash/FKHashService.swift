import Foundation
import CommonCrypto

/// Default hashing implementation based on Apple-provided CommonCrypto.
public final class FKHashService: FKHashing, @unchecked Sendable {
  private let executor: FKSecurityExecuting
  private let coder: FKSecurityCoding

  public init(executor: FKSecurityExecuting, coder: FKSecurityCoding) {
    self.executor = executor
    self.coder = coder
  }

  public func hashString(_ string: String, algorithm: FKHashAlgorithm) async throws -> String {
    guard let data = string.data(using: .utf8) else {
      throw FKSecurityError.invalidInput("String cannot be encoded as UTF-8.")
    }
    return try await hashData(data, algorithm: algorithm)
  }

  public func hashData(_ data: Data, algorithm: FKHashAlgorithm) async throws -> String {
    try await executor.run {
      let digest = Self.digest(data: data, algorithm: algorithm)
      return self.coder.hexString(from: digest, uppercase: false)
    }
  }

  public func hashFile(at url: URL, algorithm: FKHashAlgorithm) async throws -> String {
    try await executor.run {
      let handle: FileHandle
      do {
        handle = try FileHandle(forReadingFrom: url)
      } catch {
        throw FKSecurityError.fileFailed("Cannot open file for hashing: \(url.path)")
      }
      defer { try? handle.close() }

      let bufferSize = 1024 * 1024
      var context = Self.makeContext(for: algorithm)

      while true {
        let chunk = handle.readData(ofLength: bufferSize)
        if chunk.isEmpty { break }
        Self.updateContext(&context, with: chunk, algorithm: algorithm)
      }

      let digest = Self.finalizeContext(&context, algorithm: algorithm)
      return self.coder.hexString(from: digest, uppercase: false)
    }
  }

  public func hashString(
    _ string: String,
    algorithm: FKHashAlgorithm,
    completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void
  ) {
    Task {
      do {
        completion(.success(try await hashString(string, algorithm: algorithm)))
      } catch let error as FKSecurityError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  public func hashData(
    _ data: Data,
    algorithm: FKHashAlgorithm,
    completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void
  ) {
    Task {
      do {
        completion(.success(try await hashData(data, algorithm: algorithm)))
      } catch let error as FKSecurityError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  public func hashFile(
    at url: URL,
    algorithm: FKHashAlgorithm,
    completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void
  ) {
    Task {
      do {
        completion(.success(try await hashFile(at: url, algorithm: algorithm)))
      } catch let error as FKSecurityError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }
}

// MARK: - CommonCrypto low-level helpers

extension FKHashService {
  private enum DigestContext {
    case md5(CC_MD5_CTX)
    case sha1(CC_SHA1_CTX)
    case sha256(CC_SHA256_CTX)
    case sha512(CC_SHA512_CTX)
  }

  private static func digest(data: Data, algorithm: FKHashAlgorithm) -> Data {
    var context = makeContext(for: algorithm)
    updateContext(&context, with: data, algorithm: algorithm)
    return finalizeContext(&context, algorithm: algorithm)
  }

  private static func makeContext(for algorithm: FKHashAlgorithm) -> DigestContext {
    switch algorithm {
    case .md5:
      var ctx = CC_MD5_CTX()
      CC_MD5_Init(&ctx)
      return .md5(ctx)
    case .sha1:
      var ctx = CC_SHA1_CTX()
      CC_SHA1_Init(&ctx)
      return .sha1(ctx)
    case .sha256:
      var ctx = CC_SHA256_CTX()
      CC_SHA256_Init(&ctx)
      return .sha256(ctx)
    case .sha512:
      var ctx = CC_SHA512_CTX()
      CC_SHA512_Init(&ctx)
      return .sha512(ctx)
    }
  }

  private static func updateContext(_ context: inout DigestContext, with data: Data, algorithm: FKHashAlgorithm) {
    data.withUnsafeBytes { rawBuffer in
      guard let base = rawBuffer.baseAddress else { return }
      let length = CC_LONG(data.count)
      switch context {
      case var .md5(ctx):
        CC_MD5_Update(&ctx, base, length)
        context = .md5(ctx)
      case var .sha1(ctx):
        CC_SHA1_Update(&ctx, base, length)
        context = .sha1(ctx)
      case var .sha256(ctx):
        CC_SHA256_Update(&ctx, base, length)
        context = .sha256(ctx)
      case var .sha512(ctx):
        CC_SHA512_Update(&ctx, base, length)
        context = .sha512(ctx)
      }
    }
  }

  private static func finalizeContext(_ context: inout DigestContext, algorithm: FKHashAlgorithm) -> Data {
    switch context {
    case var .md5(ctx):
      var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
      CC_MD5_Final(&digest, &ctx)
      return Data(digest)
    case var .sha1(ctx):
      var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
      CC_SHA1_Final(&digest, &ctx)
      return Data(digest)
    case var .sha256(ctx):
      var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
      CC_SHA256_Final(&digest, &ctx)
      return Data(digest)
    case var .sha512(ctx):
      var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
      CC_SHA512_Final(&digest, &ctx)
      return Data(digest)
    }
  }
}

