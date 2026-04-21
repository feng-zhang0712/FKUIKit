import UIKit

public extension UIView {
  /// Adds and pins a divider to one edge of the current view.
  ///
  /// - Parameters:
  ///   - edge: Target edge to pin (`top`/`bottom`/`left`/`right`).
  ///   - configuration: Divider configuration. Defaults to global manager configuration.
  ///   - margin: Outer margin along the non-thickness axis.
  /// - Returns: The created `FKDivider` instance.
  @discardableResult
  @MainActor
  func fk_addDivider(
    at edge: FKDividerPinnedEdge,
    configuration: FKDividerConfiguration = FKDividerConfiguration(),
    margin: CGFloat = 0
  ) -> FKDivider {
    // Create and pin a divider in one step to reduce repetitive layout code.
    let divider = FKDivider(configuration: configuration)
    divider.translatesAutoresizingMaskIntoConstraints = false
    addSubview(divider)

    // Keep visual thickness consistent with divider rendering mode.
    let thickness = configuration.isPixelPerfect
      ? (1 / (window?.screen.scale ?? UIScreen.main.scale))
      : configuration.thickness

    switch edge {
    case .top:
      // Top/bottom edges use horizontal direction.
      divider.configuration.direction = .horizontal
      NSLayoutConstraint.activate([
        divider.topAnchor.constraint(equalTo: topAnchor),
        divider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
        divider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
        divider.heightAnchor.constraint(equalToConstant: max(0.5, thickness)),
      ])
    case .bottom:
      divider.configuration.direction = .horizontal
      NSLayoutConstraint.activate([
        divider.bottomAnchor.constraint(equalTo: bottomAnchor),
        divider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
        divider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
        divider.heightAnchor.constraint(equalToConstant: max(0.5, thickness)),
      ])
    case .left:
      // Left/right edges use vertical direction.
      divider.configuration.direction = .vertical
      NSLayoutConstraint.activate([
        divider.leadingAnchor.constraint(equalTo: leadingAnchor),
        divider.topAnchor.constraint(equalTo: topAnchor, constant: margin),
        divider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
        divider.widthAnchor.constraint(equalToConstant: max(0.5, thickness)),
      ])
    case .right:
      divider.configuration.direction = .vertical
      NSLayoutConstraint.activate([
        divider.trailingAnchor.constraint(equalTo: trailingAnchor),
        divider.topAnchor.constraint(equalTo: topAnchor, constant: margin),
        divider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
        divider.widthAnchor.constraint(equalToConstant: max(0.5, thickness)),
      ])
    }
    return divider
  }
}
