import UIKit

/// Manages expandable text rendering and interaction for a `UILabel`.
///
/// This controller keeps integration non-invasive by operating on an existing label instance.
/// It recalculates truncation when content or configuration changes and is intended for iOS 13.0+
/// component usage scenarios on the main actor.
@MainActor
public final class FKExpandableTextLabelController: NSObject {
  /// Called whenever the rendered expansion state changes.
  ///
  /// Use this closure to synchronize surrounding UI, analytics, or view model state.
  public var onStateChanged: ((FKExpandableTextState) -> Void)?

  /// The host label is weak to avoid introducing ownership cycles.
  private weak var label: UILabel?
  /// Stores the active rendering and interaction configuration.
  private var configuration: FKExpandableTextConfiguration
  /// Keeps the full source text so collapsed and expanded output can be regenerated.
  private var fullText: NSAttributedString = .init(string: "")
  /// Tracks the latest rendered state.
  private(set) var state: FKExpandableTextState = .collapsed
  /// Tap gesture used for button-only or whole-area interaction.
  private var tapGesture: UITapGestureRecognizer?
  /// Stores the most recently rendered text assigned to the label.
  private var renderedText: NSAttributedString = .init(string: "")
  /// Character range representing the current expand or collapse action.
  private var toggleRange: NSRange = .init(location: NSNotFound, length: 0)

  /// Creates a controller that manages expandable behavior for the specified label.
  ///
  /// - Parameters:
  ///   - label: The label that will render collapsed and expanded text.
  ///   - configuration: Configuration used for truncation, actions, animation, and accessibility.
  ///
  /// The controller updates the provided label in place and does not require subclassing.
  public init(label: UILabel, configuration: FKExpandableTextConfiguration = FKExpandableTextGlobalConfiguration.shared) {
    self.label = label
    self.configuration = configuration
    super.init()
    setup()
  }

  /// Updates the source text and immediately recalculates the rendered output.
  ///
  /// - Parameter text: The full attributed text that should be displayed by the label.
  public func setText(_ text: NSAttributedString) {
    fullText = text
    refreshLayout()
  }

  /// Updates the active configuration and rerenders the label.
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

  /// Manually sets the expansion state and rerenders the label.
  ///
  /// - Parameters:
  ///   - expanded: A Boolean value indicating whether the label should render expanded content.
  ///   - animated: A Boolean value indicating whether the state change should be animated.
  public func setExpanded(_ expanded: Bool, animated: Bool) {
    state = expanded ? .expanded : .collapsed
    render(animated: false)
    onStateChanged?(state)
  }

  /// Recomputes the rendered output using the current text, bounds, and configuration.
  ///
  /// Call this when external layout changes affect available width and you need a fresh fit.
  public func refreshLayout() {
    render(animated: false)
  }

  @objc
  private func handleTap(_ recognizer: UITapGestureRecognizer) {
    // Whole-area mode accepts any tap; button-only mode validates the action range hit.
    guard configuration.interactionMode == .fullTextArea || isTapInsideToggleRange(recognizer) else {
      return
    }
    toggle()
  }

  private func setup() {
    guard let label else { return }
    // The controller owns interaction behavior and normalizes label defaults accordingly.
    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    label.isUserInteractionEnabled = true
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    label.addGestureRecognizer(tap)
    tapGesture = tap
    updateAccessibility()
  }

  private func render(animated: Bool) {
    guard let label else { return }
    // Use current bounds when possible and fall back to screen width before first layout pass.
    let width = label.bounds.width > 0 ? label.bounds.width : UIScreen.main.bounds.width

    let actionCollapsed = configuration.expandActionText
    let actionExpanded = configuration.collapseActionText

    // Build the final output based on truncation need and current expansion state.
    let targetText: NSAttributedString
    switch configuration.collapseRule {
    case .noBodyTruncation:
      if state == .expanded {
        targetText = configuration.oneWayExpand ? fullText : FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionExpanded)
      } else {
        targetText = FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionCollapsed)
      }
    case let .lines(lineLimit):
      let needsTruncation = FKExpandableTextTextBuilder.doesTextNeedTruncation(
        fullText,
        width: width,
        lineLimit: lineLimit,
        lineBreakMode: label.lineBreakMode
      )
      if !needsTruncation {
        targetText = fullText
      } else if state == .expanded {
        targetText = configuration.oneWayExpand ? fullText : FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionExpanded)
      } else {
        targetText = FKExpandableTextTextBuilder.buildCollapsedText(
          fullText: fullText,
          width: width,
          lineLimit: lineLimit,
          lineBreakMode: label.lineBreakMode,
          token: configuration.truncationToken,
          actionText: actionCollapsed,
          placement: configuration.buttonPlacement
        )
      }
    }

    // Keep rendering mutations together so they can be executed with or without animation.
    let updates = {
      self.renderedText = targetText
      label.attributedText = targetText
      label.setNeedsLayout()
      label.layoutIfNeeded()
    }

    if animated {
      animate(label: label, updates: updates)
    } else {
      updates()
    }
    updateToggleRange()
    updateAccessibility()
  }

  private func updateToggleRange() {
    // The action text range is resolved from the final rendered output rather than source text.
    tapGesture?.isEnabled = true
    let action = state == .expanded ? configuration.collapseActionText : configuration.expandActionText
    let full = renderedText.string as NSString
    toggleRange = full.range(of: action.string, options: .backwards)
  }

  private func isTapInsideToggleRange(_ recognizer: UITapGestureRecognizer) -> Bool {
    guard
      let label,
      toggleRange.location != NSNotFound,
      renderedText.length > 0
    else {
      return false
    }

    // Reconstruct a lightweight Text Kit stack to map the touch point to a glyph index.
    let manager = NSLayoutManager()
    let container = NSTextContainer(size: label.bounds.size)
    container.lineFragmentPadding = 0
    container.maximumNumberOfLines = label.numberOfLines
    container.lineBreakMode = label.lineBreakMode
    manager.addTextContainer(container)
    let storage = NSTextStorage(attributedString: renderedText)
    storage.addLayoutManager(manager)

    let point = recognizer.location(in: label)
    let glyphIndex = manager.glyphIndex(for: point, in: container)
    return NSLocationInRange(glyphIndex, toggleRange)
  }

  private func updateAccessibility() {
    guard let label else { return }
    // VoiceOver reflects the next available action for the current state.
    label.isAccessibilityElement = true
    label.accessibilityHint = configuration.accessibility.hint
    label.accessibilityLabel = state == .expanded
      ? configuration.accessibility.collapseLabel
      : configuration.accessibility.expandLabel
  }

  private func animate(label: UILabel, updates: @escaping () -> Void) {
    // Blend text transition and container layout animation for smoother visual feedback.
    let textTransition: () -> Void = {
      let duration = self.textTransitionDuration
      if duration <= 0 {
        updates()
        return
      }
      UIView.transition(
        with: label,
        duration: duration,
        options: [.transitionCrossDissolve, .allowUserInteraction, .beginFromCurrentState],
        animations: updates
      )
    }

    // Animate parent layout so height changes feel fluid instead of abrupt.
    let layoutUpdates: () -> Void = {
      if let superview = label.superview {
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
