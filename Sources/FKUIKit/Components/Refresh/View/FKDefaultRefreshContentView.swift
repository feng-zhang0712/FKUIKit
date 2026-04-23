import UIKit

/// Built-in indicator: arrow that rotates into a spinner plus status label driven by ``FKRefreshText``.
public final class FKDefaultRefreshContentView: UIView, FKRefreshContentView {

  /// Hosts the arrow layer and spinner so they share one vertical slot above the label (avoids overlap).
  private let indicatorHost = UIView()
  private let spinner = UIActivityIndicatorView(style: .medium)
  private let arrowLayer = CAShapeLayer()
  private let stackView = UIStackView()
  private let label = UILabel()
  private let retryButton = UIButton(type: .system)

  private var configuration: FKRefreshConfiguration = .default

  /// Wired by ``FKRefreshControl`` to re-fire a failed load-more request.
  public var onRetryTap: (() -> Void)?

  private lazy var retryTapGesture: UITapGestureRecognizer = {
    let g = UITapGestureRecognizer(target: self, action: #selector(handleRetryTap))
    g.isEnabled = false
    return g
  }()

  // MARK: - Init

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    backgroundColor = .clear

    indicatorHost.backgroundColor = .clear
    indicatorHost.translatesAutoresizingMaskIntoConstraints = false

    arrowLayer.fillColor = UIColor.clear.cgColor
    arrowLayer.lineWidth = 2
    arrowLayer.lineCap = .round
    arrowLayer.strokeColor = UIColor.secondaryLabel.cgColor
    indicatorHost.layer.addSublayer(arrowLayer)

    spinner.hidesWhenStopped = true
    spinner.alpha = 0
    spinner.translatesAutoresizingMaskIntoConstraints = false
    indicatorHost.addSubview(spinner)

    label.font = .systemFont(ofSize: 12, weight: .regular)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.alpha = 0
    label.numberOfLines = 2
    label.adjustsFontForContentSizeCategory = true
    label.lineBreakMode = .byWordWrapping

    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = 6
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.addArrangedSubview(indicatorHost)
    stackView.addArrangedSubview(label)
    stackView.addArrangedSubview(retryButton)

    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),

      indicatorHost.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
      indicatorHost.heightAnchor.constraint(equalToConstant: 28),

