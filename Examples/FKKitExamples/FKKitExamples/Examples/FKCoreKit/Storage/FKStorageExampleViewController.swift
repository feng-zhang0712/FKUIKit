//
//  FKStorageExampleViewController.swift
//  FKKitExamples
//
//  Hands-on FKStorage demos: UserDefaults, Keychain, file, memory, TTL, purge, clear.
//

import UIKit
import FKCoreKit

final class FKStorageExampleViewController: UIViewController {
  // MARK: - Backends (one instance per demo category; thread-safe)

  /// Prefixed keys only — `removeAll` never wipes unrelated `UserDefaults`.
  private let userDefaultsStorage = FKUserDefaultsStorage(keyPrefix: "fk.examples.storage.")

  private lazy var keychainStorage: FKKeychainStorage = {
    let id = Bundle.main.bundleIdentifier ?? "FKKitExamples"
    return FKKeychainStorage(service: "\(id).fkstorage.example")
  }()

  private let fileStorage: FKFileStorage
  private let memoryStorage = FKMemoryStorage()

  // MARK: - UI

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let textView = UITextView()

  init() {
    do {
      fileStorage = try FKFileStorage(directoryName: "FKStorageExamples")
    } catch {
      fatalError("FKFileStorage init failed: \(error)")
    }
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKStorage"
    view.backgroundColor = .systemBackground
    setupLayout()
    appendLog("FKStorage demo ready. Tap actions below.")
  }

  // MARK: - Layout

  private func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false

    scrollView.addSubview(stackView)
    view.addSubview(scrollView)
    view.addSubview(textView)

