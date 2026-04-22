import UIKit

/// Manages expandable text rendering, interaction, and link forwarding for a `UITextView`.
///
/// This controller keeps integration non-invasive by working with an existing text view instance.
/// It supports rich text, preserves normal link interaction, and is designed for iOS 13.0+
/// component usage scenarios on the main actor.
@MainActor
public final class FKExpandableTextTextViewController: NSObject {
  /// Called whenever the rendered expansion state changes.
  ///
  /// Use this closure to synchronize external UI or state stores with the rendered state.
  public var onStateChanged: ((FKExpandableTextState) -> Void)?
  /// Called when a non-toggle link inside the text view is tapped.
  ///
  /// Toggle links generated internally are handled by the controller and are not forwarded here.
  public var onLinkTapped: ((URL) -> Void)?

  /// The host text view is weak to avoid introducing ownership cycles.
  private weak var textView: UITextView?
  /// Stores the active rendering and interaction configuration.
  private var configuration: FKExpandableTextConfiguration
  /// Keeps the full source text so collapsed and expanded output can be regenerated.
  private var fullText: NSAttributedString = .init(string: "")
  /// Tracks the latest rendered state.
  private(set) var state: FKExpandableTextState = .collapsed
  /// Preserves any external delegate so non-toggle behavior can still be forwarded.
  private var internalDelegate: UITextViewDelegate?
  /// Character range representing the current expand or collapse action.
  private var toggleRange: NSRange = .init(location: NSNotFound, length: 0)

  /// Creates a controller that manages expandable behavior for the specified text view.
  ///
  /// - Parameters:
  ///   - textView: The text view that will render collapsed and expanded content.
  ///   - configuration: Configuration used for truncation, actions, animation, and accessibility.
  ///
  /// The controller updates the provided text view in place and does not require subclassing.
  public init(textView: UITextView, configuration: FKExpandableTextConfiguration = FKExpandableTextGlobalConfiguration.shared) {
    self.textView = textView
    self.configuration = configuration
    super.init()
    setup()
  }

  /// Updates the source text and immediately recalculates the rendered output.
  ///
  /// - Parameter text: The full attributed text that should be displayed by the text view.
  public func setText(_ text: NSAttributedString) {
    fullText = text
    refreshLayout()
  }

  /// Updates the active configuration and rerenders the text view.
  ///
  /// - Parameter configuration: The new configuration to apply to the current instance.
  public func setConfiguration(_ configuration: FKExpandableTextConfiguration) {
    self.configuration = configuration
    refreshLayout()
  }

  /// Toggles between collapsed and expanded states.
  ///
  /// If `oneWayExpand` is enabled, calling this method while expanded has no effect.
  public func toggle() {
    switch state {
    case .collapsed:
      setExpanded(true, animated: true)
    case .expanded:
      guard !configuration.oneWayExpand else { return }
      setExpanded(false, animated: true)
    }
  }

  /// Manually sets the expansion state and rerenders the text view.
  ///
  /// - Parameters:
  ///   - expanded: A Boolean value indicating whether the text view should render expanded content.
  ///   - animated: A Boolean value indicating whether the state change should be animated.
  public func setExpanded(_ expanded: Bool, animated: Bool) {
    state = expanded ? .expanded : .collapsed
    render(animated: animated)
    onStateChanged?(state)
  }

  /// Recomputes the rendered output using the current text, bounds, and configuration.
  ///
  /// Call this when external layout changes affect available width and you need a fresh fit.
  public func refreshLayout() {
    render(animated: false)
  }

  private func setup() {
    guard let textView else { return }
    // Normalize text view defaults so it behaves like a self-sizing rich text container.
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.adjustsFontForContentSizeCategory = true
    internalDelegate = textView.delegate
    textView.delegate = self
    updateAccessibility()
  }

