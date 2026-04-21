import UIKit

/// Global manager for default `FKTextField` configuration.
///
/// Use this singleton to define a design-system baseline once (colors, borders, typography),
/// then create fields with `FKTextField(inputRule:)` or `FKTextField.make(...)` to inherit it.
@MainActor
public final class FKTextFieldManager {
  /// Shared singleton instance.
  public static let shared = FKTextFieldManager()

  /// Global default style.
  ///
  /// This value is copied before mutation when configuring individual fields so local
  /// overrides do not affect the global state.
  public var defaultStyle: FKTextFieldStyle = .default

  /// Creates the singleton instance.
  ///
  /// The initializer is intentionally private to enforce a single source of truth.
  private init() {}

  /// Updates global style in place.
  ///
  /// - Parameter block: Style mutation block.
  public func configureDefaultStyle(_ block: (inout FKTextFieldStyle) -> Void) {
    var style = defaultStyle
    block(&style)
    defaultStyle = style
  }

  /// Restores the global default style.
  public func resetDefaultStyle() {
    defaultStyle = .default
  }
}

