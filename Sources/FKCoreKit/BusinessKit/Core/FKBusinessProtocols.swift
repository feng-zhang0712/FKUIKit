import Foundation
import UIKit

/// Version management capabilities.
public protocol FKBusinessVersioning: AnyObject {
  /// Returns current app metadata derived from `Bundle.main`.
  func appMetadata() -> FKAppMetadata

  /// Checks remote version and returns a decision.
  @available(iOS 13.0, *)
  func checkForUpdate(using provider: FKRemoteVersionProviding) async throws -> FKVersionCheckResult

  /// Callback-style wrapper for ``checkForUpdate(using:)``.
  ///
  /// - Parameters:
  ///   - provider: Remote version provider implementation.
  ///   - completion: Completion callback with success or business error.
  func checkForUpdate(
    using provider: FKRemoteVersionProviding,
    completion: @escaping @Sendable (Result<FKVersionCheckResult, FKBusinessError>) -> Void
  )

  /// Presents an update prompt if needed.
  ///
  /// - Parameters:
  ///   - result: Version check result.
  ///   - presenter: Presenter view controller. When `nil`, uses the current top-most controller.
  func presentUpdatePromptIfNeeded(
    result: FKVersionCheckResult,
    presenter: UIViewController?
  )
}

/// Remote version provider abstraction.
public protocol FKRemoteVersionProviding: AnyObject, Sendable {
  /// Fetches remote version information.
  ///
  /// - Returns: Remote version payload mapped to ``FKRemoteVersionInfo``.
  /// - Throws: A transport or parsing related error.
  @available(iOS 13.0, *)
  func fetchRemoteVersion() async throws -> FKRemoteVersionInfo
}

/// Analytics and tracking capabilities.
public protocol FKBusinessTracking: AnyObject {
  /// Sets a provider to supply additional common parameters for all events.
  ///
  /// - Parameter provider: Optional provider. Pass `nil` to remove current provider.
  func setCommonParametersProvider(_ provider: FKAnalyticsCommonParametersProviding?)

  /// Sets an uploader to deliver batched events.
  ///
  /// - Parameter uploader: Optional uploader. Pass `nil` to disable upload attempts.
  func setUploader(_ uploader: FKAnalyticsUploading?)

  /// Tracks a page exposure event.
  ///
  /// - Parameters:
  ///   - page: Logical page identifier.
  ///   - parameters: Optional event-specific parameters.
  func trackPageView(_ page: String, parameters: [String: String]?)

  /// Tracks a click event.
  ///
  /// - Parameters:
  ///   - element: Clicked element identifier.
  ///   - page: Optional page identifier that contains the element.
  ///   - parameters: Optional event-specific parameters.
  func trackClick(_ element: String, page: String?, parameters: [String: String]?)

  /// Tracks a custom event.
  ///
  /// - Parameters:
  ///   - name: Custom event name.
  ///   - parameters: Optional event-specific parameters.
  func trackEvent(_ name: String, parameters: [String: String]?)

  /// Flushes cached events.
  @available(iOS 13.0, *)
  func flush() async

  /// Callback-style wrapper for ``flush()``.
  ///
  /// - Parameter completion: Called when flush finishes or is skipped.
  func flush(completion: (@Sendable () -> Void)?)
}

/// Supplies additional common parameters for analytics events.
public protocol FKAnalyticsCommonParametersProviding: AnyObject {
  /// Returns extra parameters to be merged into every event.
  func commonParameters() -> [String: String]
}

/// Uploads events in batch.
public protocol FKAnalyticsUploading: AnyObject {
  /// Uploads a batch of events.
  ///
  /// - Parameter batch: Events to upload in one request.
  /// - Throws: A transport error used to trigger retry behavior.
  @available(iOS 13.0, *)
  func upload(batch: [FKAnalyticsEvent]) async throws
}

/// In-app localization capabilities.
public protocol FKBusinessLocalizing: AnyObject {
  /// Currently selected language code.
  var currentLanguageCode: String { get }

  /// Sets the current language code and notifies observers.
  ///
  /// - Parameter code: Language code such as `en`, `zh-Hans`, or `ja`.
  func setLanguageCode(_ code: String)

  /// Resolves a localized string for `key`.
  ///
  /// - Parameters:
  ///   - key: Localization key.
  ///   - table: Optional strings table name. Pass `nil` for `Localizable.strings`.
  /// - Returns: Localized string value or fallback key.
  func localized(_ key: String, table: String?) -> String

  /// Adds an observer that is called when language changes.
  @discardableResult
  func observeLanguageChange(_ handler: @escaping @Sendable (String) -> Void) -> FKBusinessObservationToken
}

/// Application lifecycle observation capabilities.
public protocol FKBusinessLifecycleObserving: AnyObject {
  /// Current app lifecycle state.
  var state: FKAppLifecycleState { get }

  /// Adds an observer that receives state changes.
  @discardableResult
  func observe(_ handler: @escaping @Sendable (FKAppLifecycleState) -> Void) -> FKBusinessObservationToken
}

/// Deeplink and Universal Link routing capabilities.
public protocol FKBusinessDeeplinkRouting: AnyObject {
  /// Registers a route.
  func register(_ route: FKDeeplinkRoute)

