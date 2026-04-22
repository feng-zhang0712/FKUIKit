import SwiftUI
import UIKit

/// SwiftUI wrapper for `FKExpandableText` with rich text, link handling, and expansion binding.
///
/// This type bridges the UIKit implementation into SwiftUI through `UIViewRepresentable`, keeping
/// feature behavior aligned across frameworks while remaining non-invasive to existing data flow.
/// The wrapped implementation is compatible with iOS 13.0+ component usage scenarios.
@available(iOS 13.0, *)
@MainActor
public struct FKExpandableTextView: UIViewRepresentable {
  /// Full attributed text content rendered by the wrapped text view.
  public var text: NSAttributedString
  /// Configuration override used for truncation, actions, and animation.
  public var configuration: FKExpandableTextConfiguration
  /// Binding that synchronizes the expanded state with SwiftUI.
  @Binding public var isExpanded: Bool
  /// Closure called when the expansion state changes.
  public var onStateChanged: ((FKExpandableTextState) -> Void)?
  /// Closure called when a non-toggle link is tapped.
  public var onLinkTapped: ((URL) -> Void)?

  /// Creates a SwiftUI wrapper around `FKExpandableText`.
  ///
  /// - Parameters:
  ///   - text: Full attributed text content rendered by the underlying text view.
  ///   - configuration: Configuration override used for truncation, actions, and animation.
  ///   - isExpanded: Binding used to read and write the current expansion state.
  ///   - onStateChanged: Closure called when the rendered expansion state changes.
  ///   - onLinkTapped: Closure called when a non-toggle link is tapped.
  public init(
    text: NSAttributedString,
    configuration: FKExpandableTextConfiguration = FKExpandableTextGlobalConfiguration.shared,
    isExpanded: Binding<Bool> = .constant(false),
    onStateChanged: ((FKExpandableTextState) -> Void)? = nil,
    onLinkTapped: ((URL) -> Void)? = nil
  ) {
    self.text = text
    self.configuration = configuration
    _isExpanded = isExpanded
    self.onStateChanged = onStateChanged
    self.onLinkTapped = onLinkTapped
  }

  /// Creates the UIKit view used by SwiftUI for rendering.
  ///
  /// - Parameter context: Context containing the SwiftUI coordinator and environment values.
  /// - Returns: A configured `UITextView` instance that hosts expandable text behavior.
  public func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.backgroundColor = .clear
    context.coordinator.bind(to: textView)
    return textView
  }

  /// Updates the wrapped UIKit view to match the current SwiftUI state.
  ///
  /// - Parameters:
  ///   - uiView: The `UITextView` previously created by `makeUIView(context:)`.
  ///   - context: Context containing the SwiftUI coordinator and environment values.
  public func updateUIView(_: UITextView, context: Context) {
    context.coordinator.configuration = configuration
    context.coordinator.onStateChanged = onStateChanged
    context.coordinator.onLinkTapped = onLinkTapped
    context.coordinator.setText(text)
    context.coordinator.setExpanded(isExpanded, animated: false)
  }

  /// Creates the coordinator used to bridge UIKit callbacks back into SwiftUI.
  ///
  /// - Returns: A coordinator that owns the underlying text view controller integration.
  public func makeCoordinator() -> Coordinator {
    Coordinator(
      configuration: configuration,
      onStateChanged: onStateChanged,
      onLinkTapped: onLinkTapped
    ) { newState in
      isExpanded = (newState == .expanded)
    }
  }
}

@available(iOS 13.0, *)
public extension FKExpandableTextView {
  /// Coordinator that bridges `FKExpandableTextTextViewController` callbacks into SwiftUI.
  @MainActor
  final class Coordinator {
    /// Current configuration mirrored from the SwiftUI wrapper.
    var configuration: FKExpandableTextConfiguration
    /// Closure called when the expansion state changes.
    var onStateChanged: ((FKExpandableTextState) -> Void)?
    /// Closure called when a non-toggle link is tapped.
    var onLinkTapped: ((URL) -> Void)?

    /// Weak reference to the hosted text view for completeness and future coordination needs.
    private weak var textView: UITextView?
    /// Controller that performs the actual expandable text behavior.
    private var controller: FKExpandableTextTextViewController?
    /// Writes controller-driven state changes back into the SwiftUI binding.
    private let updateExpansionBinding: (FKExpandableTextState) -> Void

    /// Creates a coordinator for the SwiftUI wrapper.
    ///
    /// - Parameters:
    ///   - configuration: Initial configuration mirrored from the SwiftUI wrapper.
    ///   - onStateChanged: Initial state change callback.
    ///   - onLinkTapped: Initial link tap callback.
    ///   - updateExpansionBinding: Closure used to write state changes back to SwiftUI.
    init(
      configuration: FKExpandableTextConfiguration,
      onStateChanged: ((FKExpandableTextState) -> Void)?,
      onLinkTapped: ((URL) -> Void)?,
      updateExpansionBinding: @escaping (FKExpandableTextState) -> Void
    ) {
      self.configuration = configuration
      self.onStateChanged = onStateChanged
      self.onLinkTapped = onLinkTapped
      self.updateExpansionBinding = updateExpansionBinding
    }

    /// Binds the coordinator to the specified text view and creates the UIKit controller.
    ///
    /// - Parameter textView: The hosted UIKit text view created by SwiftUI.
    func bind(to textView: UITextView) {
      self.textView = textView
      let controller = FKExpandableTextTextViewController(textView: textView, configuration: configuration)
      controller.onLinkTapped = { [weak self] url in
        self?.onLinkTapped?(url)
      }
      controller.onStateChanged = { [weak self] state in
        self?.updateExpansionBinding(state)
        self?.onStateChanged?(state)
      }
      self.controller = controller
    }

    /// Updates the underlying controller with a new source text value.
    ///
    /// - Parameter text: The full attributed text to render.
    func setText(_ text: NSAttributedString) {
      controller?.setConfiguration(configuration)
      controller?.setText(text)
    }

    /// Updates the rendered expansion state.
    ///
    /// - Parameters:
    ///   - isExpanded: A Boolean value indicating whether the content should be expanded.
    ///   - animated: A Boolean value indicating whether the state change should be animated.
    func setExpanded(_ isExpanded: Bool, animated: Bool) {
      controller?.setExpanded(isExpanded, animated: animated)
    }
  }
}
