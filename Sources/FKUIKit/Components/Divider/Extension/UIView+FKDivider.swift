import UIKit

public extension UIView {
  /// Pins a new ``FKDivider`` to one edge of `self`.
  ///
  /// - Parameters:
  ///   - edge: ``FKDividerPinnedEdge/top``, ``/bottom``, or vertical pins on **semantic** ``/leading`` and ``/trailing``.
  ///   - configuration: Style; defaults to ``FKDivider/defaultConfiguration``.
  ///   - margin: Inset from the orthogonal edges (e.g. leading/trailing inset when pinning to top/bottom).
  /// - Returns: The divider instance (already added as a subview).
  @discardableResult
  @MainActor
  func fk_addDivider(
    at edge: FKDividerPinnedEdge,
    configuration: FKDividerConfiguration = FKDivider.defaultConfiguration,
    margin: CGFloat = 0
  ) -> FKDivider {
    let divider = FKDivider(configuration: configuration)
    divider.translatesAutoresizingMaskIntoConstraints = false
    addSubview(divider)

    let thickness = configuration.isPixelPerfect
      ? (1 / (window?.screen.scale ?? UIScreen.main.scale))
      : configuration.thickness

    switch edge {
    case .top:
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
    case .leading:
      divider.configuration.direction = .vertical
      NSLayoutConstraint.activate([
        divider.leadingAnchor.constraint(equalTo: leadingAnchor),
        divider.topAnchor.constraint(equalTo: topAnchor, constant: margin),
        divider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
        divider.widthAnchor.constraint(equalToConstant: max(0.5, thickness)),
      ])
    case .trailing:
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
