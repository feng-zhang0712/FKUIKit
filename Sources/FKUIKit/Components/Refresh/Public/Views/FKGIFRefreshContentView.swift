import UIKit

/// GIF-based indicator using `UIImage.animatedImage` (UIKit only).
public final class FKGIFRefreshContentView: UIView, FKRefreshContentView {

  private let imageView = UIImageView()
  private var animatedImage: UIImage?

  public var image: UIImage? {
    didSet {
      animatedImage = image
      imageView.image = image
    }
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
      imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
      imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 48),
      imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 160),
    ])
  }

  public func refreshControl(_ control: FKRefreshControl, didTransitionTo state: FKRefreshState, from previous: FKRefreshState) {
    switch state {
    case .refreshing, .loadingMore:
      startGIF()
    default:
      stopGIF()
    }
  }

  private func startGIF() {
    guard let base = animatedImage ?? imageView.image else { return }
    imageView.image = base
    imageView.startAnimating()
  }

  private func stopGIF() {
    imageView.stopAnimating()
  }
}
