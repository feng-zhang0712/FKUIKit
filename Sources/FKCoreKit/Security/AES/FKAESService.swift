import Foundation
import Security
import CommonCrypto

/// Default AES implementation using CommonCrypto.
public final class FKAESService: FKAESCrypting, @unchecked Sendable {
  private let executor: FKSecurityExecuting

  public init(executor: FKSecurityExecuting) {
    self.executor = executor
  }

  public func generateKey(length: Int = kCCKeySizeAES256) async throws -> Data {
    try await executor.run {
      guard [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256].contains(length) else {
        throw FKSecurityError.invalidKey("AES key length must be 16/24/32 bytes.")
      }
      var data = Data(count: length)
      let status = data.withUnsafeMutableBytes { buf in
        SecRandomCopyBytes(kSecRandomDefault, length, buf.baseAddress!)
      }
      guard status == errSecSuccess else {
        throw FKSecurityError.securityFailed(status: status, message: "SecRandomCopyBytes failed.")
      }
      return data
    }
  }

  public func generateIV() async throws -> Data {
    try await executor.run {
      let length = kCCBlockSizeAES128
      var data = Data(count: length)
      let status = data.withUnsafeMutableBytes { buf in
        SecRandomCopyBytes(kSecRandomDefault, length, buf.baseAddress!)
      }
      guard status == errSecSuccess else {
        throw FKSecurityError.securityFailed(status: status, message: "SecRandomCopyBytes failed.")
      }
      return data
    }
  }

  public func encrypt(_ data: Data, using key: Data, iv: Data?, mode: FKAESMode) async throws -> Data {
    try await crypt(data, operation: CCOperation(kCCEncrypt), key: key, iv: iv, mode: mode)
  }

  public func decrypt(_ data: Data, using key: Data, iv: Data?, mode: FKAESMode) async throws -> Data {
    try await crypt(data, operation: CCOperation(kCCDecrypt), key: key, iv: iv, mode: mode)
  }

  public func encryptString(_ string: String, using key: Data, iv: Data?, mode: FKAESMode) async throws -> String {
    guard let data = string.data(using: .utf8) else {
      throw FKSecurityError.invalidInput("String cannot be encoded as UTF-8.")
    }
    let encrypted = try await encrypt(data, using: key, iv: iv, mode: mode)
    return encrypted.base64EncodedString()
  }

  public func decryptString(_ base64Ciphertext: String, using key: Data, iv: Data?, mode: FKAESMode) async throws -> String {
    guard let data = Data(base64Encoded: base64Ciphertext) else {
      throw FKSecurityError.invalidInput("Ciphertext is not valid Base64.")
    }
    let decrypted = try await decrypt(data, using: key, iv: iv, mode: mode)
    guard let string = String(data: decrypted, encoding: .utf8) else {
      throw FKSecurityError.invalidInput("Decrypted data is not valid UTF-8.")
    }
    return string
  }

  public func encryptFile(
    at inputURL: URL,
    to outputURL: URL,
    using key: Data,
    iv: Data?,
    mode: FKAESMode
  ) async throws {
    try await cryptFile(at: inputURL, to: outputURL, operation: CCOperation(kCCEncrypt), key: key, iv: iv, mode: mode)
  }

  public func decryptFile(
    at inputURL: URL,
    to outputURL: URL,
    using key: Data,
    iv: Data?,
    mode: FKAESMode
  ) async throws {
    try await cryptFile(at: inputURL, to: outputURL, operation: CCOperation(kCCDecrypt), key: key, iv: iv, mode: mode)
  }
}

// MARK: - Core

extension FKAESService {
  private func validate(key: Data, iv: Data?, mode: FKAESMode) throws {
    guard [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256].contains(key.count) else {
      throw FKSecurityError.invalidKey("AES key length must be 16/24/32 bytes.")
    }
    switch mode {
    case .cbc:
      guard let iv, iv.count == kCCBlockSizeAES128 else {
        throw FKSecurityError.invalidKey("AES-CBC requires a 16-byte IV.")
      }
    case .ecb:
      break
    }
  }

