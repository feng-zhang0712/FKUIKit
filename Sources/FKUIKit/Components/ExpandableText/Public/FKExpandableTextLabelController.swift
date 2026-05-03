import UIKit

/// Drives expand/collapse rendering and taps for a `UILabel`.
///
/// The label is held weakly. Call ``refreshLayout()`` after width changes before the next layout pass
/// if you need an accurate truncation fit.
@MainActor
public final class FKExpandableTextLabelController: NSObject {
  /// Fires whenever ``state`` changes after a user or programmatic update.
  public var onExpansionChange: ((FKExpandableTextState) -> Void)?

  private weak var label: UILabel?
  private var configuration: FKExpandableTextConfiguration
  private var fullText: NSAttributedString = .init(string: "")
  public private(set) var state: FKExpandableTextState = .collapsed
  private var tapGesture: UITapGestureRecognizer?
  private var renderedText: NSAttributedString = .init(string: "")
  private var toggleRange: NSRange = .init(location: NSNotFound, length: 0)

  public init(
    label: UILabel,
    configuration: FKExpandableTextConfiguration = FKExpandableText.defaultConfiguration
  ) {
    self.label = label
    self.configuration = configuration
    super.init()
    setup()
  }

  /// Replaces the logical full source string and recomputes the displayed `attributedText`.
  public func setText(_ text: NSAttributedString) {
    fullText = text
    refreshLayout()
    // If the label is not in a window yet, the first pass cannot measure width; refresh again next turn.
    if label?.superview == nil {
      DispatchQueue.main.async { [weak self] in
        self?.refreshLayout()
      }
    }
  }

  public func setConfiguration(_ configuration: FKExpandableTextConfiguration) {
    self.configuration = configuration
    refreshLayout()
  }

  public func toggle() {
    switch state {
    case .collapsed:
      setExpanded(true, animated: true)
    case .expanded:
      guard !configuration.oneWayExpand else { return }
      setExpanded(false, animated: true)
    }
  }

  /// - Parameter animated: Reserved for API compatibility; layout is always applied synchronously.
  public func setExpanded(_ expanded: Bool, animated: Bool) {
    state = expanded ? .expanded : .collapsed
    render()
    onExpansionChange?(state)
  }

  public func refreshLayout() {
    render()
  }

  @objc
  private func handleTap(_ recognizer: UITapGestureRecognizer) {
    guard configuration.interactionMode == .fullTextArea || isTapInsideToggleRange(recognizer) else {
      return
    }
    toggle()
  }

  private func setup() {
    guard let label else { return }
    label.numberOfLines = 0
    // Multiline line-budget math must match word-wrapped layout; UILabel defaults to tail truncation.
    label.lineBreakMode = .byWordWrapping
    label.adjustsFontForContentSizeCategory = true
    label.isUserInteractionEnabled = true
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    label.addGestureRecognizer(tap)
    tapGesture = tap
    updateAccessibility()
  }

  private func render() {
    guard let label else { return }
    label.window?.layoutIfNeeded()

    let actionCollapsed = configuration.expandActionText
    let actionExpanded = configuration.collapseActionText

    var needsDeferredWidthRefresh = false
    let targetText: NSAttributedString
    switch configuration.collapseRule {
    case .noBodyTruncation:
      if state == .expanded {
        targetText = configuration.oneWayExpand ? fullText : FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionExpanded)
      } else {
        targetText = FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionCollapsed)
      }
    case let .lines(lineLimit):
      let resolved = FKExpandableTextMeasurementWidth.resolve(for: label)
      needsDeferredWidthRefresh = resolved.needsDeferredRefresh
      let layoutWidth = resolved.width
      let needsTruncation = FKExpandableTextTextBuilder.doesTextNeedTruncation(
        fullText,
        width: layoutWidth,
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
          width: layoutWidth,
          lineLimit: lineLimit,
          lineBreakMode: label.lineBreakMode,
          token: configuration.truncationToken,
          actionText: actionCollapsed,
          placement: configuration.buttonPlacement
        )
      }
    }

    renderedText = targetText
    label.attributedText = targetText
    label.setNeedsLayout()
    label.layoutIfNeeded()
    updateToggleRange()
    updateAccessibility()

    if needsDeferredWidthRefresh {
      DispatchQueue.main.async { [weak self] in
        guard let self, let label = self.label, label.bounds.width > 1 else { return }
        self.refreshLayout()
      }
    }
  }

  private func updateToggleRange() {
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
    label.isAccessibilityElement = true
    label.accessibilityHint = configuration.accessibility.hint
    label.accessibilityLabel = state == .expanded
      ? configuration.accessibility.collapseLabel
      : configuration.accessibility.expandLabel
  }

}
