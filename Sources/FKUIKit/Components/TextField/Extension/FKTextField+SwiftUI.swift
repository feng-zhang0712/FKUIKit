import UIKit
#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI wrapper for `FKTextField`.
///
/// This bridge keeps UIKit formatter/validator behavior unchanged while exposing binding-based
/// integration for SwiftUI screens.
@available(iOS 15.0, *)
public struct FKTextFieldRepresentable: UIViewRepresentable {
  /// Bound raw text value.
  @Binding public var rawText: String
  /// Text field configuration.
  public var configuration: FKTextFieldConfiguration
  /// Optional async validator.
  public var asyncValidator: FKTextFieldAsyncValidating?

  /// Creates a SwiftUI representable.
  public init(
    rawText: Binding<String>,
    configuration: FKTextFieldConfiguration,
    asyncValidator: FKTextFieldAsyncValidating? = nil
  ) {
    _rawText = rawText
    self.configuration = configuration
    self.asyncValidator = asyncValidator
  }

  public func makeUIView(context: Context) -> FKTextField {
    let binding = _rawText
    let view = FKTextField(
      configuration: configuration,
      formatter: FKTextFieldDefaultFormatter(),
      validator: FKTextFieldDefaultValidator(),
      asyncValidator: asyncValidator
    )
    view.onEditingChanged = { raw, _ in
      if binding.wrappedValue != raw {
        binding.wrappedValue = raw
      }
    }
    return view
  }

  public func updateUIView(_ uiView: FKTextField, context _: Context) {
    uiView.configure(configuration)
    if uiView.rawText != rawText {
      uiView.text = rawText
      uiView.sendActions(for: .editingChanged)
    }
  }
}
#endif

