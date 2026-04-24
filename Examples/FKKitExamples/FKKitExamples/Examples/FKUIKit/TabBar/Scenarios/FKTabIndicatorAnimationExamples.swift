import UIKit
import FKUIKit

final class FKTabBarIndicatorAnimationExampleViewController: UIViewController {
  private let tabView: FKTabBar
  private var configuration = FKTabBarConfiguration()
  private var lineFollowMode: FKTabBarIndicatorFollowMode = .trackSelectedFrame
  private var selectedKind: FKTabBarIndicatorStyleKind = .line
  private var lineHorizontalInset: CGFloat = 10
  private var backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
  private var backgroundCornerRadius: CGFloat = 999
  private var stressWorkItem: DispatchWorkItem?

  init() {
    tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(12), selectedIndex: 0, configuration: configuration)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Indicator and animation"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Indicator and animation strategy"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Change style/follow mode and drag TabBar horizontally without selecting to verify indicator follows selected tab frame."))

    let styleButtons = UIStackView()
    styleButtons.axis = .vertical
    styleButtons.spacing = 6
    for kind in FKTabBarIndicatorStyleKind.allCases {
      styleButtons.addArrangedSubview(
        FKTabBarExampleSupport.actionButton("Style: \(kind.rawValue)") { [weak self] in
          guard let self else { return }
          self.selectedKind = kind
          self.applyIndicatorStyle()
        }
      )
    }
    stack.addArrangedSubview(styleButtons)

