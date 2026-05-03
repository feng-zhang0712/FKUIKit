import UIKit

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI wrapper around ``FKDividerConfiguration`` (same fields as ``FKDivider``).
public struct FKDividerView: View {
  public var configuration: FKDividerConfiguration
  @Environment(\.displayScale) private var displayScale

  public init(configuration: FKDividerConfiguration = FKDividerConfiguration()) {
    self.configuration = configuration
  }

  public var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let thickness = resolvedThickness(displayScale: displayScale)
      let path = dividerPath(size: size)

      ZStack {
        if configuration.showsGradient {
          gradientView.mask(
            path.stroke(style: strokeStyle(lineWidth: thickness))
          )
        } else {
          path.stroke(
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
    if configuration.lineStyle == .dashed {
      return StrokeStyle(
        lineWidth: lineWidth,
        lineCap: .round,
        dash: configuration.dashPattern
      )
    }
    return StrokeStyle(lineWidth: lineWidth, lineCap: .round)
  }

  private func dividerPath(size: CGSize) -> Path {
    var path = Path()
    let rect = CGRect(origin: .zero, size: size)
    switch configuration.direction {
    case .horizontal:
      if let seg = FKDividerGeometry.horizontalSegment(in: rect, contentInsets: configuration.contentInsets) {
        path.move(to: CGPoint(x: seg.x1, y: seg.y))
        path.addLine(to: CGPoint(x: seg.x2, y: seg.y))
      }
    case .vertical:
      if let seg = FKDividerGeometry.verticalSegment(in: rect, contentInsets: configuration.contentInsets) {
        path.move(to: CGPoint(x: seg.x, y: seg.y1))
        path.addLine(to: CGPoint(x: seg.x, y: seg.y2))
      }
    }
    return path
  }

  private func resolvedThickness(displayScale: CGFloat) -> CGFloat {
    guard configuration.isPixelPerfect else { return resolvedLogicalThickness() }
    return max(1 / max(displayScale, 1), 0.5 / max(displayScale, 1))
  }

  private func resolvedLogicalThickness() -> CGFloat {
    max(0.5, configuration.thickness)
  }
}
#endif
