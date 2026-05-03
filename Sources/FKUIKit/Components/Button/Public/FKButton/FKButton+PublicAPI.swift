import UIKit

extension FKButton {
  // MARK: - Public API — State models

  /// Registers a state model for an exact `UIControl.State` key.
  ///
  /// - Important: The lookup supports combined states such as `.selected.union(.highlighted)`.
  ///   Configure these combinations to customize pressed-selected visuals.
  /// - Note: For a non-`nil` `model`, this API is intentionally *partial*: fields omitted in `model`
  ///   keep previously registered values for the same `state` (including image slots when `images` is omitted).
  /// - Note: Pass `nil` for `model` to remove **all** registrations for this exact `state` key (appearance,
  ///   title, subtitle, every image slot, and custom content), restoring resolution to fallbacks such as `.normal`.
  public func setModel(_ model: FKButtonStateModel?, for state: UIControl.State) {
    performBatchUpdates {
      guard let model else {
        clearRegisteredContent(forExactState: state)
        return
      }
      if let appearance = model.appearance {
        setAppearance(appearance, for: state)
      }
      setLabel(model.title, role: .title, for: state)
      setLabel(model.subtitle, role: .subtitle, for: state)
      if let images = model.images {
        for (slot, img) in images {
          storeImage(img, slot: slot, for: state)
        }
      }
      setCustomContent(model.customContent, for: state)
    }
  }

  /// Removes appearance, title, subtitle, all image slots, and custom content registered for this exact state key.
  func clearRegisteredContent(forExactState state: UIControl.State) {
    let key = Self.makeStateKey(state)
    appearanceByState.removeValue(forKey: key)
    titleByState.removeValue(forKey: key)
    subtitleByState.removeValue(forKey: key)
    customContentByState.removeValue(forKey: key)
    for slot in [ImageSlot.center, .leading, .trailing] {
      guard var map = imagesBySlotAndState[slot] else { continue }
      map.removeValue(forKey: key)
      if map.isEmpty {
        imagesBySlotAndState.removeValue(forKey: slot)
      } else {
        imagesBySlotAndState[slot] = map
      }
    }
    requestVisualRefresh()
  }

  /// Registers a label configuration for an exact state key.
  ///
  /// Use `role: .title` for the primary text line and `role: .subtitle` for secondary text.
  /// In the default accessibility strategy, title maps to `accessibilityLabel` and subtitle maps to `accessibilityValue`.
  public func setLabel(_ configuration: LabelAttributes?, role: LabelRole, for state: UIControl.State) {
    let key = Self.makeStateKey(state)
    switch role {
    case .title:
      if let configuration {
        titleByState[key] = configuration
      } else {
        titleByState.removeValue(forKey: key)
      }
    case .subtitle:
      if let configuration {
        subtitleByState[key] = configuration
      } else {
        subtitleByState.removeValue(forKey: key)
      }
    }
    requestVisualRefresh()
  }

  /// Reads the registered label configuration for an exact state key.
  public func label(role: LabelRole, for state: UIControl.State) -> LabelAttributes? {
    let key = Self.makeStateKey(state)
    switch role {
    case .title: return titleByState[key]
    case .subtitle: return subtitleByState[key]
    }
  }

  /// Registers an image configuration for an exact state key and slot.
  ///
  /// Prefer the slot conveniences (`setCenterImage`, `setLeadingImage`, `setTrailingImage`) in app code
  /// for readability; use this method when slot is selected dynamically.
  public func setImage(_ image: ImageAttributes?, slot: ImageSlot, for state: UIControl.State) {
    storeImage(image, slot: slot, for: state)
    requestVisualRefresh()
  }

  /// Reads the registered image configuration for an exact state key and slot.
  public func image(slot: ImageSlot, for state: UIControl.State) -> ImageAttributes? {
    imagesBySlotAndState[slot]?[Self.makeStateKey(state)]
  }

  // MARK: - Public API — Appearance

  /// Register an appearance for the given state.
  /// If the current state matches, it is applied immediately.
  ///
  /// For global theming in multilingual apps, keep content colors and contrast WCAG-friendly in every state.
  public func setAppearance(_ appearance: Appearance, for state: UIControl.State) {
    appearanceByState[Self.makeStateKey(state)] = appearance
    requestVisualRefresh()
  }
  
  /// Reads the registered appearance for an exact state key.
  public func appearance(for state: UIControl.State) -> Appearance? {
    appearanceByState[Self.makeStateKey(state)]
  }

  /// Apply an appearance bundle for normal/selected/highlighted/disabled.
  public func setAppearances(_ appearances: StateAppearances) {
    performBatchUpdates {
      setAppearance(appearances.normal, for: .normal)
      setAppearance(appearances.selected, for: .selected)
      setAppearance(appearances.highlighted, for: .highlighted)
      setAppearance(appearances.disabled, for: .disabled)
    }
  }

  /// Applies multiple stateful updates and refreshes rendering once.
  ///
  /// This helps avoid transient intermediate visuals while multiple state entries are updated.
  public func performBatchUpdates(_ updates: () -> Void) {
    batchUpdateDepth += 1
    updates()
    batchUpdateDepth -= 1
    if batchUpdateDepth == 0, needsVisualRefresh {
      needsVisualRefresh = false
      flushPendingRefresh()
    }
  }
  
  // MARK: - Public API — Title & subtitle role conveniences

  /// Registers title attributes for an exact state key.
  public func setTitle(_ configuration: LabelAttributes?, for state: UIControl.State) {
    setLabel(configuration, role: .title, for: state)
  }

  /// Reads title attributes for an exact state key.
  public func title(for state: UIControl.State) -> LabelAttributes? {
    label(role: .title, for: state)
  }

  /// Registers subtitle attributes for an exact state key.
  public func setSubtitle(_ configuration: LabelAttributes?, for state: UIControl.State) {
    setLabel(configuration, role: .subtitle, for: state)
  }

  /// Reads subtitle attributes for an exact state key.
  public func subtitle(for state: UIControl.State) -> LabelAttributes? {
    label(role: .subtitle, for: state)
  }

  // MARK: - Public API — Image slot conveniences

  /// Registers the center image slot for an exact state key.
  public func setCenterImage(_ image: ImageAttributes?, for state: UIControl.State) {
    setImage(image, slot: .center, for: state)
  }

  /// Registers the leading image slot for an exact state key.
  public func setLeadingImage(_ image: ImageAttributes?, for state: UIControl.State) {
    setImage(image, slot: .leading, for: state)
  }

  /// Registers the trailing image slot for an exact state key.
  public func setTrailingImage(_ image: ImageAttributes?, for state: UIControl.State) {
    setImage(image, slot: .trailing, for: state)
  }

  // MARK: - Public API — Custom content

  /// Requires `content.kind == .custom`. Use `nil` to clear this state.
  public func setCustomContent(_ content: CustomContent?, for state: UIControl.State) {
    let key = Self.makeStateKey(state)
    if let content {
      customContentByState[key] = content
    } else {
      customContentByState.removeValue(forKey: key)
    }
    requestVisualRefresh()
  }

  /// Reads the registered custom content for an exact state key.
  public func customContent(for state: UIControl.State) -> CustomContent? {
    customContentByState[Self.makeStateKey(state)]
  }
}
