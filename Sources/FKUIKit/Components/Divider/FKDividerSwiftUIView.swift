import UIKit

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI adapter for `FKDividerConfiguration`.
public struct FKDividerView: View {
  /// Divider configuration.
  public var configuration: FKDividerConfiguration
  @Environment(\.displayScale) private var displayScale

  /// Creates a SwiftUI divider view.
  ///
  /// - Parameter configuration: Divider configuration.
  public init(configuration: FKDividerConfiguration = FKDividerConfiguration()) {
    self.configuration = configuration
  }

  /// SwiftUI body that renders divider geometry using the same configuration model as UIKit.
  public var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      // Pixel-perfect thickness adapts to current display scale.
      let thickness = resolvedThickness(displayScale: displayScale)
      let path = dividerPath(size: size)

      ZStack {
        if configuration.showsGradient {
          // Apply gradient through stroke mask to preserve dashed/solid shape behavior.
          gradientView.mask(
            path
              .stroke(style: strokeStyle(lineWidth: thickness))
          )
        } else {
          path
            .stroke(
              Color(uiColor: configuration.color),
              style: strokeStyle(lineWidth: thickness)
            )
        }
      }
    }
    .frame(
      minWidth: configuration.direction == .vertical ? resolvedLogicalThickness() : nil,
      maxWidth: configuration.direction == .vertical ? resolvedLogicalThickness() : .infinity,
      minHeight: configuration.direction == .horizontal ? resolvedLogicalThickness() : nil,
      maxHeight: configuration.direction == .horizontal ? resolvedLogicalThickness() : .infinity
    )
    .accessibilityHidden(true)
  }

  private var gradientView: LinearGradient {
    // Map gradient direction into SwiftUI unit points.
    let start: UnitPoint = configuration.gradientDirection == .horizontal ? .leading : .top
    let end: UnitPoint = configuration.gradientDirection == .horizontal ? .trailing : .bottom
    return LinearGradient(
      colors: [
        Color(uiColor: configuration.gradientStartColor),
        Color(uiColor: configuration.gradientEndColor),
      ],
      startPoint: start,
      endPoint: end
    )
  }

  private func strokeStyle(lineWidth: CGFloat) -> StrokeStyle {
    // Dashed and solid styles share the same path with different stroke style settings.
    if configuration.lineStyle == .dashed {
      return StrokeStyle(
        lineWidth: lineWidth,
        lineCap: .round,
        dash: configuration.dashPattern.map { CGFloat(truncating: $0) }
      )
    }
    return StrokeStyle(lineWidth: lineWidth, lineCap: .round)
  }

  private func dividerPath(size: CGSize) -> Path {
    var path = Path()
    switch configuration.direction {
    case .horizontal:
      // Horizontal stroke centered vertically with optional left/right shortening.
      let y = size.height / 2
      path.move(to: CGPoint(x: configuration.contentInsets.left, y: y))
      path.addLine(to: CGPoint(x: max(configuration.contentInsets.left, size.width - configuration.contentInsets.right), y: y))
    case .vertical:
      // Vertical stroke centered horizontally with optional top/bottom shortening.
      let x = size.width / 2
      path.move(to: CGPoint(x: x, y: configuration.contentInsets.top))
      path.addLine(to: CGPoint(x: x, y: max(configuration.contentInsets.top, size.height - configuration.contentInsets.bottom)))
    }
    return path
  }

  private func resolvedThickness(displayScale: CGFloat) -> CGFloat {
    // Match UIKit behavior for 1-physical-pixel rendering.
    guard configuration.isPixelPerfect else { return resolvedLogicalThickness() }
    return max(1 / max(displayScale, 1), 0.5 / max(displayScale, 1))
  }

  private func resolvedLogicalThickness() -> CGFloat {
    max(0.5, configuration.thickness)
  }
}
#endif
