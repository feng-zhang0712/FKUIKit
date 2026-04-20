//
//  FKStorageExampleModels.swift
//  FKKitExamples
//
//  Shared models and keys for FKStorage demos — copy into your app as a starting point.
//

import Foundation
import UIKit
import FKCoreKit

// MARK: - Namespaced keys (avoid collisions across features)

/// Example keys using `FKStorageKey.fullKey` — keep one namespace per app or module.
nonisolated enum FKStorageExampleKey: String, FKStorageKey {
  // UserDefaults
  case launchCount
  case prefersDarkMode
  case lastUsername

  // Keychain
  case accessToken
  case userPassword

  // File + memory (logical segments)
  case imageBlob
  case textNote
  case jsonDocument
  case ttlSample

  var namespace: String {
    "com.example.FKKitExamples.FKStorage"
  }
}

// MARK: - Codable models for Keychain / disk

/// OAuth-style token payload (Keychain demo).
/// `nonisolated` opts out of the module’s default MainActor isolation so `Codable` + `Sendable` match `FKCodableStorage`.
nonisolated struct FKStorageExampleAuthToken: Codable, Sendable, Equatable {
  var token: String
  var expiresAt: TimeInterval
}

/// Simple credential wrapper (Keychain demo — never log real passwords in production).
nonisolated struct FKStorageExamplePassword: Codable, Sendable, Equatable {
  var account: String
  var secret: String
}

/// User profile persisted as JSON via `FKFileStorage` (Codable demo).
nonisolated struct FKStorageExampleUserProfile: Codable, Sendable, Equatable {
  var id: Int
  var displayName: String
  var email: String
}

/// Arbitrary JSON-friendly document (file demo).
nonisolated struct FKStorageExampleJSONDocument: Codable, Sendable, Equatable {
  var title: String
  var items: [String]
  var revision: Int
}

// MARK: - Sample image bytes (1×1 PNG) for file storage demo

nonisolated enum FKStorageExampleSampleImage {
  /// Minimal valid PNG data — safe to persist as `Data` via `FKFileStorage`.
  static func pngData() -> Data {
    // 1×1 transparent PNG (67 bytes).
    let base64 =
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    return Data(base64Encoded: base64)!
  }

  /// Optional: render a small UIImage and export PNG (requires UIKit).
  static func pngDataFromRenderedImage() -> Data? {
    let size = CGSize(width: 8, height: 8)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    defer { UIGraphicsEndImageContext() }
    UIColor.systemBlue.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
    return image.pngData()
  }
}
