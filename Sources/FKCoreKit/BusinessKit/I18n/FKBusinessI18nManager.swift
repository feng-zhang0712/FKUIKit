import Foundation

/// Default implementation of ``FKBusinessLocalizing``.
public final class FKBusinessI18nManager: FKBusinessLocalizing, @unchecked Sendable {
  /// Notification posted after language is changed.
  public static let languageDidChangeNotification = Notification.Name("com.fkkit.business.i18n.languageDidChange")

  /// Lock protecting mutable language state and observer list.
  private let lock = NSLock()
  /// Storage backend for persisted language code.
  private let userDefaults: UserDefaults
  /// UserDefaults key for persisted language code.
  private let storageKey: String
  /// Fallback language code used on first launch.
  private let defaultLanguageCode: String
  /// Current selected language code.
  private var _languageCode: String
  /// Registered language change observers.
  private var observers: [UUID: @Sendable (String) -> Void] = [:]

  /// Creates a manager with an optional custom `UserDefaults`.
  ///
  /// - Parameters:
  ///   - defaultLanguageCode: Fallback language code when no user selection exists.
  ///   - userDefaults: Storage for selected language.
  ///   - storageKey: Key used to persist language code.
  public init(
    defaultLanguageCode: String,
    userDefaults: UserDefaults = .standard,
    storageKey: String = "com.fkkit.business.i18n.language"
  ) {
    self.defaultLanguageCode = defaultLanguageCode
    self.userDefaults = userDefaults
    self.storageKey = storageKey
    self._languageCode = userDefaults.string(forKey: storageKey) ?? defaultLanguageCode
  }

  /// Current selected language code.
  public var currentLanguageCode: String {
    lock.lock()
    let value = _languageCode
    lock.unlock()
    return value
  }

  /// Updates current language and notifies all observers.
  ///
  /// - Parameter code: New language code.
  public func setLanguageCode(_ code: String) {
    lock.lock()
    guard _languageCode != code, !code.isEmpty else {
      lock.unlock()
      return
    }
    _languageCode = code
    userDefaults.set(code, forKey: storageKey)
    let handlers = observers.values
    lock.unlock()

    NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: code)
    handlers.forEach { $0(code) }
  }

  /// Resolves localized text from selected language bundle.
  ///
  /// - Parameters:
  ///   - key: Localization key.
  ///   - table: Optional strings table.
  /// - Returns: Localized value or key fallback.
  public func localized(_ key: String, table: String? = nil) -> String {
    let code = currentLanguageCode
    let bundle = Self.bundle(for: code) ?? .main
    return bundle.localizedString(forKey: key, value: nil, table: table)
  }

  /// Adds language change observer and emits current language immediately.
  ///
  /// - Parameter handler: Callback invoked on language updates.
  /// - Returns: Observation token for cancellation.
  @discardableResult
  public func observeLanguageChange(_ handler: @escaping @Sendable (String) -> Void) -> FKBusinessObservationToken {
    let id = UUID()
    lock.lock()
    observers[id] = handler
    let current = _languageCode
    lock.unlock()

    handler(current)

    return FKBusinessObservationToken { [weak self] in
      guard let self else { return }
      self.lock.lock()
      self.observers[id] = nil
      self.lock.unlock()
    }
  }

  /// Locates language-specific bundle under main bundle.
  ///
  /// - Parameter languageCode: Language code such as `en` or `zh-Hans`.
  /// - Returns: Matching localization bundle or `nil`.
  private static func bundle(for languageCode: String) -> Bundle? {
    guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") else { return nil }
    return Bundle(path: path)
  }
}

