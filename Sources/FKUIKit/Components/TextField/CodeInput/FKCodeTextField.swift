import UIKit

/// A native verification-code text field that renders each character in a separate slot.
///
/// This component is a `UITextField` subclass to keep integration simple in large UIKit codebases.
/// It supports:
/// - 4/6 digit codes
/// - box / underline styles
/// - iOS one-time-code AutoFill (`textContentType = .oneTimeCode`)
/// - completion callback and one-tap clear
@MainActor
public final class FKCodeTextField: UITextField {
  /// Slot rendering style.
  public enum SlotStyle: Sendable, Equatable {
    /// Each character is rendered in a bordered box.
    case boxes
    /// Each character is rendered with an underline.
    case underlines
  }

  /// Visual configuration for slots.
  ///
  /// This configuration controls only appearance and sizing behavior. Input filtering remains
  /// numeric-only by design for typical OTP flows.
  public struct Configuration {
    /// Fixed code length.
    ///
    /// Values less than `1` are clamped to `1`.
    public var length: Int
    /// Slot style.
    public var slotStyle: SlotStyle
    /// Horizontal spacing between slots.
    public var slotSpacing: CGFloat
    /// Slot corner radius (boxes only).
    public var cornerRadius: CGFloat
    /// Border width (boxes only).
    public var borderWidth: CGFloat
    /// Border color when not focused.
    public var borderColor: UIColor
    /// Border color for the active slot.
    public var activeBorderColor: UIColor
    /// Border color when in error state.
    public var errorBorderColor: UIColor
    /// Underline height (underlines only).
    public var underlineHeight: CGFloat
    /// Text font.
    public var font: UIFont
    /// Text color.
    public var textColor: UIColor

    /// Creates a configuration.
    public init(
      length: Int = 6,
      slotStyle: SlotStyle = .boxes,
      slotSpacing: CGFloat = 10,
      cornerRadius: CGFloat = 10,
      borderWidth: CGFloat = 1,
      borderColor: UIColor = .separator,
      activeBorderColor: UIColor = .systemBlue,
      errorBorderColor: UIColor = .systemRed,
      underlineHeight: CGFloat = 2,
      font: UIFont = .monospacedDigitSystemFont(ofSize: 18, weight: .semibold),
      textColor: UIColor = .label
    ) {
      self.length = max(1, length)
      self.slotStyle = slotStyle
      self.slotSpacing = max(0, slotSpacing)
      self.cornerRadius = max(0, cornerRadius)
      self.borderWidth = max(0, borderWidth)
      self.borderColor = borderColor
      self.activeBorderColor = activeBorderColor
      self.errorBorderColor = errorBorderColor
      self.underlineHeight = max(1, underlineHeight)
      self.font = font
      self.textColor = textColor
    }
  }

  /// Current configuration.
  ///
  /// Updating this value rebuilds the slot UI and keeps the current code when possible.
  public var codeConfiguration: Configuration {
    didSet { rebuildSlots() }
  }

  /// Code value containing digits only.
  public var code: String { codeState.code }

  /// Called on each code change.
  public var onCodeChanged: ((String) -> Void)?
  /// Called when code input reaches fixed length.
  public var onCodeCompleted: ((String) -> Void)?

  /// Slot container views (one per character).
  private var slotViews: [UIView] = []
  /// Slot label views (one per character).
  private var slotLabels: [UILabel] = []
  /// Underline layers (one per character), used when `slotStyle == .underlines`.
  private var underlineLayers: [CALayer] = []
  /// Internal state storing the canonical code string.
  private var codeState = FKCodeTextFieldState()
  /// Error flag affecting slot border/underline colors.
  private var isShowingError = false

  /// Creates a code input field.
  public init(configuration: Configuration = Configuration()) {
    self.codeConfiguration = configuration
    super.init(frame: .zero)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    self.codeConfiguration = Configuration()
    super.init(coder: coder)
    commonInit()
  }

  /// Clears current code and UI.
  public func clearCode() {
    applyCode("")
  }

  /// Sets an error state (e.g. wrong code) and optionally shakes.
  ///
  /// - Parameters:
  ///   - isError: Whether the field should show an error highlight.
  ///   - shakes: Whether to perform a shake animation when entering error state.
  public func setErrorState(_ isError: Bool, shakes: Bool = true) {
    isShowingError = isError
    updateSlotAppearance()
    if isError, shakes {
      fk_shake()
    }
  }
}

