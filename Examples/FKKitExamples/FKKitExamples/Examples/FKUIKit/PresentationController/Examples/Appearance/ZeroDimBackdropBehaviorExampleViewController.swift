import UIKit
import FKUIKit

/// Demonstrates `zeroDimBackdropBehavior` when `.dim(alpha: 0)` is used.
final class ZeroDimBackdropBehaviorExampleViewController: FKPresentationExamplePageViewController {
  private var dimAlpha: Float = 0
  private var behaviorIndex: Int = 0
  private var backgroundInteractionEnabled: Bool = false
  private var showsBackdropWhenEnabled: Bool = true
  private var activePresentation: FKPresentationController?

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Zero-dim backdrop behavior",
      subtitle: "When dim alpha is 0, choose how the backdrop behaves.",
      notes: "Try: set Dim alpha = 0, then switch behavior. Tap outside to dismiss and observe interaction semantics."
    )

    addView(FKExampleControls.slider(
      title: "Dim alpha",
      value: dimAlpha,
      range: 0...1,
      valueText: { String(format: "%.2f", $0) }
    ) { [weak self] value in
      self?.dimAlpha = value
    })

    addView(FKExampleControls.segmented(
      title: "zeroDimBackdropBehavior",
      items: ["dismissable (default)", "passthrough", "disabled"],
      selectedIndex: behaviorIndex
    ) { [weak self] idx in
      self?.behaviorIndex = idx
    })

    addSectionTitle("Background interaction (advanced)")
    addView(FKExampleControls.toggle(
      title: "backgroundInteraction.isEnabled",
      isOn: backgroundInteractionEnabled
    ) { [weak self] isOn in
      self?.backgroundInteractionEnabled = isOn
    })
    addView(FKExampleControls.toggle(
      title: "showsBackdropWhenEnabled",
      isOn: showsBackdropWhenEnabled
    ) { [weak self] isOn in
      self?.showsBackdropWhenEnabled = isOn
    })

    addView(FKExampleControls.infoLabel(text: """
    Notes:
    - `dismissable`: at dim=0, backdrop stays tappable (tap-outside dismissal still works).
    - `disabled`: at dim=0, backdrop does not dismiss.
    - `passthrough`: at dim=0, treat as passthrough signal (pairs with backgroundInteraction).
    """))

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      let zeroDimBehavior = self.selectedBehavior()
      let needsPassthroughGuard = self.backgroundInteractionEnabled || (self.dimAlpha <= 0 && zeroDimBehavior == .passthrough)

      // Only guard repeated presents when passthrough is active, because in that mode
      // the underlying page remains interactive and can trigger "Present" multiple times.
      if needsPassthroughGuard, let active = activePresentation {
        let isActuallyVisible = active.contentController.viewIfLoaded?.window != nil
        if active.isTransitioning || isActuallyVisible {
          return
        }
        activePresentation = nil
      }

      var configuration = FKPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fixed(300), .full]

      configuration.dismissBehavior = .init(
        allowsTapOutside: true,
        allowsSwipe: true,
        allowsBackdropTap: true
      )

      configuration.backdropStyle = .dim(alpha: CGFloat(self.dimAlpha))
      configuration.zeroDimBackdropBehavior = zeroDimBehavior
      configuration.backgroundInteraction = .init(
        isEnabled: self.backgroundInteractionEnabled,
        showsBackdropWhenEnabled: self.showsBackdropWhenEnabled
      )

      let content = FKExampleLabelContentViewController(text: "Zero-dim behavior demo")
      activePresentation = FKPresentationController.present(
        contentController: content,
        from: self,
        configuration: configuration,
        delegate: nil,
        handlers: .init(didDismiss: { [weak self] in
          self?.activePresentation = nil
        }),
        animated: true,
        completion: nil
      )
    }
  }

  private func selectedBehavior() -> FKPresentationConfiguration.ZeroDimBackdropBehavior {
    switch behaviorIndex {
    case 1: return .passthrough
    case 2: return .disabled
    default: return .dismissable
    }
  }
}