      spinner.centerXAnchor.constraint(equalTo: indicatorHost.centerXAnchor),
      spinner.centerYAnchor.constraint(equalTo: indicatorHost.centerYAnchor),
    ])

    retryButton.isHidden = true
    retryButton.setContentHuggingPriority(.required, for: .vertical)
    retryButton.addTarget(self, action: #selector(handleRetryTap), for: .touchUpInside)

    addGestureRecognizer(retryTapGesture)
    semanticContentAttribute = .unspecified
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    updateArrowPath()
  }

  private func updateArrowPath() {
    let b = indicatorHost.bounds
    guard b.width > 0, b.height > 0 else { return }
    let size: CGFloat = 20
    let cx = b.midX
    let cy = b.midY
    let r = size / 2

    let path = UIBezierPath()
    path.move(to: CGPoint(x: cx, y: cy - r))
    path.addLine(to: CGPoint(x: cx, y: cy + r))
    path.move(to: CGPoint(x: cx - r * 0.5, y: cy + r * 0.4))
    path.addLine(to: CGPoint(x: cx, y: cy + r))
    path.addLine(to: CGPoint(x: cx + r * 0.5, y: cy + r * 0.4))

    arrowLayer.path = path.cgPath
    arrowLayer.frame = b
  }

  // MARK: - FKRefreshContentView

  public func refreshControl(_ control: FKRefreshControl, didTransitionTo state: FKRefreshState, from previous: FKRefreshState) {
    configuration = control.configuration
    let texts = configuration.texts
    let isFooter = control.kind == .loadMore

    applyAppearance()
    retryTapGesture.isEnabled = false

    switch state {
    case .idle:
      showArrow(rotated: false, animated: previous != .idle)
      spinner.stopAnimating()
      setLabel(nil)

      retryButton.isHidden = true
    case .pulling:
      showArrow(rotated: false, animated: false)
      spinner.stopAnimating()
      setLabel(texts.pullToRefresh)

      retryButton.isHidden = true
    case .readyToRefresh, .triggered:
      showArrow(rotated: true, animated: true)
      setLabel(texts.releaseToRefresh)
      retryButton.isHidden = true

    case .refreshing, .loadingMore:
      UIView.animate(withDuration: 0.2) {
        self.arrowLayer.opacity = 0
        self.spinner.alpha = 1
      }
      spinner.startAnimating()
      setLabel(isFooter ? texts.footerLoading : texts.headerLoading)
      retryButton.isHidden = true

    case .finished:
      arrowLayer.opacity = 0
      spinner.stopAnimating()
      setLabel(isFooter ? texts.footerFinished : texts.headerFinished)
      UIView.animate(withDuration: 0.2) { self.spinner.alpha = 0 }

    case .listEmpty:
      arrowLayer.opacity = 0
      spinner.stopAnimating()
      setLabel(texts.headerListEmpty)
      UIView.animate(withDuration: 0.2) { self.spinner.alpha = 0 }

    case .noMoreData:
      spinner.stopAnimating()
      arrowLayer.opacity = 0
      setLabel(isFooter ? texts.footerNoMoreData : texts.headerListEmpty)
      retryButton.isHidden = true

    case .failed:
      spinner.stopAnimating()
      UIView.animate(withDuration: 0.2) { self.spinner.alpha = 0 }
      arrowLayer.opacity = 0
      retryTapGesture.isEnabled = isFooter
      if isFooter {
        setLabel("\(texts.footerFailed)\n\(texts.footerTapToRetry)")
        retryButton.setTitle(texts.footerTapToRetry, for: .normal)
        retryButton.isHidden = false
      } else {
        setLabel(texts.headerFailed)
        retryButton.isHidden = true
      }
    }

    updateAccessibility(state: state, texts: texts, isFooter: isFooter)
  }

  public func refreshControl(_ control: FKRefreshControl, didUpdatePullProgress progress: CGFloat) {
    arrowLayer.opacity = Float(min(1, progress * 1.5))
  }

  // MARK: - Actions

  @objc private func handleRetryTap() {
    onRetryTap?()
  }

  // MARK: - Helpers

  private func applyAppearance() {
    let base = UIFont.systemFont(ofSize: configuration.messageFontSize, weight: configuration.messageFontWeight)
    label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: base)
    retryButton.titleLabel?.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: base)
    applyTint(configuration.tintColor)
  }

  private func showArrow(rotated: Bool, animated: Bool) {
    let targetTransform = rotated
      ? CATransform3DMakeRotation(.pi, 0, 0, 1)
      : CATransform3DIdentity

    arrowLayer.removeAllAnimations()
    if animated {
      let rotation = CABasicAnimation(keyPath: "transform")
      rotation.fromValue = arrowLayer.presentation()?.transform ?? arrowLayer.transform
      rotation.toValue = targetTransform
      rotation.duration = 0.25
      arrowLayer.add(rotation, forKey: "arrowRotation")
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    arrowLayer.transform = targetTransform
    arrowLayer.opacity = 1
    CATransaction.commit()
    spinner.alpha = 0
  }

  private func setLabel(_ text: String?) {
    label.text = text
    UIView.animate(withDuration: 0.2) {
      self.label.alpha = text == nil ? 0 : 1
    }
  }

  private func applyTint(_ color: UIColor) {
    arrowLayer.strokeColor = color.cgColor
    spinner.color = color
    label.textColor = color
    retryButton.tintColor = color
  }

  private func updateAccessibility(state: FKRefreshState, texts: FKRefreshText, isFooter: Bool) {
    isAccessibilityElement = true
    accessibilityTraits = .staticText
    switch state {
    case .refreshing:
      accessibilityLabel = texts.headerLoading
      accessibilityHint = nil
    case .loadingMore:
      accessibilityLabel = texts.footerLoading
      accessibilityHint = nil
    case .failed:
      accessibilityLabel = isFooter ? texts.footerFailed : texts.headerFailed
      accessibilityHint = isFooter ? texts.footerTapToRetry : nil
    case .noMoreData:
      accessibilityLabel = texts.footerNoMoreData
      accessibilityHint = nil
    case .readyToRefresh, .triggered:
      accessibilityLabel = texts.releaseToRefresh
      accessibilityHint = nil
    case .pulling:
      accessibilityLabel = texts.pullToRefresh
      accessibilityHint = nil
    case .finished:
      accessibilityLabel = isFooter ? texts.footerFinished : texts.headerFinished
      accessibilityHint = nil
    case .listEmpty:
      accessibilityLabel = texts.headerListEmpty
      accessibilityHint = nil
    case .idle:
      accessibilityLabel = nil
      accessibilityHint = nil
    }

    retryButton.isAccessibilityElement = !retryButton.isHidden
    retryButton.accessibilityTraits = [.button]
    retryButton.accessibilityHint = texts.footerTapToRetry
  }
}