    let actions: [(String, Selector)] = [
      // UserDefaults
      ("UD: increment launch count", #selector(udIncrementLaunchCount)),
      ("UD: read launch count", #selector(udReadLaunchCount)),
      ("UD: set prefers dark mode", #selector(udSetDarkMode)),
      ("UD: read prefers dark mode", #selector(udReadDarkMode)),
      ("UD: list all keys", #selector(udListKeys)),
      // Keychain
      ("KC: save access token", #selector(kcSaveToken)),
      ("KC: save password", #selector(kcSavePassword)),
      ("KC: read token + password", #selector(kcReadSecrets)),
      ("KC: remove token", #selector(kcRemoveToken)),
      // Codable + file
      ("File: save user profile (JSON)", #selector(fileSaveProfile)),
      ("File: load user profile", #selector(fileLoadProfile)),
      ("File: save image Data (PNG)", #selector(fileSaveImage)),
      ("File: load image Data", #selector(fileLoadImage)),
      ("File: save text note", #selector(fileSaveText)),
      ("File: save JSON document", #selector(fileSaveJSON)),
      ("File: show disk directory path", #selector(fileShowDirectory)),
      // Memory + TTL
      ("Mem: set short-lived cache (2s TTL)", #selector(memSetTTL)),
      ("Mem: read TTL sample", #selector(memReadTTL)),
      ("Mem: wait 3s then read (expired)", #selector(memReadAfterDelay)),
      // Async API
      ("Async: set + get username (UD)", #selector(udAsyncDemo)),
      // Purge + clear
      ("Purge expired (UD + File + KC + Mem)", #selector(purgeAllExpired)),
      ("Clear: memory only", #selector(clearMemory)),
      ("Clear: UserDefaults (prefixed keys only)", #selector(clearUserDefaults)),
      ("Clear: Keychain service", #selector(clearKeychain)),
      ("Clear: file blobs + index", #selector(clearFiles)),
      ("Clear log", #selector(clearLog)),
    ]

    for action in actions {
      let button = UIButton(type: .system)
      button.setTitle(action.0, for: .normal)
      button.contentHorizontalAlignment = .left
      button.addTarget(self, action: action.1, for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }

    textView.isEditable = false
    textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    textView.backgroundColor = .secondarySystemBackground
    textView.layer.cornerRadius = 8
    textView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.45),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      textView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  // MARK: - Logging (main thread)

  private func appendLog(_ message: String) {
    let prefix = DateFormatter.fkStorageLogFormatter.string(from: Date())
    let line = "[\(prefix)] \(message)\n"
    textView.text.append(line)
    let end = textView.text.count
    textView.scrollRangeToVisible(NSRange(location: max(end - 1, 0), length: 1))
  }

  @objc private func clearLog() {
    textView.text = ""
  }

  // MARK: - UserDefaults

  @objc private func udIncrementLaunchCount() {
    let key = FKStorageExampleKey.launchCount.fullKey
    do {
      let current = (try? userDefaultsStorage.value(key: key, as: Int.self)) ?? 0
      try userDefaultsStorage.set(current + 1, key: key)
      appendLog("UD: launchCount = \(current + 1)")
    } catch {
      appendLog("UD: error \(error)")
    }
  }

  @objc private func udReadLaunchCount() {
    let key = FKStorageExampleKey.launchCount.fullKey
    do {
      let n = try userDefaultsStorage.value(key: key, as: Int.self)
      appendLog("UD: launchCount = \(n)")
    } catch {
      appendLog("UD: read failed — \(error.localizedDescription)")
    }
  }

  @objc private func udSetDarkMode() {
    let key = FKStorageExampleKey.prefersDarkMode.fullKey
    do {
      try userDefaultsStorage.set(true, key: key)
      appendLog("UD: prefersDarkMode = true")
    } catch {
      appendLog("UD: error \(error)")
    }
  }

  @objc private func udReadDarkMode() {
    let key = FKStorageExampleKey.prefersDarkMode.fullKey
    do {
      let v = try userDefaultsStorage.value(key: key, as: Bool.self)
      appendLog("UD: prefersDarkMode = \(v)")
    } catch {
      appendLog("UD: read failed — \(error.localizedDescription)")
    }
  }

  @objc private func udListKeys() {
    do {
      let keys = try userDefaultsStorage.allKeys()
      appendLog("UD: keys (\(keys.count)): \(keys.joined(separator: ", "))")
    } catch {
      appendLog("UD: allKeys failed — \(error)")
    }
  }

  @objc private func udAsyncDemo() {
    let key = FKStorageExampleKey.lastUsername.fullKey
    Task { [weak self] in
      guard let self else { return }
      do {
        // Use the async overload to avoid redundant-await diagnostics.
        try await self.userDefaultsStorage.set("demo_user", key: key, ttl: nil)
        // Read synchronously (thread-safe backend). This avoids redundant-await diagnostics caused by overload resolution.
        let name = try self.userDefaultsStorage.value(key: key, as: String.self)
        await MainActor.run {
          self.appendLog("Async UD: username = \(name)")
        }
      } catch {
        await MainActor.run {
          self.appendLog("Async UD: error \(error.localizedDescription)")
        }
      }
    }
  }

  // MARK: - Keychain

  @objc private func kcSaveToken() {
    let key = FKStorageExampleKey.accessToken.fullKey
    let payload = FKStorageExampleAuthToken(token: "example-access-token", expiresAt: Date().timeIntervalSince1970 + 3600)
    do {
      try keychainStorage.set(payload, key: key)
      appendLog("KC: token saved (service-scoped).")
    } catch {
      appendLog("KC: save failed — \(error)")
    }
  }

  @objc private func kcSavePassword() {
    let key = FKStorageExampleKey.userPassword.fullKey
    let payload = FKStorageExamplePassword(account: "demo@example.com", secret: "do-not-log-in-production")
    do {
      try keychainStorage.set(payload, key: key)
      appendLog("KC: password payload saved.")
    } catch {
      appendLog("KC: save failed — \(error)")
    }
  }

  @objc private func kcReadSecrets() {
    let tKey = FKStorageExampleKey.accessToken.fullKey
    let pKey = FKStorageExampleKey.userPassword.fullKey
    do {
      let token = try keychainStorage.value(key: tKey, as: FKStorageExampleAuthToken.self)
      let pw = try keychainStorage.value(key: pKey, as: FKStorageExamplePassword.self)
      appendLog("KC: token=\(token.token.prefix(8))… account=\(pw.account)")
    } catch {
      appendLog("KC: read failed — \(error.localizedDescription)")
    }
  }

  @objc private func kcRemoveToken() {
    let key = FKStorageExampleKey.accessToken.fullKey
    do {
      try keychainStorage.remove(key: key)
      appendLog("KC: token removed.")
    } catch {
      appendLog("KC: remove failed — \(error)")
    }
  }

  // MARK: - File (Codable + Data)

  @objc private func fileSaveProfile() {
    let key = "profile.main"
    let profile = FKStorageExampleUserProfile(id: 42, displayName: "Ada", email: "ada@example.com")
    do {
      try fileStorage.set(profile, key: key)
      appendLog("File: profile saved under key \(key).")
    } catch {
      appendLog("File: save profile — \(error)")
    }
  }

  @objc private func fileLoadProfile() {
    let key = "profile.main"
    do {
      let p = try fileStorage.value(key: key, as: FKStorageExampleUserProfile.self)
      appendLog("File: profile \(p.displayName) <\(p.email)> id=\(p.id)")
    } catch {
      appendLog("File: load profile — \(error.localizedDescription)")
    }
  }

  @objc private func fileSaveImage() {
    let key = FKStorageExampleKey.imageBlob.fullKey
    let data = FKStorageExampleSampleImage.pngDataFromRenderedImage() ?? FKStorageExampleSampleImage.pngData()
    do {
      try fileStorage.set(data, key: key)
      appendLog("File: PNG bytes saved, size=\(data.count).")
    } catch {
      appendLog("File: save image — \(error)")
    }
  }

  @objc private func fileLoadImage() {
    let key = FKStorageExampleKey.imageBlob.fullKey
    do {
      let data = try fileStorage.value(key: key, as: Data.self)
      appendLog("File: PNG loaded, size=\(data.count).")
    } catch {
      appendLog("File: load image — \(error.localizedDescription)")
    }
  }

  @objc private func fileSaveText() {
    let key = FKStorageExampleKey.textNote.fullKey
    do {
      try fileStorage.set("Hello, FKStorage file text.\nLine 2.", key: key)
      appendLog("File: text note saved.")
    } catch {
      appendLog("File: save text — \(error)")
    }
  }

  @objc private func fileSaveJSON() {
    let key = FKStorageExampleKey.jsonDocument.fullKey
    let doc = FKStorageExampleJSONDocument(title: "Demo", items: ["a", "b", "c"], revision: 3)
    do {
      try fileStorage.set(doc, key: key)
      appendLog("File: JSON document saved, revision=\(doc.revision).")
    } catch {
      appendLog("File: save JSON — \(error)")
    }
  }

  @objc private func fileShowDirectory() {
    appendLog("File: root = \(fileStorage.directoryURL.path)")
  }

  // MARK: - Memory + TTL

  @objc private func memSetTTL() {
    let key = FKStorageExampleKey.ttlSample.fullKey
    do {
      try memoryStorage.set("expires_in_2_seconds", key: key, ttl: 2)
      appendLog("Mem: TTL sample set (2s).")
    } catch {
      appendLog("Mem: set failed — \(error)")
    }
  }

  @objc private func memReadTTL() {
    let key = FKStorageExampleKey.ttlSample.fullKey
    do {
      let s = try memoryStorage.value(key: key, as: String.self)
      appendLog("Mem: value = \(s)")
    } catch {
      appendLog("Mem: read — \(error.localizedDescription)")
    }
  }

  @objc private func memReadAfterDelay() {
    appendLog("Mem: waiting 3s then read…")
    Task { [weak self] in
      try? await Task.sleep(nanoseconds: 3_000_000_000)
      guard let self else { return }
      let key = FKStorageExampleKey.ttlSample.fullKey
      do {
        let s = try self.memoryStorage.value(key: key, as: String.self)
        await MainActor.run { self.appendLog("Mem: still valid? value = \(s)") }
      } catch {
        await MainActor.run {
          self.appendLog("Mem: expected notFound after expiry — \(error.localizedDescription)")
        }
      }
    }
  }

  // MARK: - Purge & clear

  @objc private func purgeAllExpired() {
    do {
      try userDefaultsStorage.purgeExpired()
      try fileStorage.purgeExpired()
      try keychainStorage.purgeExpired()
      try memoryStorage.purgeExpired()
      appendLog("Purge: completed for all backends.")
    } catch {
      appendLog("Purge: error — \(error)")
    }
  }

  @objc private func clearMemory() {
    do {
      try memoryStorage.removeAll()
      appendLog("Clear: memory storage emptied.")
    } catch {
      appendLog("Clear: memory — \(error)")
    }
  }

  @objc private func clearUserDefaults() {
    do {
      try userDefaultsStorage.removeAll()
      appendLog("Clear: UserDefaults (prefixed keys only).")
    } catch {
      appendLog("Clear: UD — \(error)")
    }
  }

  @objc private func clearKeychain() {
    do {
      try keychainStorage.removeAll()
      appendLog("Clear: Keychain items for this service removed.")
    } catch {
      appendLog("Clear: KC — \(error)")
    }
  }

  @objc private func clearFiles() {
    do {
      try fileStorage.removeAll()
      appendLog("Clear: file storage emptied (blobs + index).")
    } catch {
      appendLog("Clear: file — \(error)")
    }
  }
}

// MARK: - Date formatting

private extension DateFormatter {
  static let fkStorageLogFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    return f
  }()
}