private extension FKCodeTextField {
  /// Applies default UIKit settings and builds the initial slot UI.
  func commonInit() {
    delegate = self
    keyboardType = .numberPad
    textContentType = .oneTimeCode
    autocorrectionType = .no
    spellCheckingType = .no
    smartDashesType = .no
    smartQuotesType = .no
    smartInsertDeleteType = .no

    // Hide the system caret and glyphs; we render characters ourselves.
    tintColor = .clear
    textColor = .clear
    backgroundColor = .clear
    borderStyle = .none

    rebuildSlots()
    addTarget(self, action: #selector(editingChanged), for: .editingChanged)
  }

  /// Recreates all slot views and underline layers based on `codeConfiguration`.
  func rebuildSlots() {
    slotViews.forEach { $0.removeFromSuperview() }
    underlineLayers.forEach { $0.removeFromSuperlayer() }
    slotViews.removeAll()
    slotLabels.removeAll()
    underlineLayers.removeAll()

    // Create slot container + label + underline layer per character.
    for _ in 0..<codeConfiguration.length {
      let slot = UIView()
      slot.isUserInteractionEnabled = false
      slot.backgroundColor = .clear
      addSubview(slot)

      let label = UILabel()
      label.textAlignment = .center
      label.font = codeConfiguration.font
      label.textColor = codeConfiguration.textColor
      label.isUserInteractionEnabled = false
      slot.addSubview(label)

      slotViews.append(slot)
      slotLabels.append(label)

      let underline = CALayer()
      underline.backgroundColor = codeConfiguration.borderColor.cgColor
      slot.layer.addSublayer(underline)
      underlineLayers.append(underline)
    }

    // Re-apply current code and refresh visuals.
    applyCode(codeState.code)
    updateSlotAppearance()
    setNeedsLayout()
    invalidateIntrinsicContentSize()
  }

  /// Updates border/underline styling based on focus, active index, and error state.
  func updateSlotAppearance() {
    let activeIndex = min(codeState.code.count, codeConfiguration.length - 1)

    for i in 0..<slotViews.count {
      let slot = slotViews[i]
      let underline = underlineLayers[i]

      // Consider the next slot active while editing until length is reached.
      let isActive = isFirstResponder && i == activeIndex && codeState.code.count < codeConfiguration.length
      let color = isShowingError ? codeConfiguration.errorBorderColor : (isActive ? codeConfiguration.activeBorderColor : codeConfiguration.borderColor)

      switch codeConfiguration.slotStyle {
      case .boxes:
        slot.layer.cornerRadius = codeConfiguration.cornerRadius
        slot.layer.borderWidth = codeConfiguration.borderWidth
        slot.layer.borderColor = color.cgColor
        underline.isHidden = true
      case .underlines:
        slot.layer.cornerRadius = 0
        slot.layer.borderWidth = 0
        slot.layer.borderColor = UIColor.clear.cgColor
        underline.isHidden = false
        underline.backgroundColor = color.cgColor
      }
    }
  }

  /// Filters and applies a code string to internal state and slot labels.
  ///
  /// - Parameter code: Any string; the implementation keeps digits only and truncates to length.
  func applyCode(_ code: String) {
    // OTP is numeric-only by design.
    let filtered = code.filter(\.isNumber)
    let truncated = String(filtered.prefix(codeConfiguration.length))
    codeState.code = truncated
    text = truncated
    isShowingError = false

    // Render each character into the corresponding slot label.
    for i in 0..<slotLabels.count {
      let label = slotLabels[i]
      if i < truncated.count {
        let ch = truncated[truncated.index(truncated.startIndex, offsetBy: i)]
        label.text = String(ch)
      } else {
        label.text = nil
      }
    }

    updateSlotAppearance()
    onCodeChanged?(truncated)
    if truncated.count == codeConfiguration.length {
      onCodeCompleted?(truncated)
    }
  }

  /// Handles `.editingChanged` events and keeps slot UI in sync with `text`.
  @objc func editingChanged() {
    applyCode(text ?? "")
  }
}

extension FKCodeTextField {
  /// Lays out slot views evenly across the available width.
  public override func layoutSubviews() {
    super.layoutSubviews()
    let count = max(1, codeConfiguration.length)
    let spacing = codeConfiguration.slotSpacing
    let totalSpacing = CGFloat(count - 1) * spacing
    let slotWidth = (bounds.width - totalSpacing) / CGFloat(count)
    let slotHeight = bounds.height

    for i in 0..<slotViews.count {
      let x = CGFloat(i) * (slotWidth + spacing)
      let slotFrame = CGRect(x: x, y: 0, width: slotWidth, height: slotHeight)
      let slot = slotViews[i]
      slot.frame = slotFrame

      let label = slotLabels[i]
      label.frame = slot.bounds

      let underline = underlineLayers[i]
      underline.frame = CGRect(
        x: 0,
        y: slot.bounds.height - codeConfiguration.underlineHeight,
        width: slot.bounds.width,
        height: codeConfiguration.underlineHeight
      )
    }
  }

  public override func caretRect(for position: UITextPosition) -> CGRect {
    .zero
  }

  /// Disables selection rectangles to keep the slot UI consistent.
  public override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
    []
  }

  /// Restricts UIMenu actions to paste only (supports AutoFill and manual paste).
  public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    // Allow paste so one-time-code AutoFill and manual paste work.
    if action == #selector(paste(_:)) { return true }
    return false
  }

  /// Handles paste by extracting digits and applying them as the code value.
  public override func paste(_ sender: Any?) {
    if let pasted = UIPasteboard.general.string {
      applyCode(pasted)
    }
  }
}

extension FKCodeTextField: UITextFieldDelegate {
  /// Intercepts character changes to keep the internal slot UI consistent and avoid cursor handling.
  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let current = textField.text, let r = Range(range, in: current) else { return true }
    let candidate = current.replacingCharacters(in: r, with: string)
    applyCode(candidate)
    return false
  }

  /// Refreshes active slot styling when editing begins.
  public func textFieldDidBeginEditing(_ textField: UITextField) {
    updateSlotAppearance()
  }

  /// Refreshes active slot styling when editing ends.
  public func textFieldDidEndEditing(_ textField: UITextField) {
    updateSlotAppearance()
  }
}

/// Internal state container for `FKCodeTextField`.
private struct FKCodeTextFieldState {
  /// Canonical code value (digits only, truncated to length).
  var code: String = ""
}

