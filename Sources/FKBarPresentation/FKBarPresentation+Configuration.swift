//
// FKBarPresentation+Configuration.swift
//
// `FKBarPresentation` top-level configuration: `FKBar`, panel `FKPresentation`,
// interaction behavior, and hosting container.
// See `FKBarPresentation.swift` for API details. Fine-grained config lives in
// `FKBar.Configuration` and `FKPresentation.Configuration`.
//

import UIKit
import FKBar
import FKPresentation

// MARK: - FKBarPresentation.Configuration (top-level)

public extension FKBarPresentation {
  /// Composite configuration: bar styling/scrolling, `FKPresentation` parameters,
  /// and the bar↔panel interaction behavior.
  struct Configuration {
    // MARK: Sub-configs (aligned with `FKBar.Configuration` / `FKPresentation.Configuration`)

    /// Bar config: spacing, scrolling, corners, shadow, etc.
    public var bar: FKBar.Configuration

    /// Panel config: mask, animation, content insets, width strategy, etc.
    public var presentation: FKPresentation.Configuration

    /// Interaction behavior between bar selection and panel presentation.
    public var behavior: Behavior

    /// Where to host the panel. By default it uses `FKBarPresentation.superview` at presentation time.
    public var presentationHost: PresentationHost

    public init(
      bar: FKBar.Configuration = .default,
      presentation: FKPresentation.Configuration = .default,
      behavior: Behavior = .init(),
      presentationHost: PresentationHost = .automatic
    ) {
      self.bar = bar
      self.presentation = presentation
      self.behavior = behavior
      self.presentationHost = presentationHost
    }

    public nonisolated(unsafe) static let `default` = Configuration()
  }
}

// MARK: - Panel hosting

public extension FKBarPresentation.Configuration {
  /// Determines the container view passed to `FKPresentation.show(..., in:)`.
  enum PresentationHost {
    /// Uses `barPresentation.superview`; falls back to `barPresentation.window` if nil.
    case automatic
    /// Forces `superview` (if nil, presentation will not happen).
    case superview
    /// Uses `barPresentation.window`.
    case window
    /// Explicit container (e.g. a full-screen `UIView`).
    case explicit(WeakUIViewBox)

    public static func explicit(_ view: UIView) -> PresentationHost {
      .explicit(WeakUIViewBox(view))
    }
  }
}

/// Weak wrapper used by `PresentationHost.explicit`.
public final class WeakUIViewBox {
  public weak var view: UIView?
  public init(_ view: UIView) {
    self.view = view
  }
}

// MARK: - Behavior

public extension FKBarPresentation.Configuration {
  /// Default bar↔panel behavior. You may further customize via `FKBarPresentationDelegate`.
  struct Behavior {
    /// When an item becomes selected, whether to attempt presenting the panel.
    public var presentsOnSelection: Bool

    /// When all items are deselected, whether to dismiss the panel (e.g. `.toggle` deselect).
    public var dismissesWhenSelectionCleared: Bool

    /// When switching from item A to B, whether to dismiss the current panel before presenting B.
    public var dismissBeforeChangingSelection: Bool

    /// If the panel is already presented for the same index, ignore repeated selections when enabled.
    public var ignoresRepeatedSelectWhilePresented: Bool

    public init(
      presentsOnSelection: Bool = true,
      dismissesWhenSelectionCleared: Bool = true,
      dismissBeforeChangingSelection: Bool = true,
      ignoresRepeatedSelectWhilePresented: Bool = true
    ) {
      self.presentsOnSelection = presentsOnSelection
      self.dismissesWhenSelectionCleared = dismissesWhenSelectionCleared
      self.dismissBeforeChangingSelection = dismissBeforeChangingSelection
      self.ignoresRepeatedSelectWhilePresented = ignoresRepeatedSelectWhilePresented
    }
  }
}

// MARK: - Dismiss reason (delegate)

public extension FKBarPresentation {
  /// Indicates why the panel was dismissed in `barPresentation(_:didDismissPresentation:)`.
  enum PresentationDismissReason: Equatable, Sendable {
    case maskTap
    case programmatic
    /// Selection cleared (e.g. toggled off).
    case selectionCleared
    /// Dismissed before switching to another selection.
    case selectionChanged
  }
}
