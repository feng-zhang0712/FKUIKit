//
// FKLoadingAnimatorComprehensiveExampleViewController.swift
//
// Comprehensive runnable examples for FKLoadingAnimator.
//

import FKUIKit
import QuartzCore
import UIKit

/// Playground screen that demonstrates all core loading animator scenarios.
final class FKLoadingAnimatorComprehensiveExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()

  private let embeddedContainer = UIView()
  private let imageHost = UIImageView(image: UIImage(systemName: "photo"))
  private let buttonHost = UIButton(type: .system)

  private let progressLabel = UILabel()
  private var progressValue: CGFloat = 0

  private var fullScreenStyleIndex: Int = 0
  private let fullScreenStyles: [FKLoadingAnimatorStyle] = [.ring, .wave, .particles, .spinner]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Comprehensive Demo"
    view.backgroundColor = .systemBackground
    FKLoadingAnimatorDemoFactory.configureGlobalStyleIfNeeded()
    setupLayout()
    setupInitialEmbeddedAnimators()
  }

  // MARK: - Setup

  private func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 12
    stackView.alignment = .fill

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
    ])

    configureEmbeddedHosts()
    addSection(
      title: "One-line API",
      buttons: [
        ("Show Fullscreen (ring/wave/particle/spinner)", #selector(showFullscreenLoading)),
        ("Hide Fullscreen", #selector(hideFullscreenLoading)),
      ]
    )

    addSection(
      title: "Embedded Loading in UIView / UIImageView / UIButton",
      customContent: [embeddedContainer, imageHost, buttonHost]
    )

    progressLabel.text = "Progress: 0%"
    progressLabel.font = .systemFont(ofSize: 14, weight: .medium)
    addSection(
      title: "Circular Progress Ring",
      customContent: [progressLabel],
      buttons: [
        ("Start Progress Ring", #selector(startProgressRing)),
        ("Increase Progress +10%", #selector(increaseProgress)),
      ]
    )

    addSection(
      title: "Manual Control",
      buttons: [
        ("Start", #selector(startManual)),
        ("Pause", #selector(pauseManual)),
        ("Resume", #selector(resumeManual)),
        ("Stop", #selector(stopManual)),
      ]
    )

    addSection(
      title: "Style & Performance Configuration",
      buttons: [
        ("Custom Color / Size / Speed / Duration", #selector(applyCustomStyle)),
        ("Particle + Wave Custom Count & Amplitude", #selector(applyParticleWaveStyle)),
        ("Disable Mask Interaction + Set Mask Alpha", #selector(showNonInteractiveMask)),
      ]
    )

    addSection(
      title: "Advanced Capability",
      buttons: [
        ("Switch Animation Style Dynamically", #selector(switchStyleDynamically)),
        ("Apply Global Style Configuration", #selector(applyGlobalTemplateAgain)),
        ("Use Custom Animator Style", #selector(useCustomAnimatorStyle)),
      ]
    )
  }

  private func configureEmbeddedHosts() {
    embeddedContainer.translatesAutoresizingMaskIntoConstraints = false
    embeddedContainer.backgroundColor = .tertiarySystemBackground
    embeddedContainer.layer.cornerRadius = 14
    embeddedContainer.heightAnchor.constraint(equalToConstant: 120).isActive = true

    imageHost.translatesAutoresizingMaskIntoConstraints = false
    imageHost.tintColor = .systemBlue
    imageHost.contentMode = .scaleAspectFit
    imageHost.backgroundColor = .tertiarySystemBackground
    imageHost.layer.cornerRadius = 14
    imageHost.clipsToBounds = true
    imageHost.heightAnchor.constraint(equalToConstant: 120).isActive = true

    buttonHost.translatesAutoresizingMaskIntoConstraints = false
    buttonHost.setTitle("Button Host", for: .normal)
    buttonHost.backgroundColor = .tertiarySystemBackground
    buttonHost.layer.cornerRadius = 14
    buttonHost.setTitleColor(.label, for: .normal)
    buttonHost.heightAnchor.constraint(equalToConstant: 64).isActive = true
  }

  private func setupInitialEmbeddedAnimators() {
    // Embedded loading inside UIView.
    embeddedContainer.fk_showLoadingAnimator { config in
      config.presentationMode = .embedded
      config.style = .wave
      config.size = CGSize(width: 76, height: 76)
    }

    // Embedded loading inside UIImageView.
    imageHost.fk_showLoadingAnimator { config in
      config.presentationMode = .embedded
      config.style = .rotatingDots
      config.size = CGSize(width: 56, height: 56)
    }

    // Embedded loading inside UIButton.
    buttonHost.fk_showLoadingAnimator { config in
      config.presentationMode = .embedded
      config.style = .spinner
      config.size = CGSize(width: 40, height: 40)
    }
  }

  // MARK: - Actions

  @objc
  private func showFullscreenLoading() {
    let style = fullScreenStyles[fullScreenStyleIndex % fullScreenStyles.count]
    fullScreenStyleIndex += 1

    view.fk_showLoadingAnimator(configuration: FKLoadingAnimatorDemoFactory.fullScreenConfig(style: style)) { [weak self] config in
      guard let self else { return }
      config.stateDidChange = { [weak self] state in
        guard let self else { return }
        if state == .loading {
          self.progressLabel.text = "Fullscreen style: \(self.debugName(of: style))"
        }
      }
    }
  }

  @objc
  private func hideFullscreenLoading() {
    view.fk_hideLoadingAnimator(animated: true)
  }

  @objc
  private func startProgressRing() {
    progressValue = 0
    progressLabel.text = "Progress: 0%"
    embeddedContainer.fk_showLoadingAnimator { config in
      config.presentationMode = .embedded
      config.style = .progressRing
      config.size = CGSize(width: 84, height: 84)
      config.styleConfiguration.primaryColor = .systemGreen
      config.styleConfiguration.ringWidth = 6
      config.autoStart = true
    }
    embeddedContainer.fk_updateLoadingProgress(0)
  }

  @objc
  private func increaseProgress() {
    progressValue = min(progressValue + 0.1, 1.0)
    embeddedContainer.fk_updateLoadingProgress(progressValue)
    progressLabel.text = "Progress: \(Int(progressValue * 100))%"
    if progressValue >= 1 {
      embeddedContainer.fk_stopLoadingAnimation()
    }
  }

  @objc
  private func startManual() {
    embeddedContainer.fk_startLoadingAnimation()
    imageHost.fk_startLoadingAnimation()
    buttonHost.fk_startLoadingAnimation()
  }

  @objc
  private func pauseManual() {
    embeddedContainer.fk_pauseLoadingAnimation()
    imageHost.fk_pauseLoadingAnimation()
    buttonHost.fk_pauseLoadingAnimation()
  }

  @objc
  private func resumeManual() {
    embeddedContainer.fk_resumeLoadingAnimation()
    imageHost.fk_resumeLoadingAnimation()
    buttonHost.fk_resumeLoadingAnimation()
  }

  @objc
  private func stopManual() {
    embeddedContainer.fk_stopLoadingAnimation()
    imageHost.fk_stopLoadingAnimation()
    buttonHost.fk_stopLoadingAnimation()
  }

  @objc
  private func applyCustomStyle() {
    view.fk_showLoadingAnimator { config in
      config.presentationMode = .fullScreen
      config.style = .gradientRing
      config.maskAlpha = 0.3
      config.size = CGSize(width: 92, height: 92)
      config.styleConfiguration.duration = 0.85
      config.styleConfiguration.speed = 1.3
      config.styleConfiguration.ringWidth = 7
      config.styleConfiguration.gradientColors = [.systemOrange, .systemPink, .systemPurple]
      config.stateDidChange = { [weak self] state in
        guard let self else { return }
        if state == .loading {
          self.fk_showLoadingAnimatorAlert(title: "State Callback", message: "Loading started with custom style.")
        }
      }
    }
  }

  @objc
  private func applyParticleWaveStyle() {
    embeddedContainer.fk_showLoadingAnimator { config in
      config.presentationMode = .embedded
      config.style = .particles
      config.styleConfiguration.particleCount = 18
      config.styleConfiguration.speed = 1.4
      config.styleConfiguration.duration = 0.9
      config.styleConfiguration.primaryColor = .systemCyan
      config.size = CGSize(width: 100, height: 100)
    }

    imageHost.fk_showLoadingAnimator { config in
      config.presentationMode = .embedded
      config.style = .wave
      config.styleConfiguration.waveAmplitude = 14
      config.styleConfiguration.lineWidth = 4
      config.styleConfiguration.primaryColor = .systemIndigo
      config.size = CGSize(width: 96, height: 96)
    }
  }

  @objc
  private func showNonInteractiveMask() {
    view.fk_showLoadingAnimator { config in
      config.presentationMode = .fullScreen
      config.style = .spinner
      config.maskAlpha = 0.45
      config.allowsMaskTapToStop = false
    }
  }

  @objc
  private func switchStyleDynamically() {
    let sequence: [FKLoadingAnimatorStyle] = [.ring, .wave, .flowingParticles, .spinner, .gear]
    embeddedContainer.fk_showLoadingAnimator { config in
      config.presentationMode = .embedded
      config.style = sequence.first ?? .ring
    }

    // Switch styles on main queue to keep transitions deterministic.
    var delay: TimeInterval = 0.4
    for style in sequence.dropFirst() {
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
        self?.embeddedContainer.fk_switchLoadingStyle(style, autoRestart: true)
      }
      delay += 0.4
    }
  }

  @objc
  private func applyGlobalTemplateAgain() {
    FKLoadingAnimatorManager.shared.configureTemplate { config in
      config.style = .pulseCircle
      config.size = CGSize(width: 68, height: 68)
      config.backgroundColor = .systemGray6
      config.styleConfiguration.primaryColor = .systemMint
      config.styleConfiguration.duration = 1.0
      config.styleConfiguration.speed = 1.0
    }
    buttonHost.fk_showLoadingAnimator()
  }

  @objc
  private func useCustomAnimatorStyle() {
    let customAnimator = FKDemoBarsLoadingAnimator()
    imageHost.fk_showLoadingAnimator { config in
      config.presentationMode = .embedded
      config.style = .custom(customAnimator)
      config.size = CGSize(width: 90, height: 90)
      config.styleConfiguration.primaryColor = .systemRed
      config.styleConfiguration.duration = 0.7
      config.styleConfiguration.repeatCount = .infinity
    }
  }

  // MARK: - Builder

  private func addSection(
    title: String,
    customContent: [UIView] = [],
    buttons: [(String, Selector)] = []
  ) {
    let container = UIView()
    container.backgroundColor = .secondarySystemGroupedBackground
    container.layer.cornerRadius = 12
    container.translatesAutoresizingMaskIntoConstraints = false

    let sectionStack = UIStackView()
    sectionStack.axis = .vertical
    sectionStack.spacing = 8
    sectionStack.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    titleLabel.text = title
    titleLabel.numberOfLines = 0

    sectionStack.addArrangedSubview(titleLabel)

    for view in customContent {
      sectionStack.addArrangedSubview(view)
    }

    for (text, action) in buttons {
      let button = UIButton(type: .system)
      button.setTitle(text, for: .normal)
      button.contentHorizontalAlignment = .left
      button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
      button.addTarget(self, action: action, for: .touchUpInside)
      sectionStack.addArrangedSubview(button)
    }

    container.addSubview(sectionStack)
    NSLayoutConstraint.activate([
      sectionStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
      sectionStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
      sectionStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
      sectionStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
    ])
    stackView.addArrangedSubview(container)
  }

  private func debugName(of style: FKLoadingAnimatorStyle) -> String {
    switch style {
    case .ring: return "ring"
    case .gradientRing: return "gradientRing"
    case .progressRing: return "progressRing"
    case .wave: return "wave"
    case .rippleWave: return "rippleWave"
    case .particles: return "particles"
    case .flowingParticles: return "flowingParticles"
    case .twinkleParticles: return "twinkleParticles"
    case .spinner: return "spinner"
    case .pulseCircle: return "pulseCircle"
    case .pulseSquare: return "pulseSquare"
    case .rotatingDots: return "rotatingDots"
    case .gear: return "gear"
    case .custom: return "custom"
    }
  }
}

/// Simple custom animator demo implementation.
///
/// This example conforms to `FKLoadingAnimationProviding` directly so users can copy it into app code.
private final class FKDemoBarsLoadingAnimator: NSObject, FKLoadingAnimationProviding {
  let renderLayer = CALayer()
  private let bar = CAShapeLayer()
  private var style = FKLoadingAnimatorStyleConfiguration()

  func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    self.style = style
    renderLayer.frame = bounds
    let barRect = CGRect(
      x: bounds.midX - 8,
      y: bounds.midY - 22,
      width: 16,
      height: 44
    )
    bar.frame = bounds
    bar.path = UIBezierPath(roundedRect: barRect, cornerRadius: 8).cgPath
    bar.fillColor = style.primaryColor.cgColor
    if bar.superlayer == nil {
      renderLayer.addSublayer(bar)
    }
  }

  func start() {
    stop()
    let scale = CABasicAnimation(keyPath: "transform.scale.y")
    scale.fromValue = 0.4
    scale.toValue = 1.0
    scale.autoreverses = true
    scale.repeatCount = style.repeatCount
    scale.duration = style.duration / max(style.speed, 0.01)
    bar.add(scale, forKey: "bars.scale")
  }

  func stop() {
    renderLayer.removeAllAnimations()
    bar.removeAllAnimations()
  }

  func pause() {
    let paused = renderLayer.convertTime(CACurrentMediaTime(), from: nil)
    renderLayer.speed = 0
    renderLayer.timeOffset = paused
  }

  func resume() {
    let paused = renderLayer.timeOffset
    renderLayer.speed = 1
    renderLayer.timeOffset = 0
    renderLayer.beginTime = 0
    renderLayer.beginTime = renderLayer.convertTime(CACurrentMediaTime(), from: nil) - paused
  }

  func updateProgress(_ progress: CGFloat) {
    _ = progress
  }
}

