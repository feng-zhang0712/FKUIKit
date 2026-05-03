import UIKit

extension FKButton {
  // MARK: - Accessibility (a11y)

  func applyAccessibilityForCurrentState() {
    // Traits: keep `.button` always; add `.selected` and `.updatesFrequently` while loading.
    var traits: UIAccessibilityTraits = [.button]
    if isSelected { traits.insert(.selected) }
    if isLoading { traits.insert(.updatesFrequently) }
    accessibilityTraits = traits

    accessibilityLabel = accessibilityConfiguration.labelProvider?(self) ?? defaultAccessibilityLabel()
    accessibilityValue = accessibilityConfiguration.valueProvider?(self) ?? defaultAccessibilityValue()
    accessibilityHint = accessibilityConfiguration.hintProvider?(self) ?? defaultAccessibilityHint()
  }

  func defaultAccessibilityLabel() -> String? {
    // Strategy:
    // - Keep the semantic "title" as `accessibilityLabel` (stable meaning).
    // - Put subtitle / loading text into `accessibilityValue`.
    switch content.kind {
    case .textOnly, .textAndImage:
      let title = resolveTitleElement()
      if let explicit = title.accessibilityLabel { return explicit }
      if let attributed = title.attributedText { return attributed.string }
      if let text = title.text, !text.isEmpty { return transformedText(from: text, by: title.textTransform) }
      return nil
    case .imageOnly:
      return activeImageElements().first?.accessibilityLabel
    case .custom:
      return resolveCustomContent()?.view?.accessibilityLabel
    }
  }

  func defaultAccessibilityValue() -> String? {
    // Prefer loading message while loading; otherwise use subtitle when present.
    if isLoading {
      switch loadingPresentationStyle {
      case .overlay:
        return "Loading"
      case .replacesContent(let options):
        let trimmed = options.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Loading" : trimmed
      }
    }

    switch content.kind {
    case .textOnly, .textAndImage:
      guard let subtitle = resolveSubtitleElement(), subtitleHasRenderableContent(subtitle) else { return nil }
      if let attributed = subtitle.attributedText { return attributed.string }
      if let text = subtitle.text, !text.isEmpty { return transformedText(from: text, by: subtitle.textTransform) }
      return nil
    case .imageOnly, .custom:
      return nil
    }
  }

  func defaultAccessibilityHint() -> String? {
    switch content.kind {
    case .textOnly, .textAndImage:
      return resolveTitleElement().accessibilityHint
    case .imageOnly:
      return activeImageElements().first?.accessibilityHint
    case .custom:
      return resolveCustomContent()?.view?.accessibilityHint
    }
  }
}
