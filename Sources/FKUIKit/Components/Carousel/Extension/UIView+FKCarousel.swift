//
// UIView+FKCarousel.swift
//

import UIKit

public extension UIView {
  /// Adds and pins a carousel to current view.
  ///
  /// - Parameters:
  ///   - items: Carousel data source. Passing one item automatically disables swipe and loop behavior.
  ///   - configuration: Optional custom configuration. Defaults to global template.
  ///   - configure: Optional mutating configuration closure executed before applying config.
  /// - Returns: Created carousel instance pinned to all edges of the host view.
  @discardableResult
  func fk_addCarousel(
    items: [FKCarouselItem],
    configuration: FKCarouselConfiguration? = nil,
    configure: ((inout FKCarouselConfiguration) -> Void)? = nil
  ) -> FKCarousel {
    var config = configuration ?? FKCarouselManager.shared.templateConfiguration
    configure?(&config)

    let carousel = FKCarousel(frame: .zero)
    carousel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(carousel)
    NSLayoutConstraint.activate([
      carousel.topAnchor.constraint(equalTo: topAnchor),
      carousel.leadingAnchor.constraint(equalTo: leadingAnchor),
      carousel.trailingAnchor.constraint(equalTo: trailingAnchor),
      carousel.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    carousel.apply(configuration: config)
    carousel.reload(items: items)
    return carousel
  }
}
