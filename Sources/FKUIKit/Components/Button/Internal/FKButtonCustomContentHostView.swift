import UIKit

/// Internal stack cell for `FKButton.Content.kind == .custom`; forwards fitting / intrinsic size.
final class FKButtonCustomContentHostView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    isOpaque = false
  }

  override func didAddSubview(_ subview: UIView) {
    super.didAddSubview(subview)
    invalidateIntrinsicContentSize()
  }

  override func willRemoveSubview(_ subview: UIView) {
    super.willRemoveSubview(subview)
    invalidateIntrinsicContentSize()
  }

  override var intrinsicContentSize: CGSize {
    guard let subview = subviews.first else {
      return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    let fitted = subview.systemLayoutSizeFitting(
      CGSize(width: UIView.layoutFittingCompressedSize.width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .fittingSizeLevel,
      verticalFittingPriority: .fittingSizeLevel
    )
    if fitted.width > 0.5, fitted.height > 0.5 {
      return fitted
    }
    let intrinsic = subview.intrinsicContentSize
    let width = intrinsic.width > 0 ? intrinsic.width : UIView.noIntrinsicMetric
    let height = intrinsic.height > 0 ? intrinsic.height : UIView.noIntrinsicMetric
    if width != UIView.noIntrinsicMetric || height != UIView.noIntrinsicMetric {
      return CGSize(width: width, height: height)
    }
    return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
  }
}
