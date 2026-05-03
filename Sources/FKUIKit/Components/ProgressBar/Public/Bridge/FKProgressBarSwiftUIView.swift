#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKProgressBar`` / ``FKProgressBarConfiguration``.
public struct FKProgressBarView: UIViewRepresentable {
  @Binding public var progress: CGFloat
  @Binding public var bufferProgress: CGFloat
  @Binding public var isIndeterminate: Bool
  public var configuration: FKProgressBarConfiguration
  public var animateChanges: Bool
  /// When non-nil, wired to ``UIControl/Event/primaryActionTriggered`` (use with ``FKProgressBarInteractionConfiguration/interactionMode`` ``FKProgressBarInteractionMode/button``).
  public var onPrimaryAction: (() -> Void)?

  public init(
    progress: Binding<CGFloat>,
    bufferProgress: Binding<CGFloat> = .constant(0),
    isIndeterminate: Binding<Bool> = .constant(false),
    configuration: FKProgressBarConfiguration = FKProgressBarDefaults.configuration,
    animateChanges: Bool = true,
    onPrimaryAction: (() -> Void)? = nil
  ) {
    _progress = progress
    _bufferProgress = bufferProgress
    _isIndeterminate = isIndeterminate
    self.configuration = configuration
    self.animateChanges = animateChanges
    self.onPrimaryAction = onPrimaryAction
  }

  public final class Coordinator: NSObject {
    var onPrimaryAction: (() -> Void)?
    @objc func handlePrimary(_ sender: UIControl) {
      onPrimaryAction?()
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  public func makeUIView(context: Context) -> FKProgressBar {
    let v = FKProgressBar(configuration: configuration)
    v.setProgress(progress, buffer: bufferProgress, animated: false)
    v.isIndeterminate = isIndeterminate
    context.coordinator.onPrimaryAction = onPrimaryAction
    if onPrimaryAction != nil {
      v.addTarget(context.coordinator, action: #selector(Coordinator.handlePrimary(_:)), for: .primaryActionTriggered)
    }
    return v
  }

  public func updateUIView(_ uiView: FKProgressBar, context: Context) {
    context.coordinator.onPrimaryAction = onPrimaryAction
    uiView.removeTarget(context.coordinator, action: #selector(Coordinator.handlePrimary(_:)), for: .primaryActionTriggered)
    if onPrimaryAction != nil {
      uiView.addTarget(context.coordinator, action: #selector(Coordinator.handlePrimary(_:)), for: .primaryActionTriggered)
    }
    uiView.configuration = configuration
    uiView.isIndeterminate = isIndeterminate
    uiView.setProgress(progress, buffer: bufferProgress, animated: animateChanges)
  }

  public static func dismantleUIView(_ uiView: FKProgressBar, coordinator: Coordinator) {
    uiView.removeTarget(coordinator, action: #selector(Coordinator.handlePrimary(_:)), for: .primaryActionTriggered)
  }
}
#endif
