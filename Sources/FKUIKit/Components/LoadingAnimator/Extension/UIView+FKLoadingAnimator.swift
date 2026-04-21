//
// UIView+FKLoadingAnimator.swift
//

import ObjectiveC.runtime
import UIKit

/// Associated-object keys used by `UIView` loading animator hosting APIs.
private enum FKLoadingHostKeys {
  /// Key for embedded `FKLoadingAnimatorView`.
  nonisolated(unsafe) static var embeddedView: UInt8 = 0
  /// Key for full-screen `FKLoadingOverlayView`.
  nonisolated(unsafe) static var overlayView: UInt8 = 0
}

public extension UIView {
  /// Returns active embedded animator view if created.
  var fk_loadingAnimatorView: FKLoadingAnimatorView? {
    objc_getAssociatedObject(self, &FKLoadingHostKeys.embeddedView) as? FKLoadingAnimatorView
  }

  /// Shows loading animation on the host view.
  ///
  /// - Parameters:
  ///   - configuration: Optional screen-level config. Defaults to global template.
  ///   - configure: Optional closure to mutate config before presenting.
  func fk_showLoadingAnimator(
    configuration: FKLoadingAnimatorConfiguration? = nil,
    configure: ((inout FKLoadingAnimatorConfiguration) -> Void)? = nil
  ) {
    fk_loadingPerformOnMain { [weak self] in
      guard let self else { return }
      var config = configuration ?? FKLoadingAnimatorManager.shared.templateConfiguration
      configure?(&config)
      // Presentation mode decides whether loading is embedded or mask-based.
      switch config.presentationMode {
      case .embedded:
        self.fk_showEmbeddedAnimator(config)
      case .fullScreen:
        self.fk_showFullscreenAnimator(config)
      }
    }
  }

  /// Hides active animator from both embedded and full-screen hosts.
  ///
  /// - Parameter animated: Whether removal uses fade-out animation.
  func fk_hideLoadingAnimator(animated: Bool = true) {
    fk_loadingPerformOnMain { [weak self] in
      guard let self else { return }

      if let embedded = self.fk_loadingAnimatorView {
        embedded.stop()
        self.fk_removeAnimatorView(embedded, animated: animated)
        objc_setAssociatedObject(self, &FKLoadingHostKeys.embeddedView, nil, .OBJC_ASSOCIATION_ASSIGN)
      }

      if let overlay = objc_getAssociatedObject(self, &FKLoadingHostKeys.overlayView) as? FKLoadingOverlayView {
        overlay.animatorView.stop()
        self.fk_removeAnimatorView(overlay, animated: animated)
        objc_setAssociatedObject(self, &FKLoadingHostKeys.overlayView, nil, .OBJC_ASSOCIATION_ASSIGN)
      }
    }
  }

  /// Switches style on currently visible animator.
  ///
  /// - Parameters:
  ///   - style: Style to switch to.
  ///   - autoRestart: Whether animation restarts automatically.
  func fk_switchLoadingStyle(_ style: FKLoadingAnimatorStyle, autoRestart: Bool = true) {
    fk_loadingPerformOnMain { [weak self] in
      guard let self else { return }
      if let embedded = self.fk_loadingAnimatorView {
        embedded.switchStyle(style, autoRestart: autoRestart)
      } else if let overlay = objc_getAssociatedObject(self, &FKLoadingHostKeys.overlayView) as? FKLoadingOverlayView {
        overlay.animatorView.switchStyle(style, autoRestart: autoRestart)
      }
    }
  }

  /// Updates progress value for progress ring style.
  ///
  /// - Parameter progress: Normalized progress in `0...1`.
  func fk_updateLoadingProgress(_ progress: CGFloat) {
    fk_loadingPerformOnMain { [weak self] in
      guard let self else { return }
      if let embedded = self.fk_loadingAnimatorView {
        embedded.setProgress(progress)
      } else if let overlay = objc_getAssociatedObject(self, &FKLoadingHostKeys.overlayView) as? FKLoadingOverlayView {
        overlay.animatorView.setProgress(progress)
      }
    }
  }

  /// Manual start.
  ///
  /// Starts whichever animator host (embedded or overlay) currently exists.
  func fk_startLoadingAnimation() {
    fk_loadingPerformOnMain { [weak self] in
      guard let self else { return }
      self.fk_loadingAnimatorView?.start()
      (objc_getAssociatedObject(self, &FKLoadingHostKeys.overlayView) as? FKLoadingOverlayView)?.animatorView.start()
    }
  }

