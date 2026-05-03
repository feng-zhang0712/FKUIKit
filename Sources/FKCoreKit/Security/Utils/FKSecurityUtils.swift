import Foundation
import Security
import Darwin

/// Default utilities implementation for FKSecurity.
public final class FKSecurityUtils: FKSecurityUtilizing, @unchecked Sendable {
  private let executor: FKSecurityExecuting
  private let hasher: FKHashing

  public init(executor: FKSecurityExecuting, hasher: FKHashing) {
    self.executor = executor
    self.hasher = hasher
  }

  public func randomBytes(count: Int) async throws -> Data {
    try await executor.run {
      guard count > 0 else { throw FKSecurityError.invalidInput("Random byte count must be > 0.") }
      var data = Data(count: count)
      let status = data.withUnsafeMutableBytes { buf in
        SecRandomCopyBytes(kSecRandomDefault, count, buf.baseAddress!)
      }
      guard status == errSecSuccess else {
        throw FKSecurityError.securityFailed(status: status, message: "SecRandomCopyBytes failed.")
      }
      return data
    }
  }

  public func randomString(length: Int, alphabet: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") async throws -> String {
    let bytes = try await randomBytes(count: length)
    let chars = Array(alphabet)
    guard !chars.isEmpty else { throw FKSecurityError.invalidInput("Alphabet must not be empty.") }
    var out = String()
    out.reserveCapacity(length)
    for b in bytes {
      out.append(chars[Int(b) % chars.count])
    }
    return out
  }

  public func maskPhone(_ value: String) -> String {
    let digits = value.filter(\.isNumber)
    guard digits.count >= 7 else { return value }
    let start = digits.prefix(3)
    let end = digits.suffix(4)
    return "\(start)****\(end)"
  }

  public func maskIDCard(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 8 else { return value }
    let start = trimmed.prefix(3)
    let end = trimmed.suffix(3)
    return "\(start)\(String(repeating: "*", count: max(0, trimmed.count - 6)))\(end)"
  }

  public func maskEmail(_ value: String) -> String {
    let parts = value.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count == 2 else { return value }
    let name = String(parts[0])
    let domain = String(parts[1])
    guard !name.isEmpty else { return value }
    let maskedName: String
    if name.count <= 2 {
      maskedName = String(name.prefix(1)) + "*"
    } else {
      maskedName =
        String(name.prefix(1)) + String(repeating: "*", count: name.count - 2) + String(name.suffix(1))
    }
    return "\(maskedName)@\(domain)"
  }

  public func isDebuggerAttached() -> Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let sysctlResult = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
    guard sysctlResult == 0 else { return false }
    return (info.kp_proc.p_flag & P_TRACED) != 0
  }

  public func hasSuspiciousEnvironment() -> Bool {
    let env = ProcessInfo.processInfo.environment
    if env.keys.contains(where: { $0.hasPrefix("DYLD_") }) { return true }
    if env["SIMULATOR_DEVICE_NAME"] != nil { return true }
    return false
  }

  public func snapshotExecutableHash(algorithm: FKHashAlgorithm) async throws -> String {
    guard let url = Bundle.main.executableURL else {
      throw FKSecurityError.unavailable("Bundle.main.executableURL is nil.")
    }
    return try await hasher.hashFile(at: url, algorithm: algorithm)
  }

  public func verifyExecutableHashSnapshot(_ expected: String, algorithm: FKHashAlgorithm) async throws -> Bool {
    let current = try await snapshotExecutableHash(algorithm: algorithm)
    return current.caseInsensitiveCompare(expected) == .orderedSame
  }

  public func secureWipe(_ data: inout Data) {
    data.withUnsafeMutableBytes { buf in
      guard let base = buf.baseAddress else { return }
      memset(base, 0, buf.count)
    }
    data.removeAll(keepingCapacity: false)
  }

  public func secureWipeFile(at url: URL, passes: Int = 1) async throws {
    try await executor.run {
      guard passes >= 1 else { throw FKSecurityError.invalidInput("passes must be >= 1.") }
      let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
      let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
      guard size > 0 else {
        try FileManager.default.removeItem(at: url)
        return
      }

      let handle = try FileHandle(forWritingTo: url)
      defer { try? handle.close() }

      for _ in 0..<passes {
        try handle.seek(toOffset: 0)
        var remaining = size
        let chunk = 1024 * 1024
        while remaining > 0 {
          let writeCount = min(chunk, remaining)
          var random = Data(count: writeCount)
          let status = random.withUnsafeMutableBytes { buf in
            SecRandomCopyBytes(kSecRandomDefault, writeCount, buf.baseAddress!)
          }
          guard status == errSecSuccess else {
            throw FKSecurityError.securityFailed(status: status, message: "SecRandomCopyBytes failed.")
          }
          handle.write(random)
          remaining -= writeCount
        }
        try handle.synchronize()
      }

      try FileManager.default.removeItem(at: url)
    }
  }
}

