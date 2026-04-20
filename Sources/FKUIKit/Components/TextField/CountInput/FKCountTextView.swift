//
// FKCountTextView.swift
//
// TextView with placeholder + realtime counter + max length enforcement.
//

import UIKit

/// A native `UITextView` subclass with built-in:
/// - placeholder (supports dynamic layout),
/// - realtime character counter,
/// - max length enforcement,
/// - error feedback callback (for UI binding).
///
/// This component is designed for large UIKit codebases where reuse, performance, and
/// predictable behavior are required.
@MainActor
public final class FKCountTextView: UITextView {
  /// Configuration for counting and layout behavior.
  ///
  /// This configuration controls:
  /// - counting and enforcement rules,
  /// - placeholder appearance,
  /// - counter label appearance and positioning.
  public struct Configuration {
    /// Maximum allowed character count. When `nil`, no limit is enforced.
    ///
    /// - Important: Enforcement is performed on the current `text` value and truncates
    ///   overflow content.
    public var maxLength: Int?
    /// Whether counter label is shown.
    public var showsCounter: Bool
    /// Placeholder text.
    public var placeholder: String?
    /// Placeholder font. Defaults to `font` if `nil`.
    public var placeholderFont: UIFont?
    /// Placeholder color.
    public var placeholderColor: UIColor
    /// Counter font.
    public var counterFont: UIFont
    /// Counter color.
    public var counterColor: UIColor
    /// Counter overflow color (when reaching max).
    public var counterOverflowColor: UIColor
    /// Counter bottom padding relative to text container inset.
    public var counterBottomPadding: CGFloat
    /// Counter trailing padding relative to text container inset.
    public var counterTrailingPadding: CGFloat

    /// Creates a configuration.
    public init(
      maxLength: Int? = nil,
      showsCounter: Bool = true,
      placeholder: String? = nil,
      placeholderFont: UIFont? = nil,
      placeholderColor: UIColor = .tertiaryLabel,
      counterFont: UIFont = .preferredFont(forTextStyle: .caption2),
      counterColor: UIColor = .secondaryLabel,
      counterOverflowColor: UIColor = .systemRed,
      counterBottomPadding: CGFloat = 6,
      counterTrailingPadding: CGFloat = 2
    ) {
      self.maxLength = maxLength
      self.showsCounter = showsCounter
      self.placeholder = placeholder
      self.placeholderFont = placeholderFont
      self.placeholderColor = placeholderColor
      self.counterFont = counterFont
      self.counterColor = counterColor
      self.counterOverflowColor = counterOverflowColor
      self.counterBottomPadding = max(0, counterBottomPadding)
      self.counterTrailingPadding = max(0, counterTrailingPadding)
    }
  }

  /// Current configuration.
  ///
  /// Updating this value refreshes placeholder/counter rendering.
  public var countConfiguration: Configuration {
    didSet { applyConfiguration() }
  }

  /// Receives text change updates.
  public var onTextChanged: ((String) -> Void)?
  /// Receives counter updates (current, max).
  public var onCountChanged: ((Int, Int?) -> Void)?
  /// Receives overflow attempts with the rejected text.
  ///
  /// This callback is fired after the text is truncated to `maxLength`.
  public var onOverflowAttempt: ((String) -> Void)?

  /// Forwarding delegate for external behaviors.
  ///
  /// `FKCountTextView` acts as its own delegate to implement counting and enforcement.
  /// Use this property to plug in additional delegate behavior without overriding.
  public weak var forwardingDelegate: UITextViewDelegate?

  /// Placeholder label rendered inside the text container.
  private let placeholderLabel = UILabel()
  /// Counter label rendered near the bottom-right.
  private let counterLabel = UILabel()
  /// Guard flag to avoid recursive updates when mutating `text` programmatically.
  private var isApplyingProgrammaticChange = false

  /// Creates a count text view.
  public init(configuration: Configuration = Configuration()) {
    self.countConfiguration = configuration
    super.init(frame: .zero, textContainer: nil)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    self.countConfiguration = Configuration()
    super.init(coder: coder)
    commonInit()
  }

  /// Removes notification observers.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

private extension FKCountTextView {
  /// Applies default UIKit configuration and installs internal subviews.
  func commonInit() {
    delegate = self
    backgroundColor = .secondarySystemBackground
    layer.cornerRadius = 10
    // Reserve bottom space for the counter label.
    textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 28, right: 12)

