//
// FKCarouselPageControl.swift
//

import UIKit

/// Internal dot-based page control used by `FKCarousel`.
///
/// This view supports custom dot size, color, image, and spacing while keeping
/// update operations lightweight for frequent page transitions.
final class FKCarouselPageControl: UIView {
  /// Horizontal stack that arranges dot views.
  private let stackView = UIStackView()
  /// Dot view cache reused across style updates.
  private var dots: [UIImageView] = []
  /// Current dot style snapshot.
  private var style = FKCarouselPageControlStyle()
  /// Total number of logical pages.
  private(set) var numberOfPages: Int = 0
  /// Current selected page index.
  private(set) var currentPage: Int = 0

  /// Creates page control programmatically.
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  /// Creates page control from Interface Builder.
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  /// Rebuilds page control state and dot views.
  ///
  /// - Parameters:
  ///   - numberOfPages: Total page count.
  ///   - currentPage: Current selected page.
  ///   - style: Visual style for dot rendering.
  func update(numberOfPages: Int, currentPage: Int, style: FKCarouselPageControlStyle) {
    self.numberOfPages = max(0, numberOfPages)
    self.currentPage = min(max(0, currentPage), max(0, numberOfPages - 1))
    self.style = style
    rebuildDots()
  }

  /// Updates selected page without rebuilding dot hierarchy.
  ///
  /// - Parameter page: Target page index.
  func setCurrentPage(_ page: Int) {
    let clamped = min(max(0, page), max(0, numberOfPages - 1))
    guard clamped != currentPage else { return }
    currentPage = clamped
    applyDotStyles()
  }

  /// Initializes stack layout constraints.
  private func setupUI() {
    isUserInteractionEnabled = false
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  /// Recreates dot views when page count or style changes.
  private func rebuildDots() {
    dots.forEach { $0.removeFromSuperview() }
    dots.removeAll(keepingCapacity: true)
    stackView.spacing = style.spacing

    // No indicators are needed for zero or single-item data sets.
    guard numberOfPages > 1 else { return }
    for _ in 0 ..< numberOfPages {
      let dot = UIImageView()
      dot.clipsToBounds = true
      dot.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(dot)
      dots.append(dot)
    }
    applyDotStyles()
  }

  /// Applies visual state to all dots based on `currentPage`.
  private func applyDotStyles() {
    for (index, dot) in dots.enumerated() {
      dot.constraints.forEach { dot.removeConstraint($0) }
      let selected = index == currentPage
      let size = selected ? style.selectedDotSize : style.normalDotSize
      NSLayoutConstraint.activate([
        dot.widthAnchor.constraint(equalToConstant: size.width),
        dot.heightAnchor.constraint(equalToConstant: size.height),
      ])
      dot.layer.cornerRadius = size.height * 0.5
      dot.image = selected ? style.selectedDotImage : style.normalDotImage
      dot.tintColor = selected ? style.selectedColor : style.normalColor
      dot.backgroundColor = dot.image == nil ? dot.tintColor : .clear
    }
  }
}