    let bgShape = UISegmentedControl(items: ["Bg Capsule", "Bg Rounded"])
    bgShape.selectedSegmentIndex = 0
    bgShape.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.backgroundCornerRadius = control.selectedSegmentIndex == 0 ? 999 : 10
      // If current style is a background highlight, re-apply immediately so the change is visible.
      self.applyIndicatorStyle()
    }, for: .valueChanged)
    stack.addArrangedSubview(bgShape)

    let lineInsetSlider = UISlider()
    lineInsetSlider.minimumValue = 0
    lineInsetSlider.maximumValue = 24
    lineInsetSlider.value = Float(lineHorizontalInset)
    lineInsetSlider.addAction(UIAction { [weak self] action in
      guard let self, let slider = action.sender as? UISlider else { return }
      self.lineHorizontalInset = CGFloat(slider.value)
      self.applyIndicatorStyle()
    }, for: .valueChanged)
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Line horizontal inset"))
    stack.addArrangedSubview(lineInsetSlider)

    let bgInsetTop = makeInsetSlider(title: "Background top inset", value: backgroundInsets.top) { [weak self] v in
      self?.backgroundInsets.top = v
      self?.applyIndicatorStyle()
    }
    stack.addArrangedSubview(bgInsetTop)
    let bgInsetLeading = makeInsetSlider(title: "Background leading inset", value: backgroundInsets.leading) { [weak self] v in
      self?.backgroundInsets.leading = v
      self?.applyIndicatorStyle()
    }
    stack.addArrangedSubview(bgInsetLeading)
    let bgInsetBottom = makeInsetSlider(title: "Background bottom inset", value: backgroundInsets.bottom) { [weak self] v in
      self?.backgroundInsets.bottom = v
      self?.applyIndicatorStyle()
    }
    stack.addArrangedSubview(bgInsetBottom)
    let bgInsetTrailing = makeInsetSlider(title: "Background trailing inset", value: backgroundInsets.trailing) { [weak self] v in
      self?.backgroundInsets.trailing = v
      self?.applyIndicatorStyle()
    }
    stack.addArrangedSubview(bgInsetTrailing)

    let follow = UISegmentedControl(items: ["Selected", "Content", "Progress", "Locked"])
    follow.selectedSegmentIndex = 0
    follow.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      switch control.selectedSegmentIndex {
      case 1: self.lineFollowMode = .trackContentFrame
      case 2: self.lineFollowMode = .trackContentProgress
      case 3: self.lineFollowMode = .lockedUntilSettle
      default: self.lineFollowMode = .trackSelectedFrame
      }
      self.applyLineStyle()
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(follow)

    let anim = UISegmentedControl(items: ["None", "Linear", "Spring"])
    anim.selectedSegmentIndex = 2
    anim.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      switch control.selectedSegmentIndex {
      case 0: self.configuration.animation.indicatorAnimation = .none
      case 1: self.configuration.animation.indicatorAnimation = .linear(duration: 0.22)
      default: self.configuration.animation.indicatorAnimation = .spring(duration: 0.3, damping: 0.85, velocity: 0.15)
      }
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(anim)

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Stress tap selection x24") { [weak self] in
      guard let self else { return }
      self.stressWorkItem?.cancel()
      let work = DispatchWorkItem { [weak self] in
        guard let self else { return }
        for step in 0..<24 {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.045 * Double(step)) { [weak self] in
            guard let self else { return }
            self.tabView.setSelectedIndex(step % 6, animated: true, reason: .programmatic)
          }
        }
      }
      self.stressWorkItem = work
      DispatchQueue.main.async(execute: work)
    })

    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Try manually dragging the tab strip left/right while keeping the same selected tab."))

    tabView.translatesAutoresizingMaskIntoConstraints = false
    tabView.indicatorViewProvider = { id in
      guard id == "demo.custom" else { return nil }
      let view = UIView()
      view.backgroundColor = .systemYellow.withAlphaComponent(0.5)
      view.layer.cornerRadius = 8
      return view
    }
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 50),
    ])
    applyIndicatorStyle()
  }

  private func applyLineStyle() {
    configuration.appearance.indicatorStyle = .line(
      FKTabBarLineIndicatorConfiguration(
        position: .bottom,
        thickness: 3,
        fill: .gradient(colors: [.systemBlue, .systemTeal], startPoint: .zero, endPoint: .init(x: 1, y: 0)),
        leadingInset: lineHorizontalInset,
        trailingInset: lineHorizontalInset,
        cornerRadius: 1.5,
        followMode: lineFollowMode
      )
    )
  }

  private func applyIndicatorStyle() {
    switch selectedKind {
    case .none:
      configuration.appearance.indicatorStyle = .none
    case .line:
      applyLineStyle()
    case .backgroundHighlight:
      configuration.appearance.indicatorStyle = .backgroundHighlight(
        FKTabBarBackgroundIndicatorConfiguration(
          insets: backgroundInsets,
          cornerRadius: backgroundCornerRadius,
          fill: .solid(.tertiarySystemFill)
        )
      )
    case .gradientHighlight:
      configuration.appearance.indicatorStyle = .gradientHighlight(
        FKTabBarBackgroundIndicatorConfiguration(
          insets: backgroundInsets,
          cornerRadius: backgroundCornerRadius,
          fill: .gradient(colors: [.systemPink, .systemPurple], startPoint: .init(x: 0, y: 0.5), endPoint: .init(x: 1, y: 0.5)),
          shadowColor: .black,
          shadowOpacity: 0.15,
          shadowRadius: 4,
          shadowOffset: .init(width: 0, height: 2)
        )
      )
    case .pill:
      configuration.appearance.indicatorStyle = .pill(
        FKTabBarBackgroundIndicatorConfiguration(
          insets: backgroundInsets,
          cornerRadius: 999,
          fill: .solid(.secondarySystemFill)
        )
      )
    case .custom:
      configuration.appearance.indicatorStyle = .custom(id: "demo.custom")
    }
    tabView.configuration = configuration
  }

  private func makeInsetSlider(title: String, value: CGFloat, onChange: @escaping (CGFloat) -> Void) -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 4
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel(title))
    let slider = UISlider()
    slider.minimumValue = 0
    slider.maximumValue = 24
    slider.value = Float(value)
    slider.addAction(UIAction { action in
      guard let s = action.sender as? UISlider else { return }
      onChange(CGFloat(s.value))
    }, for: .valueChanged)
    stack.addArrangedSubview(slider)
    return stack
  }
}

final class FKTabBarReduceMotionExampleViewController: UIViewController {
  private let tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(5), selectedIndex: 0)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Reduce Motion"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Reduce Motion downgrade"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Turn on iOS Reduce Motion in Settings to verify indicator animations are simplified automatically."))

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 50),
    ])
  }
}

