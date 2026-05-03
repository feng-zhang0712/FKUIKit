import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

/// SwiftUI state driving ``FKProgressBarView`` — mirrors the UIKit playground on a smaller surface.
private struct FKProgressBarSwiftUIDemoRoot: View {
  @State private var progress: CGFloat = 0.3
  @State private var buffer: CGFloat = 0.55
  @State private var indeterminate = false
  @State private var configuration: FKProgressBarConfiguration = {
    var c = FKProgressBarConfiguration()
    c.layout.trackThickness = 8
    c.appearance.showsBuffer = true
    c.label.placement = .below
    c.label.format = .percentInteger
    c.motion.animationDuration = 0.3
    return c
  }()
  @State private var buttonTapCount = 0
  @State private var buttonBarConfiguration: FKProgressBarConfiguration = {
    var c = FKProgressBarConfiguration()
    c.layout.trackThickness = 9
    c.label.placement = .centeredOnTrack
    c.label.contentMode = .customTitleWhenIdle
    c.label.customTitle = "Fetch"
    c.interaction.interactionMode = .button
    c.interaction.touchHaptic = .lightImpactOnTouchDown
    c.interaction.minimumTouchTargetSize = CGSize(width: 44, height: 44)
    c.label.font = .preferredFont(forTextStyle: .subheadline)
    c.label.usesSemanticTextColor = true
    return c
  }()

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKProgressBarView(
            progress: $progress,
            bufferProgress: $buffer,
            isIndeterminate: $indeterminate,
            configuration: configuration,
            animateChanges: true
          )
          .frame(minHeight: 52)
        } header: {
          Text("Live bar")
        } footer: {
          Text("FKProgressBarView forwards bindings into UIKit on each update; disable “Animate” in production if you need maximum scroll performance.")
        }

        Section("Values") {
          Slider(value: $progress, in: 0...1)
          Slider(value: $buffer, in: 0...1)
          Toggle("Indeterminate", isOn: $indeterminate)
        }

        Section {
          FKProgressBarView(
            progress: $progress,
            bufferProgress: $buffer,
            isIndeterminate: $indeterminate,
            configuration: buttonBarConfiguration,
            animateChanges: true,
            onPrimaryAction: {
              buttonTapCount += 1
            }
          )
          .frame(minHeight: 48)
        } header: {
          Text("Progress as button")
        } footer: {
          Text("onPrimaryAction increments a counter (\(buttonTapCount)). Configuration uses interactionMode `.button` and a custom idle title.")
        }

        Section("Appearance") {
          Toggle("Gradient fill", isOn: Binding(
            get: { configuration.appearance.fillStyle == .gradientAlongProgress },
            set: { on in
              var c = configuration
              c.appearance.fillStyle = on ? .gradientAlongProgress : .solid
              configuration = c
            }
          ))
          Picker("Variant", selection: Binding(
            get: { configuration.layout.variant == .ring ? 1 : 0 },
            set: { tag in
              var c = configuration
              c.layout.variant = tag == 1 ? .ring : .linear
              configuration = c
            }
          )) {
            Text("Linear").tag(0)
            Text("Ring").tag(1)
          }
          .pickerStyle(.segmented)
        }
      }
      .navigationTitle("SwiftUI")
    }
    .navigationViewStyle(.stack)
  }
}
#endif

/// Hosts the SwiftUI demo when SwiftUI is available in the SDK; otherwise shows a short fallback message.
final class FKProgressBarSwiftUIDemoViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

#if canImport(SwiftUI)
    title = "SwiftUI bridge"
    let host = UIHostingController(rootView: FKProgressBarSwiftUIDemoRoot())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
#else
    title = "SwiftUI"
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.text = "SwiftUI is not available in this build."
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
      label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
    ])
#endif
  }
}
