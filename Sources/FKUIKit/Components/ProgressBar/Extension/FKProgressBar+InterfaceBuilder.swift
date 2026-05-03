import UIKit

// MARK: - Interface Builder

public extension FKProgressBar {
  /// `0` linear, `1` ring.
  @IBInspectable
  var ibVariant: Int {
    get { configuration.layout.variant.rawValue }
    set { configuration.layout.variant = FKProgressBarVariant(rawValue: newValue) ?? .linear }
  }

  /// `0` horizontal, `1` vertical (linear only).
  @IBInspectable
  var ibAxis: Int {
    get { configuration.layout.axis.rawValue }
    set { configuration.layout.axis = FKProgressBarAxis(rawValue: newValue) ?? .horizontal }
  }

  @IBInspectable
  var ibTrackThickness: CGFloat {
    get { configuration.layout.trackThickness }
    set { configuration.layout.trackThickness = max(0.5, newValue) }
  }

  @IBInspectable
  var ibTrackColor: UIColor {
    get { configuration.appearance.trackColor }
    set { configuration.appearance.trackColor = newValue }
  }

  @IBInspectable
  var ibProgressColor: UIColor {
    get { configuration.appearance.progressColor }
    set { configuration.appearance.progressColor = newValue }
  }

  @IBInspectable
  var ibBufferColor: UIColor {
    get { configuration.appearance.bufferColor }
    set { configuration.appearance.bufferColor = newValue }
  }

  @IBInspectable
  var ibShowsBuffer: Bool {
    get { configuration.appearance.showsBuffer }
    set { configuration.appearance.showsBuffer = newValue }
  }

  @IBInspectable
  var ibProgress: CGFloat {
    get { progress }
    set { setProgress(newValue, animated: false) }
  }

  @IBInspectable
  var ibBufferProgress: CGFloat {
    get { bufferProgress }
    set { setBufferProgress(newValue, animated: false) }
  }

  @IBInspectable
  var ibIndeterminate: Bool {
    get { isIndeterminate }
    set { isIndeterminate = newValue }
  }

  @IBInspectable
  var ibRingLineWidth: CGFloat {
    get { configuration.layout.ringLineWidth }
    set { configuration.layout.ringLineWidth = max(0.5, newValue) }
  }

  @IBInspectable
  var ibAnimationDuration: CGFloat {
    get { CGFloat(configuration.motion.animationDuration) }
    set { configuration.motion.animationDuration = TimeInterval(max(0, newValue)) }
  }

  @IBInspectable
  var ibSegmentCount: Int {
    get { configuration.layout.segmentCount }
    set { configuration.layout.segmentCount = max(0, newValue) }
  }

  @IBInspectable
  var ibRespectsReducedMotion: Bool {
    get { configuration.motion.respectsReducedMotion }
    set { configuration.motion.respectsReducedMotion = newValue }
  }

  /// `0` indicator, `1` button (``FKProgressBarInteractionMode`` raw value).
  @IBInspectable
  var ibInteractionMode: Int {
    get { configuration.interaction.interactionMode.rawValue }
    set { configuration.interaction.interactionMode = FKProgressBarInteractionMode(rawValue: newValue) ?? .indicator }
  }

  /// ``FKProgressBarLabelContentMode`` raw value (`0` formatted progress … `3` title + progress subtitle).
  @IBInspectable
  var ibLabelContentMode: Int {
    get { configuration.label.contentMode.rawValue }
    set { configuration.label.contentMode = FKProgressBarLabelContentMode(rawValue: newValue) ?? .formattedProgress }
  }

  @IBInspectable
  var ibCustomTitle: String {
    get { configuration.label.customTitle }
    set { configuration.label.customTitle = newValue }
  }
}