    placeholderLabel.numberOfLines = 0
    placeholderLabel.isUserInteractionEnabled = false
    addSubview(placeholderLabel)

    counterLabel.textAlignment = .right
    counterLabel.isUserInteractionEnabled = false
    addSubview(counterLabel)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(textDidChangeNotification),
      name: UITextView.textDidChangeNotification,
      object: self
    )

    applyConfiguration()
    updateUI()
  }

  func applyConfiguration() {
    placeholderLabel.text = countConfiguration.placeholder
    placeholderLabel.textColor = countConfiguration.placeholderColor
    placeholderLabel.font = countConfiguration.placeholderFont ?? font ?? .systemFont(ofSize: 15)

    counterLabel.font = countConfiguration.counterFont
    counterLabel.textColor = countConfiguration.counterColor
    counterLabel.isHidden = !countConfiguration.showsCounter

    setNeedsLayout()
    updateUI()
  }

  /// Enforces `maxLength` by truncating text when needed.
  func enforceMaxLengthIfNeeded() {
    guard let max = countConfiguration.maxLength, max >= 0 else { return }
    guard !isApplyingProgrammaticChange else { return }
    let current = text ?? ""
    guard current.count > max else { return }
    let truncated = String(current.prefix(max))
    isApplyingProgrammaticChange = true
    text = truncated
    isApplyingProgrammaticChange = false
    // Notify overflow and provide a visual hint.
    onOverflowAttempt?(current)
    fk_shake(amplitude: 8, shakes: 3, duration: 0.25)
  }

  /// Updates placeholder visibility, counter text, and triggers callbacks.
  func updateUI() {
    let t = text ?? ""
    placeholderLabel.isHidden = !t.isEmpty

    if countConfiguration.showsCounter {
      let current = t.count
      let max = countConfiguration.maxLength
      if let max, max >= 0 {
        counterLabel.text = "\(current)/\(max)"
        counterLabel.textColor = current >= max ? countConfiguration.counterOverflowColor : countConfiguration.counterColor
      } else {
        counterLabel.text = "\(current)"
        counterLabel.textColor = countConfiguration.counterColor
      }
      onCountChanged?(current, max)
    }

    onTextChanged?(t)
  }

  /// Handles `UITextView.textDidChangeNotification` to centralize enforcement and UI updates.
  @objc func textDidChangeNotification() {
    enforceMaxLengthIfNeeded()
    updateUI()
  }
}

extension FKCountTextView {
  /// Lays out placeholder and counter labels relative to text container inset.
  public override func layoutSubviews() {
    super.layoutSubviews()
    let inset = textContainerInset
    let availableWidth = bounds.width - inset.left - inset.right

    let placeholderSize = placeholderLabel.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
    placeholderLabel.frame = CGRect(
      x: inset.left + 4,
      y: inset.top,
      width: availableWidth - 8,
      height: min(placeholderSize.height, bounds.height - inset.top - inset.bottom)
    )

    counterLabel.frame = CGRect(
      x: inset.left,
      y: bounds.height - inset.bottom + countConfiguration.counterBottomPadding,
      width: availableWidth - countConfiguration.counterTrailingPadding,
      height: 18
    )
  }
}

extension FKCountTextView: UITextViewDelegate {
  /// Forwards `textViewShouldBeginEditing` if provided.
  public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    forwardingDelegate?.textViewShouldBeginEditing?(textView) ?? true
  }

  /// Forwards `textViewDidBeginEditing` if provided.
  public func textViewDidBeginEditing(_ textView: UITextView) {
    forwardingDelegate?.textViewDidBeginEditing?(textView)
  }

  /// Forwards `textViewDidEndEditing` if provided.
  public func textViewDidEndEditing(_ textView: UITextView) {
    forwardingDelegate?.textViewDidEndEditing?(textView)
  }

  /// Forwards `shouldChangeTextIn` decisions and allows local enforcement to happen via notifications.
  public func textView(
    _ textView: UITextView,
    shouldChangeTextIn range: NSRange,
    replacementText text: String
  ) -> Bool {
    if let decision = forwardingDelegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) {
      if decision == false { return false }
    }
    return true
  }
}