  /// Removes a previously registered route.
  func unregister(_ routeID: String)

  /// Attempts to route the URL.
  ///
  /// - Returns: `true` when a route matched and was executed.
  func route(_ url: URL, source: FKDeeplinkSource) -> Bool
}

/// Device and application information capabilities.
public protocol FKBusinessInfoProviding: AnyObject {
  /// Application bundle identifier.
  var bundleID: String { get }

  /// Marketing version (for example `1.2.3`).
  var appVersion: String { get }

  /// Internal build number.
  var buildNumber: String { get }

  /// Operating system version string.
  var systemVersion: String { get }

  /// Hardware model identifier (for example `iPhone16,2`).
  var deviceModelIdentifier: String { get }

  /// Main screen size in points.
  var screenSize: CGSize { get }

  /// Distribution channel label.
  var channel: String { get }

  /// Runtime environment label.
  var environment: FKBusinessEnvironment { get }
}

/// Utilities capabilities.
public protocol FKBusinessUtilitiesProviding: AnyObject {
  /// Time-related business formatting helpers.
  var time: FKBusinessTimeFormatting { get }

  /// Number-related business formatting helpers.
  var number: FKBusinessNumberFormatting { get }

  /// Sensitive-data masking helpers.
  var mask: FKBusinessMasking { get }

  /// Global alert management helper.
  var alerts: FKBusinessAlertManaging { get }

  /// Startup task orchestration helper.
  var startup: FKBusinessStartupTaskManaging { get }
}

/// Time-related helpers.
public protocol FKBusinessTimeFormatting: AnyObject {
  /// Formats date into a fixed display string.
  ///
  /// - Parameters:
  ///   - date: Target date.
  ///   - format: Date format pattern.
  ///   - locale: Optional locale override.
  /// - Returns: Formatted date string.
  func format(date: Date, format: String, locale: Locale?) -> String

  /// Generates a business-friendly relative time description.
  ///
  /// - Parameters:
  ///   - date: Source date.
  ///   - now: Reference date used for relative comparison.
  /// - Returns: Relative time text such as "2m ago" or "Yesterday 19:30".
  func relativeDescription(from date: Date, now: Date) -> String
}

/// Number-related helpers.
public protocol FKBusinessNumberFormatting: AnyObject {
  /// Formats decimal amount with grouped separators and fixed fraction digits.
  ///
  /// - Parameters:
  ///   - value: Decimal amount.
  ///   - fractionDigits: Number of digits after decimal point.
  /// - Returns: Formatted amount string.
  func formatAmount(_ value: Decimal, fractionDigits: Int) -> String

  /// Formats number using compact units.
  ///
  /// - Parameters:
  ///   - value: Input numeric value.
  ///   - fractionDigits: Maximum fraction digits for compact value.
  /// - Returns: Compact string such as `1.2K`, `2.4M`, or `3.5万`.
  func formatCompact(_ value: Double, fractionDigits: Int) -> String
}

/// Common sensitive-data masking helpers.
public protocol FKBusinessMasking: AnyObject {
  /// Masks a mobile phone number.
  ///
  /// - Parameter input: Original phone string.
  /// - Returns: Masked phone string.
  func maskPhone(_ input: String) -> String

  /// Masks an ID card number.
  ///
  /// - Parameter input: Original ID string.
  /// - Returns: Masked ID string.
  func maskIDCard(_ input: String) -> String

  /// Masks an email address.
  ///
  /// - Parameter input: Original email string.
  /// - Returns: Masked email string.
  func maskEmail(_ input: String) -> String

  /// Masks an arbitrary string by preserving prefix and suffix segments.
  ///
  /// - Parameters:
  ///   - input: Original string.
  ///   - keepPrefix: Number of characters to keep at the beginning.
  ///   - keepSuffix: Number of characters to keep at the end.
  ///   - maskCharacter: Character used to replace hidden range.
  /// - Returns: Masked string.
  func mask(_ input: String, keepPrefix: Int, keepSuffix: Int, maskCharacter: Character) -> String
}

/// Global alert presenting and de-duplication.
public protocol FKBusinessAlertManaging: AnyObject {
  /// Presents an alert once for a given identifier.
  ///
  /// - Parameters:
  ///   - id: Stable alert identifier for duplicate suppression.
  ///   - title: Alert title.
  ///   - message: Alert message.
  ///   - actions: Alert action descriptors.
  ///   - presenter: Optional presenter. When `nil`, toolkit resolves top-most controller.
  func presentOnce(
    id: String,
    title: String?,
    message: String?,
    actions: [FKAlertAction],
    presenter: UIViewController?
  )
}

/// App startup task orchestration.
public protocol FKBusinessStartupTaskManaging: AnyObject {
  /// Registers or replaces a startup task by identifier.
  ///
  /// - Parameter task: Startup task descriptor.
  func register(_ task: FKStartupTask)

  /// Runs all registered startup tasks asynchronously.
  @available(iOS 13.0, *)
  func runAll() async

  /// Closure-style wrapper for running all startup tasks.
  ///
  /// - Parameter completion: Called when all startup tasks finish.
  func runAll(completion: (@Sendable () -> Void)?)
}

