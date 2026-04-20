//
// FKStarRatingStarView.swift
//
// Single star rendering unit used by FKStarRating.
//

import UIKit

/// Internal star rendering view for one star item.
@MainActor
final class FKStarRatingStarView: UIView {
  private let borderContainer = UIView()
  private let imageContainer = UIView()
  private let unselectedImageView = UIImageView()
  private let selectedImageView = UIImageView()
  private let halfImageView = UIImageView()
  private let selectedMaskLayer = CALayer()

  private var selectedImage: UIImage?
  private var unselectedImage: UIImage?
  private var halfImage: UIImage?
  private var selectedTintColor: UIColor = .systemYellow
  private var unselectedTintColor: UIColor = .systemGray3
  private var renderMode: FKStarRatingRenderMode = .color

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViewHierarchy()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViewHierarchy()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    borderContainer.frame = bounds
    imageContainer.frame = borderContainer.bounds
    unselectedImageView.frame = imageContainer.bounds
    selectedImageView.frame = imageContainer.bounds
    halfImageView.frame = imageContainer.bounds
    if layer.shadowOpacity > 0 {
      layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: borderContainer.layer.cornerRadius).cgPath
    }
  }

  /// Applies visual resources used to render this star.
  func applyResources(
    selectedImage: UIImage?,
    unselectedImage: UIImage?,
    halfImage: UIImage?,
    selectedTintColor: UIColor,
    unselectedTintColor: UIColor,
    renderMode: FKStarRatingRenderMode
  ) {
    self.selectedImage = selectedImage
    self.unselectedImage = unselectedImage
    self.halfImage = halfImage
    self.selectedTintColor = selectedTintColor
    self.unselectedTintColor = unselectedTintColor
    self.renderMode = renderMode
    refreshImages()
  }

  /// Applies corner/border/shadow style for the star container.
  func applyStyle(_ style: FKStarRatingStarStyle) {
    borderContainer.layer.cornerRadius = style.cornerRadius
    borderContainer.layer.masksToBounds = true
    borderContainer.layer.borderWidth = style.borderWidth
    borderContainer.layer.borderColor = style.borderColor.cgColor

    layer.shadowColor = style.shadowColor.cgColor
    layer.shadowOpacity = style.shadowOpacity
    layer.shadowRadius = style.shadowRadius
    layer.shadowOffset = style.shadowOffset
    layer.masksToBounds = false
    if style.shadowOpacity == 0 {
      layer.shadowPath = nil
    }
    setNeedsLayout()
  }

  /// Updates star fill with value in `0...1`.
  ///
  /// This method supports:
  /// - Whole fill (`0` or `1`)
  /// - Half fill (`0.5`) with optional custom `halfImage`
  /// - Precise decimal fill (mask clipping width)
  func updateFill(_ fillRatio: CGFloat) {
    let clamped = max(0, min(1, fillRatio))
    halfImageView.isHidden = true
    selectedImageView.isHidden = false

    if abs(clamped - 0.5) < 0.001, halfImage != nil {
      selectedImageView.layer.mask = nil
      selectedImageView.isHidden = true
      halfImageView.isHidden = false
      return
    }

    if clamped <= 0 {
      selectedImageView.layer.mask = nil
      selectedImageView.isHidden = true
      return
    }

    selectedImageView.isHidden = false
    selectedImageView.layer.mask = selectedMaskLayer
    selectedMaskLayer.frame = CGRect(
      x: 0,
      y: 0,
      width: bounds.width * clamped,
      height: bounds.height
    )
  }
}

private extension FKStarRatingStarView {
  func setupViewHierarchy() {
    isUserInteractionEnabled = false
    backgroundColor = .clear

    addSubview(borderContainer)
    borderContainer.addSubview(imageContainer)
    imageContainer.addSubview(unselectedImageView)
    imageContainer.addSubview(selectedImageView)
    imageContainer.addSubview(halfImageView)

    unselectedImageView.contentMode = .scaleAspectFit
    selectedImageView.contentMode = .scaleAspectFit
    halfImageView.contentMode = .scaleAspectFit

    selectedMaskLayer.backgroundColor = UIColor.black.cgColor
  }

  func refreshImages() {
    switch renderMode {
    case .image:
      unselectedImageView.image = unselectedImage
      selectedImageView.image = selectedImage
      halfImageView.image = halfImage
      unselectedImageView.tintColor = nil
      selectedImageView.tintColor = nil
      halfImageView.tintColor = nil
    case .color:
      let baseUnselected = (unselectedImage ?? UIImage(systemName: "star"))?.withRenderingMode(.alwaysTemplate)
      let baseSelected = (selectedImage ?? UIImage(systemName: "star.fill"))?.withRenderingMode(.alwaysTemplate)
      let baseHalf = (halfImage ?? UIImage(systemName: "star.leadinghalf.filled"))?.withRenderingMode(.alwaysTemplate)
      unselectedImageView.image = baseUnselected
      selectedImageView.image = baseSelected
      halfImageView.image = baseHalf
      unselectedImageView.tintColor = unselectedTintColor
      selectedImageView.tintColor = selectedTintColor
      halfImageView.tintColor = selectedTintColor
    }
  }
}