  /// Manual stop.
  ///
  /// Stops whichever animator host (embedded or overlay) currently exists.
  func fk_stopLoadingAnimation() {
    fk_loadingPerformOnMain { [weak self] in
      guard let self else { return }
      self.fk_loadingAnimatorView?.stop()
      (objc_getAssociatedObject(self, &FKLoadingHostKeys.overlayView) as? FKLoadingOverlayView)?.animatorView.stop()
    }
  }

  /// Manual pause.
  ///
  /// Pauses whichever animator host (embedded or overlay) currently exists.
  func fk_pauseLoadingAnimation() {
    fk_loadingPerformOnMain { [weak self] in
      guard let self else { return }
      self.fk_loadingAnimatorView?.pause()
      (objc_getAssociatedObject(self, &FKLoadingHostKeys.overlayView) as? FKLoadingOverlayView)?.animatorView.pause()
    }
  }

  /// Manual resume.
  ///
  /// Resumes whichever animator host (embedded or overlay) currently exists.
  func fk_resumeLoadingAnimation() {
    fk_loadingPerformOnMain { [weak self] in
      guard let self else { return }
      self.fk_loadingAnimatorView?.resume()
      (objc_getAssociatedObject(self, &FKLoadingHostKeys.overlayView) as? FKLoadingOverlayView)?.animatorView.resume()
    }
  }
}

private extension UIView {
  /// Creates or reuses an embedded animator view and applies configuration.
  ///
  /// - Parameter configuration: Configuration to present.
  func fk_showEmbeddedAnimator(_ configuration: FKLoadingAnimatorConfiguration) {
    let animator = fk_loadingAnimatorView ?? {
      let view = FKLoadingAnimatorView()
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: topAnchor),
        view.leadingAnchor.constraint(equalTo: leadingAnchor),
        view.trailingAnchor.constraint(equalTo: trailingAnchor),
        view.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
      objc_setAssociatedObject(self, &FKLoadingHostKeys.embeddedView, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return view
    }()

    // Keep instance reuse for table/collection reuse scenarios to prevent state mismatch.
    animator.isHidden = false
    animator.alpha = 1
    // Keep loading view above host subviews (e.g. UIButton title/image) to avoid visual offset illusion.
    animator.layer.zPosition = 999
    animator.apply(configuration)
    bringSubviewToFront(animator)
  }

  /// Creates or reuses a full-screen overlay animator and applies configuration.
  ///
  /// - Parameter configuration: Configuration to present.
  func fk_showFullscreenAnimator(_ configuration: FKLoadingAnimatorConfiguration) {
    let overlay = (objc_getAssociatedObject(self, &FKLoadingHostKeys.overlayView) as? FKLoadingOverlayView) ?? {
      let view = FKLoadingOverlayView()
      addSubview(view)
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: topAnchor),
        view.leadingAnchor.constraint(equalTo: leadingAnchor),
        view.trailingAnchor.constraint(equalTo: trailingAnchor),
        view.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
      objc_setAssociatedObject(self, &FKLoadingHostKeys.overlayView, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return view
    }()

    // Tap behavior is dynamic and controlled by the current configuration.
    overlay.onMaskTap = { [weak self] in
      guard configuration.allowsMaskTapToStop else { return }
      self?.fk_hideLoadingAnimator()
    }
    overlay.isHidden = false
    overlay.alpha = 1
    // Keep overlay at highest local z-order in complex container hierarchies.
    overlay.layer.zPosition = 999
    overlay.apply(configuration)
    bringSubviewToFront(overlay)
  }

  /// Removes animator host view from hierarchy.
  ///
  /// - Parameters:
  ///   - view: View to remove.
  ///   - animated: Whether to fade out before removal.
  func fk_removeAnimatorView(_ view: UIView, animated: Bool) {
    if animated {
      UIView.animate(
        withDuration: 0.2,
        delay: 0,
        options: [.allowUserInteraction, .beginFromCurrentState],
        animations: { view.alpha = 0 },
        completion: { _ in
          view.removeFromSuperview()
          view.alpha = 1
        }
      )
    } else {
      view.removeFromSuperview()
    }
  }
}
