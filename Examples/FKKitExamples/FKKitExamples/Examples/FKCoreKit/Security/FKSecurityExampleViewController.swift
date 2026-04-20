import FKCoreKit
import Security
import UIKit

/// Interactive and copy-ready demo for FKSecurity.
/// Each button maps to a practical, production-aligned usage scenario.
final class FKSecurityExampleViewController: UIViewController {
  // MARK: - UI

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let outputView = UITextView()

  // MARK: - State

  private let security = FKSecurity.shared

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSecurity"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendOutput("FKSecurity example loaded.")
  }

  // MARK: - Layout

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8

    outputView.translatesAutoresizingMaskIntoConstraints = false
    outputView.isEditable = false
    outputView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    outputView.backgroundColor = .secondarySystemBackground
    outputView.layer.cornerRadius = 8

    let actions: [(String, Selector)] = [
      ("1) Hash (String/Data/File) - MD5/SHA256/SHA512", #selector(demoHashAll)),
      ("2) AES (String/Data) Encrypt & Decrypt (async/await)", #selector(demoAESAsync)),
      ("3) AES (String/Data) Encrypt & Decrypt (closure)", #selector(demoAESClosure)),
      ("4) RSA KeyPair + Encrypt/Decrypt + Sign/Verify (async/await)", #selector(demoRSAAsync)),
      ("5) RSA KeyPair + Encrypt/Decrypt + Sign/Verify (closure)", #selector(demoRSAClosure)),
      ("6) Base64 / HEX / URL Encode & Decode", #selector(demoEncoding)),
      ("7) HMAC (SHA256/SHA512) + Parameter Signing", #selector(demoHMAC)),
      ("8) Secure Random (String/Number) + Keychain Store", #selector(demoRandomAndKeychain)),
      ("9) Sensitive Data Masking (Phone/ID/Email)", #selector(demoMasking)),
      ("10) Secure Erase (Data/File) + Anti-Tampering Checks", #selector(demoEraseAndAntiTamper)),
      ("Clear On-screen Output", #selector(clearOutput)),
    ]

    for (title, selector) in actions {
      let button = UIButton(type: .system)
      button.setTitle(title, for: .normal)
      button.contentHorizontalAlignment = .left
      button.addTarget(self, action: selector, for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(outputView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.52),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      outputView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      outputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      outputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      outputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  // MARK: - 1) Hash (String / Data / File)

  /// Demonstrates MD5/SHA256/SHA512 for String, Data, and File.
  @objc private func demoHashAll() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let text = "Hello FKSecurity"
        let data = Data(text.utf8)

        let md5 = try await self.security.hash.hashString(text, algorithm: .md5)
        let sha256 = try await self.security.hash.hashData(data, algorithm: .sha256)
        let sha512 = try await self.security.hash.hashString(text, algorithm: .sha512)

        self.appendOutput("Hash String MD5: \(md5)")
        self.appendOutput("Hash Data SHA256: \(sha256)")
        self.appendOutput("Hash String SHA512: \(sha512)")

        // Create a demo file and hash it.
        let fileURL = try self.makeDemoFile(name: "fksecurity-hash-demo.txt", content: text + " (file)")
        let fileSHA256 = try await self.security.hash.hashFile(at: fileURL, algorithm: .sha256)
        self.appendOutput("Hash File SHA256: \(fileSHA256)")
        self.appendOutput("File path: \(fileURL.path)")
      } catch {
        self.appendOutput("Hash demo failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 2) AES (async/await)

  /// Demonstrates AES-CBC with PKCS7 padding for both String and Data.
  @objc private func demoAESAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let key = try await self.security.aes.generateKey(length: 32) // AES-256
        let iv = try await self.security.aes.generateIV()            // 16 bytes

        // String -> Base64 ciphertext -> String
        let plaintext = "AES-CBC is commonly used for interoperability."
        let ciphertext = try await self.security.aes.encryptString(plaintext, using: key, iv: iv, mode: .cbc)
        let decrypted = try await self.security.aes.decryptString(ciphertext, using: key, iv: iv, mode: .cbc)

        self.appendOutput("AES async (String) ciphertext(Base64): \(ciphertext)")
        self.appendOutput("AES async (String) decrypted: \(decrypted)")

        // Data -> Data -> Data
        let input = Data([0x01, 0x02, 0x03, 0xAA, 0xBB, 0xCC])
        let enc = try await self.security.aes.encrypt(input, using: key, iv: iv, mode: .cbc)
        let dec = try await self.security.aes.decrypt(enc, using: key, iv: iv, mode: .cbc)

        self.appendOutput("AES async (Data) enc bytes: \(enc.count), dec bytes: \(dec.count)")
        self.appendOutput("AES async (Data) roundtrip OK: \(dec == input)")
      } catch {
        self.appendOutput("AES async demo failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 3) AES (closure)

  /// Demonstrates closure-based API for projects that are not fully async/await yet.
  @objc private func demoAESClosure() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let key = try await self.security.aes.generateKey(length: 16) // AES-128
        let iv = try await self.security.aes.generateIV()
        let data = Data("hello (closure)".utf8)

        self.security.aes.encrypt(data, using: key, iv: iv, mode: .cbc) { [weak self] result in
          guard let self else { return }
          switch result {
          case let .success(cipher):
            self.appendOutput("AES closure encrypt OK, bytes: \(cipher.count)")
            self.security.aes.decrypt(cipher, using: key, iv: iv, mode: .cbc) { [weak self] decryptResult in
              guard let self else { return }
              switch decryptResult {
              case let .success(plain):
                let text = String(data: plain, encoding: .utf8) ?? "<non-utf8>"
                self.appendOutput("AES closure decrypt OK: \(text)")
              case let .failure(error):
                self.appendOutput("AES closure decrypt failed: \(error.localizedDescription)")
              }
            }
          case let .failure(error):
            self.appendOutput("AES closure encrypt failed: \(error.localizedDescription)")
          }
        }
      } catch {
        self.appendOutput("AES closure setup failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 4) RSA (async/await)

  /// Demonstrates RSA key generation, encryption/decryption, and signature verification.
  @objc private func demoRSAAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let tag = "com.fkkit.examples.security.rsa.\(UUID().uuidString)"
        let pair = try await self.security.rsa.generateKeyPair(keySize: 2048, tag: tag, storeInKeychain: false)

        let message = Data("hello rsa".utf8)
        let encrypted = try await self.security.rsa.encrypt(message, publicKey: pair.publicKey, algorithm: .oaepSHA256)
        let decrypted = try await self.security.rsa.decrypt(encrypted, privateKey: pair.privateKey, algorithm: .oaepSHA256)

        let signature = try await self.security.rsa.sign(message, privateKey: pair.privateKey, algorithm: .pkcs1v15SHA256)
        let ok = try await self.security.rsa.verify(signature, data: message, publicKey: pair.publicKey, algorithm: .pkcs1v15SHA256)

        self.appendOutput("RSA async encrypted bytes: \(encrypted.count)")
        self.appendOutput("RSA async decrypted: \(String(decoding: decrypted, as: UTF8.self))")
        self.appendOutput("RSA async signature bytes: \(signature.count)")
        self.appendOutput("RSA async verify OK: \(ok)")

        // Export/Import DER examples (SPKI public, PKCS8 private).
        let publicSPKI = try await self.security.rsa.exportPublicKeySPKIDER(pair.publicKey)
        let privatePKCS8 = try await self.security.rsa.exportPrivateKeyPKCS8DER(pair.privateKey)
        _ = try await self.security.rsa.importPublicKey(fromDER: publicSPKI, isSPKI: true)
        _ = try await self.security.rsa.importPrivateKey(fromDER: privatePKCS8, isPKCS8: true)
        self.appendOutput("RSA export/import DER OK. SPKI bytes: \(publicSPKI.count), PKCS8 bytes: \(privatePKCS8.count)")
      } catch {
        self.appendOutput("RSA async demo failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 5) RSA (closure)

  /// Demonstrates closure-based RSA APIs.
  @objc private func demoRSAClosure() {
    let tag = "com.fkkit.examples.security.rsa.callback.\(UUID().uuidString)"
    security.rsa.generateKeyPair(keySize: 2048, tag: tag, storeInKeychain: false) { [weak self] result in
      guard let self else { return }
      switch result {
      case let .success(pair):
        let message = Data("rsa closure message".utf8)
        self.security.rsa.encrypt(message, publicKey: pair.publicKey, algorithm: .pkcs1) { [weak self] encResult in
          guard let self else { return }
          switch encResult {
          case let .success(cipher):
            self.appendOutput("RSA closure encrypt OK, bytes: \(cipher.count)")
            self.security.rsa.decrypt(cipher, privateKey: pair.privateKey, algorithm: .pkcs1) { [weak self] decResult in
              guard let self else { return }
              switch decResult {
              case let .success(plain):
                self.appendOutput("RSA closure decrypt OK: \(String(decoding: plain, as: UTF8.self))")
                self.security.rsa.sign(message, privateKey: pair.privateKey, algorithm: .pkcs1v15SHA512) { [weak self] sigResult in
                  guard let self else { return }
                  switch sigResult {
                  case let .success(signature):
                    self.security.rsa.verify(signature, data: message, publicKey: pair.publicKey, algorithm: .pkcs1v15SHA512) { [weak self] verifyResult in
                      guard let self else { return }
                      switch verifyResult {
                      case let .success(ok):
                        self.appendOutput("RSA closure verify OK: \(ok)")
                      case let .failure(error):
                        self.appendOutput("RSA closure verify failed: \(error.localizedDescription)")
                      }
                    }
                  case let .failure(error):
                    self.appendOutput("RSA closure sign failed: \(error.localizedDescription)")
                  }
                }
              case let .failure(error):
                self.appendOutput("RSA closure decrypt failed: \(error.localizedDescription)")
              }
            }
          case let .failure(error):
            self.appendOutput("RSA closure encrypt failed: \(error.localizedDescription)")
          }
        }
      case let .failure(error):
        self.appendOutput("RSA closure key pair failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 6) Base64 / HEX / URL

  /// Demonstrates Base64/HEX/URL encoding and decoding.
  @objc private func demoEncoding() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let coder = self.security.code
        let bytes = Data([0x01, 0xAB, 0xFF, 0x10, 0x20])

        let base64 = coder.base64Encode(bytes)
        let decodedB64 = try coder.base64Decode(base64)

        let hex = coder.hexString(from: bytes, uppercase: false)
        let decodedHex = try coder.data(fromHex: hex)

        let urlRaw = "https://example.com/search?q=hello world&x=1"
        let urlEncoded = coder.urlEncode(urlRaw)
        let urlDecoded = coder.urlDecode(urlEncoded)

        self.appendOutput("Base64: \(base64)")
        self.appendOutput("Base64 decode OK: \(decodedB64 == bytes)")
        self.appendOutput("HEX: \(hex)")
        self.appendOutput("HEX decode OK: \(decodedHex == bytes)")
        self.appendOutput("URL encoded: \(urlEncoded)")
        self.appendOutput("URL decoded == raw: \(urlDecoded == urlRaw)")
      } catch {
        self.appendOutput("Encoding demo failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 7) HMAC

  /// Demonstrates HMAC (SHA256/SHA512) and parameter signing.
  @objc private func demoHMAC() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let payload = Data("payload".utf8)
        let key = Data("secret".utf8)

        let mac256 = try await self.security.sign.hmacHex(payload, key: key, algorithm: .sha256)
        let mac512 = try await self.security.sign.hmacHex(payload, key: key, algorithm: .sha512)

        self.appendOutput("HMAC-SHA256(hex): \(mac256)")
        self.appendOutput("HMAC-SHA512(hex): \(mac512)")

        // Parameter signing (typed overload is Sendable-friendly).
        let params: [String: String] = [
          "userId": "1001",
          "timestamp": "\(Int(Date().timeIntervalSince1970))",
          "nonce": UUID().uuidString,
        ]
        let signature = try await self.security.sign.signParameters(params, secret: "server-shared-secret", algorithm: .sha256)
        self.appendOutput("Params signature(hex): \(signature)")
      } catch {
        self.appendOutput("HMAC demo failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 8) Secure Random + Keychain

  /// Demonstrates secure random and storing key material in Keychain.
  @objc private func demoRandomAndKeychain() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let nonce = try await self.security.utils.randomString(
          length: 16,
          alphabet: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        )
        let bytes = try await self.security.utils.randomBytes(count: 8)
        // Convert random bytes to an unsigned integer without alignment assumptions.
        let number = bytes.reduce(UInt64(0)) { (acc, byte) in (acc << 8) | UInt64(byte) }

        self.appendOutput("Random nonce: \(nonce)")
        self.appendOutput("Random UInt64: \(number)")

        // Store an AES key in Keychain for later retrieval.
        let aesKey = try await self.security.aes.generateKey(length: 32)
        try self.security.keys.setKey(
          aesKey,
          forKey: "fksecurity.demo.aesKey",
          accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        )
        let loadedKey = try self.security.keys.key(forKey: "fksecurity.demo.aesKey")
        self.appendOutput("Keychain store/load OK: \(loadedKey == aesKey)")
      } catch {
        self.appendOutput("Random/Keychain demo failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 9) Masking

  /// Demonstrates masking common sensitive strings before logging or analytics.
  @objc private func demoMasking() {
    let phone = security.utils.maskPhone("13800138000")
    let id = security.utils.maskIDCard("110101199001011234")
    let email = security.utils.maskEmail("name@example.com")

    appendOutput("Mask phone: \(phone)")
    appendOutput("Mask ID: \(id)")
    appendOutput("Mask email: \(email)")
  }

  // MARK: - 10) Erase + Anti-Tampering

  /// Demonstrates in-memory wipe, file wipe, and basic anti-debug/tamper signals.
  @objc private func demoEraseAndAntiTamper() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        // In-memory wipe example.
        var secret = Data("highly-sensitive".utf8)
        self.security.utils.secureWipe(&secret)
        self.appendOutput("Secure wipe Data OK: \(secret.isEmpty)")

        // File wipe example (overwrite + delete).
        let fileURL = try self.makeDemoFile(name: "fksecurity-wipe-demo.txt", content: "wipe me")
        self.appendOutput("Wipe target file: \(fileURL.lastPathComponent)")
        try await self.security.utils.secureWipeFile(at: fileURL, passes: 1)
        self.appendOutput("Secure wipe file completed (deleted).")

        // Anti-debug checks (heuristics).
        let debugged = self.security.utils.isDebuggerAttached()
        let suspicious = self.security.utils.hasSuspiciousEnvironment()
        self.appendOutput("Debugger attached: \(debugged)")
        self.appendOutput("Suspicious environment: \(suspicious)")

        // Anti-tampering snapshot: hash current executable and verify.
        let snapshot = try await self.security.utils.snapshotExecutableHash(algorithm: .sha256)
        let verified = try await self.security.utils.verifyExecutableHashSnapshot(snapshot, algorithm: .sha256)
        self.appendOutput("Executable SHA256 snapshot: \(snapshot.prefix(16))...")
        self.appendOutput("Executable snapshot verify OK: \(verified)")
      } catch {
        self.appendOutput("Erase/anti-tamper demo failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Helpers

  @objc private func clearOutput() {
    outputView.text = ""
    appendOutput("On-screen output cleared.")
  }

  /// Creates a temp demo file under Documents.
  private func makeDemoFile(name: String, content: String) throws -> URL {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dir = docs.appendingPathComponent("FKSecurityDemo", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent(name)
    let data = Data(content.utf8)
    try data.write(to: url, options: [.atomic])
    return url
  }

  /// Appends one line into on-screen log.
  private nonisolated func appendOutput(_ message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let line = "[\(DateFormatter.securityDemoFormatter.string(from: Date()))] \(message)\n"
      self.outputView.text.append(line)
      let range = NSRange(location: max(self.outputView.text.count - 1, 0), length: 1)
      self.outputView.scrollRangeToVisible(range)
    }
  }
}

private extension DateFormatter {
  static let securityDemoFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}