  private func render(animated: Bool) {
    guard let textView else { return }
    // Use current bounds when possible and fall back to screen width before first layout pass.
    let width = textView.bounds.width > 0 ? textView.bounds.width : UIScreen.main.bounds.width
    let actionCollapsed = configuration.expandActionText
    let actionExpanded = configuration.collapseActionText

    // Build the final output based on truncation need and current expansion state.
    let resultText: NSAttributedString
    switch configuration.collapseRule {
    case .noBodyTruncation:
      if state == .expanded {
        resultText = configuration.oneWayExpand ? fullText : FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionExpanded)
      } else {
        resultText = FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionCollapsed)
      }
    case let .lines(lineLimit):
      let needsTruncation = FKExpandableTextTextBuilder.doesTextNeedTruncation(
        fullText,
        width: width,
        lineLimit: lineLimit,
        lineBreakMode: textView.textContainer.lineBreakMode
      )
      if !needsTruncation {
        resultText = fullText
      } else if state == .expanded {
        resultText = configuration.oneWayExpand ? fullText : FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionExpanded)
      } else {
        resultText = FKExpandableTextTextBuilder.buildCollapsedText(
          fullText: fullText,
          width: width,
          lineLimit: lineLimit,
          lineBreakMode: textView.textContainer.lineBreakMode,
          token: configuration.truncationToken,
          actionText: actionCollapsed,
          placement: configuration.buttonPlacement
        )
      }
    }

    // Keep rendering mutations together so they can be executed with or without animation.
    let updates = {
      textView.attributedText = self.decorateActionText(resultText)
      textView.setNeedsLayout()
      textView.layoutIfNeeded()
    }

    if animated {
      animate(textView: textView, updates: updates)
    } else {
      updates()
    }
    updateAccessibility()
  }

  private func decorateActionText(_ text: NSAttributedString) -> NSAttributedString {
    // Add a private link attribute so the toggle action can reuse UITextView link interaction.
    let output = NSMutableAttributedString(attributedString: text)
    let action = state == .expanded ? configuration.collapseActionText : configuration.expandActionText
    let full = output.string as NSString
    let actionRange = full.range(of: action.string, options: .backwards)
    if actionRange.location != NSNotFound {
      toggleRange = actionRange
      output.addAttribute(.link, value: "fkexpand://toggle", range: actionRange)
    } else {
      toggleRange = .init(location: NSNotFound, length: 0)
    }
    return output
  }

  private func updateAccessibility() {
    guard let textView else { return }
    // VoiceOver reflects the next available action for the current state.
    textView.isAccessibilityElement = true
    textView.accessibilityHint = configuration.accessibility.hint
    textView.accessibilityLabel = state == .expanded
      ? configuration.accessibility.collapseLabel
      : configuration.accessibility.expandLabel
  }

  private func animate(textView: UITextView, updates: @escaping () -> Void) {
    // Blend text transition and container layout animation for smoother visual feedback.
    let textTransition: () -> Void = {
      let duration = self.textTransitionDuration
      if duration <= 0 {
        updates()
        return
      }
      UIView.transition(
        with: textView,
        duration: duration,
        options: [.transitionCrossDissolve, .allowUserInteraction, .beginFromCurrentState],
        animations: updates
      )
    }

    // Animate parent layout so height changes feel fluid instead of abrupt.
    let layoutUpdates: () -> Void = {
      if let superview = textView.superview {
        superview.layoutIfNeeded()
      }
    }

    textTransition()

    // Map configuration to the corresponding UIKit animation API for layout movement.
    switch configuration.animation {
    case .none:
      layoutUpdates()
    case let .curve(duration, options):
      UIView.animate(
        withDuration: duration,
        delay: 0,
        options: options.union([.allowUserInteraction, .beginFromCurrentState]),
        animations: layoutUpdates
      )
    case let .spring(duration, dampingRatio, velocity, options):
      UIView.animate(
        withDuration: duration,
        delay: 0,
        usingSpringWithDamping: dampingRatio,
        initialSpringVelocity: velocity,
        options: options.union([.allowUserInteraction, .beginFromCurrentState]),
        animations: layoutUpdates
      )
    }
  }

  private var textTransitionDuration: TimeInterval {
    switch configuration.animation {
    case .none:
      return 0
    case let .curve(duration, _):
      return min(max(duration * 0.65, 0.12), 0.28)
    case let .spring(duration, _, _, _):
      return min(max(duration * 0.55, 0.12), 0.24)
    }
  }
}

extension FKExpandableTextTextViewController: UITextViewDelegate {
  /// Asks the controller whether the specified URL interaction should proceed.
  ///
  /// - Parameters:
  ///   - textView: The text view requesting interaction handling.
  ///   - URL: The URL associated with the tapped range.
  ///   - characterRange: The character range for the interaction.
  ///   - interaction: The interaction type requested by the system.
  /// - Returns: `false` when the controller consumes the interaction, otherwise the forwarded result.
  ///
  /// Internal toggle links are consumed by the controller. Other links are forwarded to
  /// `onLinkTapped` and, when available, the original delegate.
  public func textView(
    _ textView: UITextView,
    shouldInteractWith URL: URL,
    in characterRange: NSRange,
    interaction: UITextItemInteraction
  ) -> Bool {
    if URL.scheme == "fkexpand" {
      // Consume the synthetic toggle link and switch state locally.
      toggle()
      return false
    }

    if configuration.interactionMode == .fullTextArea {
      // In full-area mode, non-toggle links should behave like a normal text view.
      return true
    }

    if toggleRange.location != NSNotFound, NSIntersectionRange(characterRange, toggleRange).length > 0 {
      // Prevent the toggle action from being treated as a normal outgoing link.
      toggle()
      return false
    }

    // Notify the caller and preserve any original delegate behavior when possible.
    onLinkTapped?(URL)
    return internalDelegate?.textView?(
      textView,
      shouldInteractWith: URL,
      in: characterRange,
      interaction: interaction
    ) ?? true
  }
}
