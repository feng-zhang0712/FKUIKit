import UIKit

/// Anchor specification used by `FKPresentationMode.anchor(_:)`.
///
/// This type is designed to be resilient in dynamic UI environments where the source view may move,
/// appear/disappear, or change size (e.g. navigation bars, tab bars, animated toolbars).
public struct FKAnchor {
  /// How to resolve the anchor's source geometry.
  public enum Source {
    /// Anchors to a view. The reference is weak to avoid retain cycles.
    case view(FKWeakReference<UIView>)
    /// Anchors to a rect provider in container coordinates.
    case rect(@MainActor () -> CGRect?)
  }

  /// Which edge of the source is used as the attachment line.
  public enum Edge {
    /// Uses the top edge of the source rect.
    case top
    /// Uses the bottom edge of the source rect.
    case bottom
  }

  /// Expansion direction relative to the attachment edge.
  public enum Direction {
    /// Expands upward from the attachment edge.
    case up
    /// Expands downward from the attachment edge.
    case down
    /// Chooses `up` or `down` based on available space.
    case auto
  }

  /// Horizontal alignment of the presented frame relative to the source.
  public enum Alignment {
    /// Aligns leading edges.
    case leading
    /// Aligns centers.
    case center
    /// Aligns trailing edges.
    case trailing
    /// Fills available width according to `widthPolicy`.
    case fill
  }

  /// Width sizing strategy.
  public enum WidthPolicy {
    /// Matches the source width.
    case matchAnchor
    /// Matches the container width (minus safe area if configured).
    case matchContainer
    /// Uses a custom fixed width.
    case fixed(CGFloat)
  }

  /// Geometry source.
  public var source: Source
  /// Attachment edge on the source.
  public var edge: Edge
  /// Expansion direction.
  public var direction: Direction
  /// Horizontal alignment policy.
  public var alignment: Alignment
  /// Width sizing strategy.
  public var widthPolicy: WidthPolicy
  /// Gap between source and presented frame.
  public var offset: CGFloat

  /// Creates an anchor from a view.
  public init(
    sourceView: UIView,
    edge: Edge = .bottom,
    direction: Direction = .auto,
    alignment: Alignment = .fill,
    widthPolicy: WidthPolicy = .matchContainer,
    offset: CGFloat = 8
  ) {
    self.source = .view(FKWeakReference(sourceView))
    self.edge = edge
    self.direction = direction
    self.alignment = alignment
    self.widthPolicy = widthPolicy
    self.offset = max(0, offset)
  }

  /// Creates an anchor from a rect resolver.
  public init(
    edge: Edge,
    direction: Direction = .auto,
    alignment: Alignment = .fill,
    widthPolicy: WidthPolicy = .matchContainer,
    offset: CGFloat = 8,
    rectProvider: @escaping @MainActor () -> CGRect?
  ) {
    self.source = .rect(rectProvider)
    self.edge = edge
    self.direction = direction
    self.alignment = alignment
    self.widthPolicy = widthPolicy
    self.offset = max(0, offset)
  }
}

