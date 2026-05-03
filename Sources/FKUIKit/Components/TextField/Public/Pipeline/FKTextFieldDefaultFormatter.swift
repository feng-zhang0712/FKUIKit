import Foundation

/// Default formatter used by `FKTextField`.
///
/// The default formatter provides:
/// - sanitization (emoji/whitespace/special character filtering),
/// - per-format raw normalization,
/// - per-format display formatting (grouping/separators).
///
/// - Important: This formatter is deterministic and does not depend on locale.
public struct FKTextFieldDefaultFormatter: FKTextFieldFormatting {
  /// Creates a default formatter.
  public init() {}

  /// Formats text according to the active input rule.
  ///
  /// - Parameters:
  ///   - text: The current display text (may already contain separators).
  ///   - rule: The active input rule defining formatting and filtering behavior.
  /// - Returns: A `FKTextFieldFormattingResult` containing raw and formatted output.
  public func format(text: String, rule: FKTextFieldInputRule) -> FKTextFieldFormattingResult {
    var candidate = text
    var removedIllegalCharacters = false

    if !rule.allowsEmoji, candidate.fk_containsEmoji {
      // Remove emoji scalars early to avoid surprising grouping behavior.
      candidate = candidate.unicodeScalars.filter { scalar in
        if scalar.properties.isEmojiPresentation {
          return false
        }
        // Do not drop ASCII digits/symbols that can form keycap emoji sequences.
        if scalar.properties.isEmoji && !scalar.isASCII {
          return false
        }
        return true
      }
        .map(String.init)
        .joined()
      removedIllegalCharacters = true
    }

    if !rule.allowsWhitespace {
      // Strip all whitespace (including newlines) to keep raw input stable.
      let filtered = candidate.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
      removedIllegalCharacters = removedIllegalCharacters || (filtered != candidate)
      candidate = filtered
    }

    // Apply an additional allowlist filter before per-format normalization.
    switch rule.allowedInput {
    case .any:
      break
    case .numeric:
      let filtered = candidate.filter(\.isNumber)
      removedIllegalCharacters = removedIllegalCharacters || (filtered != candidate)
      candidate = filtered
    case .alphabetic:
      let filtered = candidate.filter(\.isLetter)
      removedIllegalCharacters = removedIllegalCharacters || (filtered != candidate)
      candidate = filtered
    case .alphaNumeric:
      let filtered = candidate.filter { $0.isLetter || $0.isNumber }
      removedIllegalCharacters = removedIllegalCharacters || (filtered != candidate)
      candidate = filtered
    case .chinese:
      let filtered = candidate.unicodeScalars.filter { scalar in
        // CJK Unified Ideographs + extensions A/B/C/D/E/F + Compatibility Ideographs.
        switch scalar.value {
        case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF,
             0x20000...0x2A6DF, 0x2A700...0x2B73F, 0x2B740...0x2B81F,
             0x2B820...0x2CEAF, 0x2CEB0...0x2EBEF:
          return true
        default:
          return false
        }
      }.map(String.init).joined()
      removedIllegalCharacters = removedIllegalCharacters || (filtered != candidate)
      candidate = filtered
    case let .regex(regex):
      let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
      let filtered = candidate.filter { predicate.evaluate(with: String($0)) }
      removedIllegalCharacters = removedIllegalCharacters || (filtered != candidate)
      candidate = filtered
    }

    let result: FKTextFieldFormattingResult
    switch rule.formatType {
    case .phoneNumber:
      // Phone: digits only + 3-4-4 grouping.
      result = formatPhone(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .idCard:
      // ID card: digits + optional trailing X + business grouping.
      result = formatIDCard(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .bankCard:
      // Bank card: digits only + 4-digit grouping.
      result = formatBankCard(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case let .verificationCode(length, allowsAlphabet):
      // Verification code: fixed length, optionally alphanumeric.
      result = formatVerificationCode(
        candidate,
        length: length,
        allowsAlphabet: allowsAlphabet,
        maxLength: rule.maxLength,
        removed: removedIllegalCharacters
      )
    case let .password(_, maxLength, _):
      // Password: no display formatting, only length truncation.
      result = formatPassword(candidate, maxLength: rule.maxLength ?? maxLength, removed: removedIllegalCharacters)
    case let .amount(maxIntegerDigits, decimalDigits):
      // Amount: digits + optional dot + thousands grouping + decimal precision.
      result = formatAmount(
        candidate,
        maxIntegerDigits: maxIntegerDigits,
        decimalDigits: decimalDigits,
        removed: removedIllegalCharacters
      )
    case .email:
      // Email: normalize to lowercase.
      result = formatEmail(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .numeric:
      // Numeric: digits only.
      result = formatNumeric(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .alphabetic:
      // Alphabetic: ASCII letters only.
      result = formatAlphabetic(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .alphaNumeric:
      // Alphanumeric: ASCII letters + digits only.
      result = formatAlphaNumeric(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case let .custom(regex, maxLength, separator, groupPattern):
      // Custom: character filtering by regex + optional grouping.
      result = formatCustom(
        candidate,
        regex: regex,
        maxLength: maxLength ?? rule.maxLength,
        separator: separator,
        groupPattern: groupPattern,
        removed: removedIllegalCharacters
      )
    }

    if !rule.allowsSpecialCharacters {
      // Apply a conservative allowlist after per-format normalization.
      // This keeps common business inputs usable: dot for amounts, @ for emails, underscore for IDs.
      let filteredRaw = result.rawText.filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "@" || $0 == "_" }
      if filteredRaw != result.rawText {
        return FKTextFieldFormattingResult(
          rawText: filteredRaw,
          formattedText: filteredRaw,
          isTruncated: result.isTruncated,
          removedIllegalCharacters: true
        )
      }
    }

    return result
  }
}

private extension FKTextFieldDefaultFormatter {
  /// Formats a phone number as digits with 3-4-4 grouping.
  func formatPhone(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    let limit = maxLength ?? 11
    // Keep digits only, then truncate by raw max length.
    let raw = text.fk_digitsOnly.fk_truncated(to: limit)
    // Display grouping is applied on the raw digits.
    let formatted = raw.fk_grouped(pattern: [3, 4, 4])
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < text.fk_digitsOnly.count, removedIllegalCharacters: removed || raw != text)
  }

  /// Formats an ID card number with business-friendly grouping.
  func formatIDCard(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    // Allow digits plus `X` (checksum char) and normalize to uppercase.
    var raw = text.uppercased().filter { $0.isNumber || $0 == "X" }
    let limit = maxLength ?? 18
    raw = raw.fk_truncated(to: limit)
    // 18-digit uses 6-4-4-4 grouping; 15-digit uses 6-4-5 grouping.
    let format = raw.count > 15 ? [6, 4, 4, 4] : [6, 4, 5]
    let formatted = raw.fk_grouped(pattern: format)
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text.uppercased())
  }

  /// Formats a bank card number with 4-digit grouping.
  func formatBankCard(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    let limit = maxLength ?? 24
    let raw = text.fk_digitsOnly.fk_truncated(to: limit)
    let formatted = raw.fk_grouped(pattern: [4])
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < text.fk_digitsOnly.count, removedIllegalCharacters: removed || raw != text)
  }

  /// Formats a verification code (digits only or alphanumeric) with a fixed max length.
  func formatVerificationCode(
    _ text: String,
    length: Int,
    allowsAlphabet: Bool,
    maxLength: Int?,
    removed: Bool
  ) -> FKTextFieldFormattingResult {
    let maxCount = maxLength ?? max(0, length)
    let raw: String
    if allowsAlphabet {
      // Normalize to uppercase to keep code comparisons stable.
      raw = text.fk_alphaNumericOnly.uppercased().fk_truncated(to: maxCount)
    } else {
      raw = text.fk_digitsOnly.fk_truncated(to: maxCount)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }

  /// Formats a password by truncating to the allowed length.
  func formatPassword(_ text: String, maxLength: Int, removed: Bool) -> FKTextFieldFormattingResult {
    let raw = text.fk_truncated(to: max(0, maxLength))
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed)
  }

  /// Formats an amount with thousands separators and limited decimal scale.
  func formatAmount(
    _ text: String,
    maxIntegerDigits: Int,
    decimalDigits: Int,
    removed: Bool
  ) -> FKTextFieldFormattingResult {
    // Keep only digits and a single dot; downstream splitting handles multi-dot gracefully.
    let filtered = text.filter { $0.isNumber || $0 == "." }
    let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
    // Limit integer and fractional digits separately.
    let integerRaw = String(parts.first ?? "").fk_digitsOnly.fk_truncated(to: max(1, maxIntegerDigits))
    let decimalRaw = parts.count > 1 ? String(parts[1]).fk_digitsOnly.fk_truncated(to: max(0, decimalDigits)) : ""
    // Insert commas in the integer part for display.
    let groupedInteger = groupThousands(integerRaw)
    let formatted = decimalRaw.isEmpty ? groupedInteger : "\(groupedInteger).\(decimalRaw)"
    let raw = decimalRaw.isEmpty ? integerRaw : "\(integerRaw).\(decimalRaw)"
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < filtered.count, removedIllegalCharacters: removed || filtered != text)
  }

  /// Adds comma separators every three digits from the right.
  ///
  /// - Parameter digits: A digit-only string.
  /// - Returns: A display string with commas (e.g. `12345` → `12,345`).
  func groupThousands(_ digits: String) -> String {
    guard digits.count > 3 else { return digits }
    var out: [Character] = []
    out.reserveCapacity(digits.count + digits.count / 3)
    var counter = 0
    for ch in digits.reversed() {
      if counter > 0, counter % 3 == 0 {
        out.append(",")
      }
      out.append(ch)
      counter += 1
    }
    return String(out.reversed())
  }

  /// Formats an email by lowercasing and applying an optional max length.
  func formatEmail(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    var raw = text.lowercased()
    if let maxLength {
      raw = raw.fk_truncated(to: maxLength)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed)
  }

  /// Formats numeric-only input by filtering digits and applying an optional max length.
  func formatNumeric(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    var raw = text.fk_digitsOnly
    if let maxLength {
      raw = raw.fk_truncated(to: maxLength)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }

  /// Formats alphabetic-only input by filtering ASCII letters and applying an optional max length.
  func formatAlphabetic(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    var raw = text.fk_lettersOnly
    if let maxLength {
      raw = raw.fk_truncated(to: maxLength)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }

  /// Formats alphanumeric input by filtering ASCII letters/digits and applying an optional max length.
  func formatAlphaNumeric(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    var raw = text.fk_alphaNumericOnly
    if let maxLength {
      raw = raw.fk_truncated(to: maxLength)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }

  /// Formats input by filtering each character with a regex and applying optional grouping.
  func formatCustom(
    _ text: String,
    regex: String,
    maxLength: Int?,
    separator: Character?,
    groupPattern: [Int],
    removed: Bool
  ) -> FKTextFieldFormattingResult {
    // This predicate is evaluated per-character, so `regex` should match a single character.
    let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
    let raw = text.filter { predicate.evaluate(with: String($0)) }
      .fk_truncated(to: maxLength ?? .max)
    let formatted: String
    if let separator, !groupPattern.isEmpty {
      formatted = raw.fk_grouped(separator: separator, pattern: groupPattern)
    } else {
      formatted = raw
    }
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }
}