  private func crypt(
    _ input: Data,
    operation: CCOperation,
    key: Data,
    iv: Data?,
    mode: FKAESMode
  ) async throws -> Data {
    try await executor.run {
      try self.validate(key: key, iv: iv, mode: mode)

      let options = Self.ccOptions(for: mode)
      var outLength = 0
      var out = Data(count: input.count + kCCBlockSizeAES128)
      let outCapacity = out.count

      let status = out.withUnsafeMutableBytes { outBuf in
        input.withUnsafeBytes { inBuf in
          key.withUnsafeBytes { keyBuf in
            let ivBytes: UnsafeRawPointer? = (mode == .cbc) ? (iv! as NSData).bytes : nil
            return CCCrypt(
              operation,
              CCAlgorithm(kCCAlgorithmAES),
              options,
              keyBuf.baseAddress!,
              key.count,
              ivBytes,
              inBuf.baseAddress!,
              input.count,
              outBuf.baseAddress!,
              outCapacity,
              &outLength
            )
          }
        }
      }

      guard status == kCCSuccess else {
        throw FKSecurityError.cryptoFailed(status: status, message: "CCCrypt failed.")
      }

      out.removeSubrange(outLength..<out.count)
      return out
    }
  }

  private func cryptFile(
    at inputURL: URL,
    to outputURL: URL,
    operation: CCOperation,
    key: Data,
    iv: Data?,
    mode: FKAESMode
  ) async throws {
    try await executor.run {
      try self.validate(key: key, iv: iv, mode: mode)

      let inHandle: FileHandle
      do {
        inHandle = try FileHandle(forReadingFrom: inputURL)
      } catch {
        throw FKSecurityError.fileFailed("Cannot open input file: \(inputURL.path)")
      }
      defer { try? inHandle.close() }

      FileManager.default.createFile(atPath: outputURL.path, contents: nil)
      let outHandle: FileHandle
      do {
        outHandle = try FileHandle(forWritingTo: outputURL)
      } catch {
        throw FKSecurityError.fileFailed("Cannot open output file: \(outputURL.path)")
      }
      defer { try? outHandle.close() }

      var cryptor: CCCryptorRef?
      let options = Self.ccOptions(for: mode)
      let ivBytes: UnsafeRawPointer? = (mode == .cbc) ? (iv! as NSData).bytes : nil

      let createStatus = key.withUnsafeBytes { keyBuf in
        CCCryptorCreate(
          operation,
          CCAlgorithm(kCCAlgorithmAES),
          options,
          keyBuf.baseAddress!,
          key.count,
          ivBytes,
          &cryptor
        )
      }
      guard createStatus == kCCSuccess, let cryptor else {
        throw FKSecurityError.cryptoFailed(status: createStatus, message: "CCCryptorCreate failed.")
      }
      defer { CCCryptorRelease(cryptor) }

      let chunkSize = 1024 * 1024
      while true {
        let chunk = inHandle.readData(ofLength: chunkSize)
        if chunk.isEmpty { break }

        var outData = Data(count: CCCryptorGetOutputLength(cryptor, chunk.count, false))
        let outCapacity = outData.count
        var moved: size_t = 0
        let status = outData.withUnsafeMutableBytes { outBuf in
          chunk.withUnsafeBytes { inBuf in
            CCCryptorUpdate(cryptor, inBuf.baseAddress!, chunk.count, outBuf.baseAddress!, outCapacity, &moved)
          }
        }
        guard status == kCCSuccess else {
          throw FKSecurityError.cryptoFailed(status: status, message: "CCCryptorUpdate failed.")
        }
        outData.removeSubrange(Int(moved)..<outData.count)
        if !outData.isEmpty {
          outHandle.write(outData)
        }
      }

      var finalData = Data(count: CCCryptorGetOutputLength(cryptor, 0, true))
      let finalCapacity = finalData.count
      var finalMoved: size_t = 0
      let finalStatus = finalData.withUnsafeMutableBytes { outBuf in
        CCCryptorFinal(cryptor, outBuf.baseAddress!, finalCapacity, &finalMoved)
      }
      guard finalStatus == kCCSuccess else {
        throw FKSecurityError.cryptoFailed(status: finalStatus, message: "CCCryptorFinal failed.")
      }
      finalData.removeSubrange(Int(finalMoved)..<finalData.count)
      if !finalData.isEmpty {
        outHandle.write(finalData)
      }
    }
  }

  private static func ccOptions(for mode: FKAESMode) -> CCOptions {
    switch mode {
    case .cbc:
      return CCOptions(kCCOptionPKCS7Padding)
    case .ecb:
      return CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode)
    }
  }
}

