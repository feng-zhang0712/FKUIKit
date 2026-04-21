//
// FKLoadingAnimatorDemoSupport.swift
//
// Shared helpers for FKLoadingAnimator example screens.
//

import FKUIKit
import UIKit

// MARK: - Demo Factory

enum FKLoadingAnimatorDemoFactory {
  /// Applies a global baseline style used by all loading animator demos.
  static func configureGlobalStyleIfNeeded() {
    FKLoadingAnimatorManager.shared.configureTemplate { config in
      config.style = .ring
      config.presentationMode = .embedded
      config.size = CGSize(width: 72, height: 72)
      config.animationInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
      config.backgroundColor = .secondarySystemBackground
      config.maskColor = .black
      config.maskAlpha = 0.25
      config.autoStart = true
      config.allowsMaskTapToStop = false

      config.styleConfiguration.primaryColor = .systemBlue
      config.styleConfiguration.secondaryColor = .systemTeal
      config.styleConfiguration.gradientColors = [.systemBlue, .systemTeal, .systemPurple]
      config.styleConfiguration.duration = 1.1
      config.styleConfiguration.speed = 1.0
      config.styleConfiguration.lineWidth = 3
      config.styleConfiguration.ringWidth = 4
      config.styleConfiguration.particleCount = 10
      config.styleConfiguration.waveAmplitude = 8
      config.styleConfiguration.repeatCount = .infinity
    }
  }

  /// Creates a common full-screen configuration.
  static func fullScreenConfig(style: FKLoadingAnimatorStyle) -> FKLoadingAnimatorConfiguration {
    var config = FKLoadingAnimatorManager.shared.templateConfiguration
    config.style = style
    config.presentationMode = .fullScreen
    return config
  }
}

// MARK: - UIKit helper

extension UIViewController {
  /// Shows a simple message alert for demo callback events.
  func fk_showLoadingAnimatorAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

