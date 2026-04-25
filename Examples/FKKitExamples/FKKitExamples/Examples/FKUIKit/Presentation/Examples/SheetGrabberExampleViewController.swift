import UIKit
import FKUIKit

/// Shows how to toggle the sheet grabber and tune its size/inset.
///
/// Key highlights:
/// - `sheet.showsGrabber` on/off
/// - Grabber sizing is a small but impactful UX detail.
final class SheetGrabberExampleViewController: FKPresentationExamplePageViewController {
  private var showsGrabber = true
  private var grabberWidth: Float = 36
  private var grabberTopInset: Float = 8

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Grabber on/off",
      subtitle: "A small control that communicates affordance.",
      notes: "Turn it off for fully custom chrome, or when your content already implies drag affordance."
    )

    addView(
      FKExampleControls.toggle(
        title: "Shows grabber",
        isOn: showsGrabber
      ) { [weak self] isOn in
        self?.showsGrabber = isOn
      }
    )

    addView(
      FKExampleControls.slider(
        title: "Grabber width",
        value: grabberWidth,
        range: 24...64,
        valueText: { "\(Int($0)) pt" }
      ) { [weak self] v in
        self?.grabberWidth = v
      }
    )

    addView(
      FKExampleControls.slider(
        title: "Grabber top inset",
        value: grabberTopInset,
        range: 0...20,
        valueText: { "\(Int($0)) pt" }
      ) { [weak self] v in
        self?.grabberTopInset = v
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var config = FKPresentationConfiguration.default
      config.mode = .bottomSheet
      config.sheet.detents = [.fixed(260), .full]
      config.sheet.showsGrabber = self.showsGrabber
      config.sheet.grabberSize = .init(width: CGFloat(self.grabberWidth), height: 5)
      config.sheet.grabberTopInset = CGFloat(self.grabberTopInset)
      _ = FKPresentationExampleHelpers.present(from: self, title: "Grabber", configuration: config)
    }
  }
}

