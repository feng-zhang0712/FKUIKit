# FKSecurity

Pure-native Swift security & cryptography for large-scale iOS projects.

`FKSecurity` ships with `FKCoreKit` and is designed for production apps and open-source SDKs: **no third-party libraries**, **no Objective-C dependency**, and **async-first** APIs that do not block the main thread.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Encryption & Algorithms](#supported-encryption--algorithms)
  - [Hash Algorithms (MD5/SHA1/SHA256/SHA512)](#hash-algorithms-md5sha1sha256sha512)
  - [AES Symmetric Encryption](#aes-symmetric-encryption)
  - [RSA Asymmetric Encryption](#rsa-asymmetric-encryption)
  - [Data Encoding (Base64/HEX/URL)](#data-encoding-base64hexurl)
  - [HMAC Signature](#hmac-signature)
  - [Security Tools](#security-tools)
- [Requirements](#requirements)
- [Installation](#installation)
- [Architecture](#architecture)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
  - [String/File Hash Calculation](#stringfile-hash-calculation)
  - [AES Encrypt & Decrypt](#aes-encrypt--decrypt)
  - [RSA Key Generate/Encrypt/Decrypt/Sign](#rsa-key-generateencryptdecryptsign)
  - [Base64/HEX Encode & Decode](#base64hex-encode--decode)
  - [HMAC Signature Verification](#hmac-signature-verification)
  - [Data Masking & Secure Random](#data-masking--secure-random)
- [API Reference](#api-reference)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Security Notes](#security-notes)
- [License](#license)

## Overview

`FKSecurity` provides a modular, protocol-oriented security toolbox for:

- Hashing (String / Data / File)
- AES encryption/decryption (CBC/ECB + PKCS7)
- RSA encryption/decryption and signatures
- Data encoding utilities (Base64 / HEX / URL encoding)
- HMAC signatures and stable request parameter signing
- Practical security utilities (secure random, masking, anti-debug signals, secure wipe)

All cryptographic heavy work runs on a dedicated background executor to avoid UI stalls.

## Features

- **Async-first**: `async/await` APIs across core services, plus closure-based convenience overloads.
- **Protocol-oriented**: `FKHashing`, `FKAESCrypting`, `FKRSACrypting`, `FKSecuritySigning`, `FKSecurityCoding`, `FKSecurityUtilizing`.
- **Streaming file support**: Hash/AES support chunked file processing for large files.
- **Keychain integration**: built-in `FKKeychainKeyStore` for storing raw key bytes (e.g. AES keys).
- **Open-source friendly**: clean module layout, unified error type `FKSecurityError`.

## Supported Encryption & Algorithms

### Hash Algorithms (MD5/SHA1/SHA256/SHA512)

- **Algorithms**: MD5, SHA-1, SHA-256, SHA-512
- **Inputs**: `String`, `Data`, `File`
- **Output**: lowercase HEX digest string

> Notes:
> - MD5 and SHA-1 are provided for compatibility and non-security use cases (e.g. caching keys, legacy integrations). For security-sensitive integrity checks, prefer SHA-256 or stronger.

### AES Symmetric Encryption

- **Algorithms**: AES (128/192/256-bit keys)
- **Modes**: CBC / ECB
- **Padding**: PKCS7
- **Inputs/Outputs**:
  - `Data` ↔ `Data`
  - `String` ↔ Base64 ciphertext `String`
  - `File` ↔ `File` (streaming)
- **Key/IV**:
  - Key length must be **16 / 24 / 32 bytes**
  - CBC requires a **16-byte IV**
  - ECB ignores IV (still supported for interoperability, but generally discouraged)

### RSA Asymmetric Encryption

- **Key generation**: RSA key pair (`2048/3072/4096` bits), optional Keychain persistence by tag
- **Encryption algorithms**:
  - PKCS#1 v1.5 (`.pkcs1`)
  - OAEP SHA-256 (`.oaepSHA256`)
- **Signatures**:
  - PKCS#1 v1.5 SHA-256 (`.pkcs1v15SHA256`)
  - PKCS#1 v1.5 SHA-512 (`.pkcs1v15SHA512`)
- **Import/Export (DER)**:
  - Public key: SPKI DER (`SubjectPublicKeyInfo`)
  - Private key: PKCS#8 DER (`PrivateKeyInfo`)

### Data Encoding (Base64/HEX/URL)

- Base64 encode/decode (`Data` ↔ `String`)
- URL encode/decode (`String` ↔ `String`)
- HEX encode/decode (`Data` ↔ `String`)

### HMAC Signature

- HMAC with SHA-256 / SHA-512
- Stable request parameter signing:
  - Canonicalizes parameters in a deterministic order
  - Suitable for API anti-tampering checks (when used with HTTPS + server-side verification)

### Security Tools

- Secure random bytes / random strings (`SecRandomCopyBytes`)
- Data masking:
  - phone number
  - ID card number
  - email
- Basic anti-debug signals:
  - debugger detection via `sysctl`
  - suspicious environment hints (e.g. `DYLD_` variables)
- Secure wipe:
  - in-memory `Data` overwrite + release
  - file overwrite (random passes) + delete

## Requirements

- Swift 5.9+
- iOS 13.0+
- No third-party dependency
- System frameworks only:
  - `Foundation`
  - `Security`
  - Apple-provided `CommonCrypto` (for AES/HMAC/MD5/SHA)

## Installation

`FKSecurity` is included in `FKCoreKit`.

### Swift Package Manager

Add FKKit to your `Package.swift`:

```swift
.package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.16.0")
```

Then import in your code:

```swift
import FKCoreKit
```

## Architecture

Directory layout:

- `Core/`
  - `FKSecurity.swift` (public entry point, singleton)
  - `FKSecurityExecutor.swift` (background execution)
  - `FKSecurityProtocols.swift` (protocol contracts)
  - `FKSecurity+Convenience.swift` (one-liner convenience APIs)
- `Model/`
  - `FKSecurityError.swift`
  - `FKSecurityModels.swift` (algorithms, key pair model)
- `Hash/` (`FKHashService`)
- `AES/` (`FKAESService`)
- `RSA/` (`FKRSAService`)
- `Code/` (`FKSecurityCoder`)
- `Signature/` (`FKSignatureService`)
- `Utils/`
  - `FKSecurityUtils` (random, masking, anti-debug hints, wipe)
  - `FKKeychainKeyStore` (Keychain storage)
  - `FKASN1` (minimal ASN.1 DER helper for PKCS8/SPKI wrapping)

## Basic Usage

```swift
import FKCoreKit

let security = FKSecurity.shared

// Hash
let sha256 = try await security.hash(.sha256, string: "hello")

// AES (CBC + PKCS7)
let key = try await security.aes.generateKey(length: 32)   // AES-256
let iv  = try await security.aes.generateIV()              // 16 bytes

let cipher = try await security.aesEncrypt("secret", key: key, iv: iv, mode: .cbc)
let plain  = try await security.aesDecrypt(cipher, key: key, iv: iv, mode: .cbc)
```

## Advanced Usage

### String/File Hash Calculation

```swift
import FKCoreKit

let s = FKSecurity.shared

let md5 = try await s.hash.hashString("cache-key", algorithm: .md5)
let sha512 = try await s.hash.hashData(Data("payload".utf8), algorithm: .sha512)

let fileURL = Bundle.main.bundleURL.appendingPathComponent("SomeLargeFile.bin")
let fileSHA256 = try await s.hash.hashFile(at: fileURL, algorithm: .sha256)
```

### AES Encrypt & Decrypt

```swift
import FKCoreKit

let s = FKSecurity.shared
let key = try await s.aes.generateKey(length: 16) // AES-128
let iv  = try await s.aes.generateIV()

let plaintext = "Hello AES-CBC"
let ciphertextBase64 = try await s.aes.encryptString(plaintext, using: key, iv: iv, mode: .cbc)
let decrypted = try await s.aes.decryptString(ciphertextBase64, using: key, iv: iv, mode: .cbc)
```

File encryption (streaming):

```swift
import FKCoreKit

let s = FKSecurity.shared
let key = try await s.aes.generateKey(length: 32)
let iv  = try await s.aes.generateIV()

let input = URL(fileURLWithPath: "/path/to/input.dat")
let enc   = URL(fileURLWithPath: "/path/to/output.dat.enc")
let dec   = URL(fileURLWithPath: "/path/to/output.dat.dec")

try await s.aes.encryptFile(at: input, to: enc, using: key, iv: iv, mode: .cbc)
try await s.aes.decryptFile(at: enc, to: dec, using: key, iv: iv, mode: .cbc)
```

### RSA Key Generate/Encrypt/Decrypt/Sign

```swift
import FKCoreKit

let s = FKSecurity.shared

// Generate a key pair (optionally stored in Keychain by tag)
let pair = try await s.rsa.generateKeyPair(keySize: 2048, tag: "com.example.fksecurity.rsa", storeInKeychain: true)

// Encrypt / Decrypt
let message = Data("hello".utf8)
let encrypted = try await s.rsa.encrypt(message, publicKey: pair.publicKey, algorithm: .oaepSHA256)
let decrypted = try await s.rsa.decrypt(encrypted, privateKey: pair.privateKey, algorithm: .oaepSHA256)

// Sign / Verify
let signature = try await s.rsa.sign(message, privateKey: pair.privateKey, algorithm: .pkcs1v15SHA256)
let ok = try await s.rsa.verify(signature, data: message, publicKey: pair.publicKey, algorithm: .pkcs1v15SHA256)
```

Import/Export (DER):

```swift
import FKCoreKit

let s = FKSecurity.shared
let pair = try await s.rsa.generateKeyPair(keySize: 2048, tag: "com.example.rsa.export", storeInKeychain: false)

let publicSPKI = try await s.rsa.exportPublicKeySPKIDER(pair.publicKey)
let privatePKCS8 = try await s.rsa.exportPrivateKeyPKCS8DER(pair.privateKey)

let importedPublic = try await s.rsa.importPublicKey(fromDER: publicSPKI, isSPKI: true)
let importedPrivate = try await s.rsa.importPrivateKey(fromDER: privatePKCS8, isPKCS8: true)
_ = (importedPublic, importedPrivate)
```

### Base64/HEX Encode & Decode

```swift
import FKCoreKit

let coder = FKSecurity.shared.code
let data = Data([0x01, 0xAB, 0xFF])

let b64 = coder.base64Encode(data)
let raw = try coder.base64Decode(b64)

let hex = coder.hexString(from: data, uppercase: false)
let back = try coder.data(fromHex: hex)
_ = (raw, back)
```

### HMAC Signature Verification

Typed parameter signing (recommended):

```swift
import FKCoreKit

let s = FKSecurity.shared

let params: [String: String] = [
  "userId": "1001",
  "timestamp": "1710000000",
  "nonce": "abc123"
]

let sig = try await s.sign.signParameters(params, secret: "server-shared-secret", algorithm: .sha256)
// Send `params` + `sig` to server, verify server-side with the same canonicalization rules.
```

Raw HMAC:

```swift
import FKCoreKit

let s = FKSecurity.shared
let mac = try await s.sign.hmacHex(Data("payload".utf8), key: Data("key".utf8), algorithm: .sha512)
```

### Data Masking & Secure Random

```swift
import FKCoreKit

let u = FKSecurity.shared.utils

let phone = u.maskPhone("13800138000")     // 138****8000
let email = u.maskEmail("name@example.com")
let id    = u.maskIDCard("110101199001011234")

let bytes = try await u.randomBytes(count: 32)
let nonce = try await u.randomString(length: 16)
_ = (phone, email, id, bytes, nonce)
```

## API Reference

Main entry:

- `FKSecurity.shared`

Services:

- `FKSecurity.shared.hash` → `FKHashing`
  - `hashString(_:algorithm:)`
  - `hashData(_:algorithm:)`
  - `hashFile(at:algorithm:)`
- `FKSecurity.shared.aes` → `FKAESCrypting`
  - `encrypt(_:using:iv:mode:)` / `decrypt(_:using:iv:mode:)`
  - `encryptString(_:using:iv:mode:)` / `decryptString(_:using:iv:mode:)`
  - `encryptFile(at:to:using:iv:mode:)` / `decryptFile(at:to:using:iv:mode:)`
  - `generateKey(length:)` / `generateIV()`
- `FKSecurity.shared.rsa` → `FKRSACrypting`
  - `generateKeyPair(keySize:tag:storeInKeychain:)`
  - `encrypt(_:publicKey:algorithm:)` / `decrypt(_:privateKey:algorithm:)`
  - `sign(_:privateKey:algorithm:)` / `verify(_:data:publicKey:algorithm:)`
  - `exportPublicKeySPKIDER(_:)` / `exportPrivateKeyPKCS8DER(_:)`
  - `importPublicKey(fromDER:isSPKI:)` / `importPrivateKey(fromDER:isPKCS8:)`
- `FKSecurity.shared.code` → `FKSecurityCoding`
  - `base64Encode(_:)` / `base64Decode(_:)`
  - `urlEncode(_:)` / `urlDecode(_:)`
  - `hexString(from:uppercase:)` / `data(fromHex:)`
- `FKSecurity.shared.sign` → `FKSecuritySigning`
  - `hmac(_:key:algorithm:)` / `hmacHex(_:key:algorithm:)`
  - `signParameters(_:secret:algorithm:)`
  - `verifyParameters(_:secret:signatureHex:algorithm:)`
- `FKSecurity.shared.utils` → `FKSecurityUtilizing`
  - `randomBytes(count:)` / `randomString(length:alphabet:)`
  - `maskPhone(_:)` / `maskIDCard(_:)` / `maskEmail(_:)`
  - `isDebuggerAttached()` / `hasSuspiciousEnvironment()`
  - `secureWipe(_:)` / `secureWipeFile(at:passes:)`
- `FKSecurity.shared.keys` → `FKSecurityKeyStoring` (Keychain-backed)
  - `setKey(_:forKey:accessibility:)` / `key(forKey:)` / `removeKey(forKey:)` / `exists(key:)`

## Error Handling

All operations throw `FKSecurityError`:

- `invalidInput(_:)`
- `invalidKey(_:)`
- `cryptoFailed(status:message:)`
- `securityFailed(status:message:)`
- `keyNotFound(_:)`
- `fileFailed(_:)`
- `unavailable(_:)`
- `unknown(_:)`

Example:

```swift
import FKCoreKit

do {
  let h = try await FKSecurity.shared.hash(.sha256, string: "hello")
  print(h)
} catch let e as FKSecurityError {
  print("FKSecurity error:", e.localizedDescription)
} catch {
  print("Unexpected error:", error)
}
```

## Best Practices

- Always prefer **SHA-256+** for integrity/security; use MD5/SHA-1 only for interoperability or non-security tasks.
- For AES:
  - Prefer **CBC with random IV** (or other modern authenticated modes if available in your system constraints).
  - Never reuse IV with the same key for CBC.
  - Store AES keys in **Keychain** (`FKSecurity.shared.keys`) and never hardcode secrets in the app.
- For RSA:
  - Prefer **OAEP SHA-256** for encryption when interoperable.
  - Use **signatures** for authenticity, not encryption.
- Use HTTPS/TLS for network transport even when signing parameters. Signatures do not replace TLS.
- Keep cryptographic operations off the main thread (already handled by FKSecurity).

## Security Notes

- **AES here provides confidentiality only**. For strong modern schemes, authenticated encryption (AEAD) is recommended. FKSecurity focuses on system APIs and interoperability; you should layer protocol-level authentication (HMAC/RSA signature) and always use TLS.
- **Key management is the real security boundary**:
  - Prefer Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (default in this repo’s Keychain store).
  - Avoid logging keys, IVs, plaintext, or decrypted data.
- **Anti-debug and anti-tamper checks are heuristic**:
  - Do not rely on them as a sole protection mechanism.
  - Keep checks compliant with App Store review rules (no private APIs, no malicious behavior).
- **Commercial compliance**:
  - Uses Apple public APIs only and is suitable for commercial apps.
  - Ensure your usage complies with local regulations for cryptography and data protection.

## License

This module follows the same license as the FKKit repository.

