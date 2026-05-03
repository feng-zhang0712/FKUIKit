import UIKit

/// Drives expand/collapse for a read-only, non-scrolling `UITextView` while preserving link taps.
///
/// Toggle taps are implemented with a hidden `fkexpand://` URL on the action substring; your
/// content’s real links are forwarded to ``onLinkTapped`` and to any existing `UITextViewDelegate`.
@MainActor
public final class FKExpandableTextLinkedTextViewController: NSObject {
  public var onExpansionChange: ((FKExpandableTextState) -> Void)?
  /// Invoked for user-visible `URL` links after the internal toggle link is filtered out.
  public var onLinkTapped: ((URL) -> Void)?

  private weak var textView: UITextView?
  private var configuration: FKExpandableTextConfiguration
  private var fullText: NSAttributedString = .init(string: "")
  public private(set) var state: FKExpandableTextState = .collapsed
  private var internalDelegate: UITextViewDelegate?
  private var toggleRange: NSRange = .init(location: NSNotFound, length: 0)

  public init(
    textView: UITextView,
    configuration: FKExpandableTextConfiguration = FKExpandableText.defaultConfiguration
  ) {
    self.textView = textView
    self.configuration = configuration
    super.init()
    setup()
  }

  public func setText(_ text: NSAttributedString) {
    fullText = text
    refreshLayout()
    if textView?.superview == nil {
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

  private func setup() {
    guard let textView else { return }
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.textContainer.lineBreakMode = .byWordWrapping
    textView.adjustsFontForContentSizeCategory = true
    internalDelegate = textView.delegate
    textView.delegate = self
    updateAccessibility()
  }

  private func render() {
    guard let textView else { return }
    textView.window?.layoutIfNeeded()
    let actionCollapsed = configuration.expandActionText
    let actionExpanded = configuration.collapseActionText

    var needsDeferredWidthRefresh = false
    let resultText: NSAttributedString
    switch configuration.collapseRule {
    case .noBodyTruncation:
      if state == .expanded {
        resultText = configuration.oneWayExpand ? fullText : FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionExpanded)
      } else {
        resultText = FKExpandableTextTextBuilder.appendTrailingButtonLine(to: fullText, action: actionCollapsed)
      }
    case let .lines(lineLimit):
      let resolved = FKExpandableTextMeasurementWidth.resolve(for: textView)
      needsDeferredWidthRefresh = resolved.needsDeferredRefresh
      let layoutWidth = resolved.width
      let needsTruncation = FKExpandableTextTextBuilder.doesTextNeedTruncation(
        fullText,
        width: layoutWidth,
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
          width: layoutWidth,
          lineLimit: lineLimit,
          lineBreakMode: textView.textContainer.lineBreakMode,
          token: configuration.truncationToken,
          actionText: actionCollapsed,
          placement: configuration.buttonPlacement
        )
      }
    }

    textView.attributedText = decorateActionText(resultText)
    textView.setNeedsLayout()
    textView.layoutIfNeeded()
    updateAccessibility()

    if needsDeferredWidthRefresh {
      DispatchQueue.main.async { [weak self] in
        guard let self, let textView = self.textView, textView.bounds.width > 1 else { return }
        self.refreshLayout()
      }
    }
  }

  private func decorateActionText(_ text: NSAttributedString) -> NSAttributedString {
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
    textView.isAccessibilityElement = true
    textView.accessibilityHint = configuration.accessibility.hint
    textView.accessibilityLabel = state == .expanded
      ? configuration.accessibility.collapseLabel
      : configuration.accessibility.expandLabel
  }

}

extension FKExpandableTextLinkedTextViewController: UITextViewDelegate {
  public func textView(
    _ textView: UITextView,
    shouldInteractWith URL: URL,
    in characterRange: NSRange,
    interaction: UITextItemInteraction
  ) -> Bool {
    if URL.scheme == "fkexpand" {
      toggle()
      return false
    }

    if configuration.interactionMode == .fullTextArea {
      return true
    }

    if toggleRange.location != NSNotFound, NSIntersectionRange(characterRange, toggleRange).length > 0 {
      toggle()
      return false
    }

    onLinkTapped?(URL)
    return internalDelegate?.textView?(
      textView,
      shouldInteractWith: URL,
      in: characterRange,
      interaction: interaction
    ) ?? true
  }
}
