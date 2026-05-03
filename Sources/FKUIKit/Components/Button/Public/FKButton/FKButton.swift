//
// FKButton.swift
//
// Type core: nested types, stored state, initializers, `deinit`, and highlighted-state handling.
// Behavior is split across sibling files in this folder (`FKButton+*.swift`) by responsibility.
//

import AudioToolbox
import UIKit

/// A `UIControl` subclass with explicit, state-keyed content and styling.
///
/// Design goals: predictable layout, safe primary-action throttling, strong accessibility defaults,
/// and opt-in feedback (haptics, sound, pointer) that stays off until you turn it on.
///
/// ## Content
/// `content` selects the layout shape: text only, image only, text+image (leading, trailing, or both sides), or a single custom view.
///
/// ## State model
/// Register values per exact `UIControl.State` (including combined states such as `.selected.union(.highlighted)`).
/// Use `setModel(_:for:)` to apply a bundle, or the `setTitle` / `setImage` / `setAppearance` family for fine-grained updates.
/// Passing `nil` to `setModel(_:for:)` removes **all** registrations for that exact state so resolution falls back (e.g. to `.normal`).
///
/// ## Appearance
/// `setAppearance(_:for:)` and `setAppearances(_:)` control background (solid or gradient), border, corner, shadow, insets, and press feedback.
///
/// ## Interaction
/// - `minimumTapInterval` throttles **primary** actions (`.touchUpInside` / `.primaryActionTriggered`) only; other control events are untouched.
/// - `hitTestEdgeInsets` and per-appearance `hitTestOutsets` enlarge the tappable region without changing layout.
/// - Long-press: `onLongPressBegan`, `onLongPressRepeatTick`, `onLongPressEnded`.
///
/// ## Alignment
/// Inherited `contentHorizontalAlignment` and `contentVerticalAlignment` position the internal stack inside `Appearance.contentInsets`
/// (default `.center` / `.center`). Use `.fill` when the stack should span the padded area.
///
/// ## Loading
/// `setLoading(_:presentation:)` shows a built-in activity indicator, blocks interaction, and supports overlay or content-replacement styles.
/// `performWhileLoading` wraps async work.
///
/// ## Global defaults
/// `FKButton.GlobalStyle` is applied during initialization (tap interval, long-press timing, disabled dimming, optional default appearances).
///
/// The class is `open` for subclassing (e.g. custom `intrinsicContentSize` or hit testing).
@IBDesignable open class FKButton: UIControl {
  // MARK: - Internal typealiases

  typealias StateKey = UInt
  typealias StatefulValues<T> = [StateKey: T]

  // MARK: - State key canonicalization

  /// Canonicalizes `UIControl.State` into an internal key for state maps.
  /// Currently uses `rawValue` directly to support arbitrary user-defined combinations.
  static func makeStateKey(_ state: UIControl.State) -> StateKey { state.rawValue }

  // MARK: - Public nested types

  /// The layout axis for the button content (affects how image and title are arranged).
  ///
  /// - `horizontal`: laid out horizontally.
  /// - `vertical`: laid out vertically.
  ///
  /// Under `.textAndImage`, it determines relative placement of text and image.
  /// Other `content.kind` values have smaller or no effect.
  public enum Axis {
    case horizontal
    case vertical
  }
  
  /// Image slots (semantics for `setImage` / `setLeadingImage` / `setTrailingImage`).
  ///
  /// - `center`: centered image slot (used only when needed by `.imageOnly` or some `.textAndImage` cases).
  /// - `leading`: image slot placed adjacent to the title on the leading side (maps to different physical directions across `axis`).
  /// - `trailing`: image slot placed adjacent to the title on the trailing side (maps to different physical directions across `axis`).
  public enum ImageSlot {
    case center
    case leading
    case trailing
  }

  /// Resolves state lookup candidates for stateful maps.
  /// Return order must be from high to low priority, and may include combined candidates
  /// such as `.selected.union(.highlighted)`.
  public typealias StateResolutionProvider = (_ isEnabled: Bool, _ isSelected: Bool, _ isHighlighted: Bool) -> [UIControl.State]

  /// Label roles rendered by `FKButton`.
  public enum LabelRole: Sendable {
    case title
    case subtitle
  }

  // MARK: - Public configuration

  /// Content composition model. Updating this rebinds internal subviews immediately.
  public var content: FKButton.Content {
    didSet {
      requestVisualRefresh(rebuildContentLayout: true)
    }
  }
  
  /// Layout axis for the internal `UIStackView`.
  public var axis: Axis = .horizontal {
    didSet { applyAxis() }
  }

  /// Optional custom provider for state lookup candidates.
  ///
  /// - Important: Return candidates from highest to lowest priority.
  /// - Note: You may include combined states such as `.selected.union(.highlighted)`.
  ///
  /// When `nil`, the default candidates follow UIKit intuition:
  /// `disabled` > `selected+highlighted` > `highlighted` > `selected` > `normal`.
  public var stateResolutionProvider: StateResolutionProvider? {
    didSet { requestVisualRefresh() }
  }

  /// Controls how `accessibilityLabel`, `accessibilityValue`, and `accessibilityHint` are computed.
  public var accessibilityConfiguration: FKButtonAccessibilityConfiguration = .init() {
    didSet { requestVisualRefresh() }
  }

  /// Optional haptics configuration. Defaults to off.
  public var hapticsConfiguration: FKButtonHapticsConfiguration = .init() {
    didSet {
      guard hapticsConfiguration.impactStyle != oldValue.impactStyle else { return }
      impactFeedbackGenerator = UIImpactFeedbackGenerator(style: hapticsConfiguration.impactStyle)
      impactFeedbackGenerator.prepare()
    }
  }

  /// Optional sound-feedback configuration. Defaults to off.
  public var soundFeedbackConfiguration: FKButtonSoundFeedbackConfiguration = .init() {
    didSet { syncSoundFeedbackResourcesIfNeeded() }
  }

  /// Optional pointer interaction configuration. Defaults to off.
  public var pointerConfiguration: FKButtonPointerConfiguration = .init() {
    didSet { syncPointerInteractionIfNeeded() }
  }

  // MARK: - View hierarchy (container + stack)

  /// Hosts `stackView`; `Appearance.contentInsets` pin this view to `FKButton` edges so `contentHorizontalAlignment` /
  /// `contentVerticalAlignment` can position the stack inside without fighting appearance insets.
  let contentContainerView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.isUserInteractionEnabled = false
    v.backgroundColor = .clear
    return v
  }()

  let stackView = UIStackView()
  var contentAlignmentConstraints: [NSLayoutConstraint] = []

  // MARK: - Lazily created content subviews

  /// Created only when `content.kind` is `.textOnly` / `.textAndImage` (added via the title container).
  /// When switching to `.imageOnly` / `.custom`, it is released via `releaseTitleLabel()`.
  public internal(set) var titleLabel: UILabel?
  
  /// Subtitle label shown below `titleLabel`.
  /// Layout: subtitle is always constrained beneath `titleLabel`.
  public internal(set) var subtitleLabel: UILabel?
  
  /// Title container (subtitle is always below the title).
  var titleContainerView: UIView?
  
  /// Created only when the corresponding slot is needed.
  /// Recovered via `clearImageSlot(_:)` / `releaseAllImageSlots()`.
  public internal(set) var imageView: UIImageView?
  public internal(set) var leadingImageView: UIImageView?
  public internal(set) var trailingImageView: UIImageView?

  var titleLabelTopConstraint: NSLayoutConstraint?
  var titleLabelLeadingConstraint: NSLayoutConstraint?
  var titleLabelTrailingConstraint: NSLayoutConstraint?
  var titleLabelBottomConstraintToContainer: NSLayoutConstraint?
  var subtitleTopConstraint: NSLayoutConstraint?
  var subtitleLeadingConstraint: NSLayoutConstraint?
  var subtitleTrailingConstraint: NSLayoutConstraint?
  var subtitleBottomConstraint: NSLayoutConstraint?

  /// Created only for `Content.Kind.custom`.
  /// Released via `releaseCustomContentHost()`.
  var customContentHost: FKButtonCustomContentHostView?
  var embeddedCustomContentView: UIView?

  // MARK: - Stateful value storage

  var appearanceByState: StatefulValues<Appearance> = [UIControl.State.normal.rawValue: .default]

  var titleByState: StatefulValues<LabelAttributes> = [:]
  var subtitleByState: StatefulValues<LabelAttributes> = [:]
  var customContentByState: StatefulValues<CustomContent> = [:]

  /// Store state data per slot.
  /// No pre-allocation (consistent with on-demand view creation); written on the first `setImage`.
  var imagesBySlotAndState: [ImageSlot: StatefulValues<ImageAttributes>] = [:]
  
  var imageConstraints: [ObjectIdentifier: [NSLayoutConstraint]] = [:]
  
  var topConstraint: NSLayoutConstraint?
  var leadingConstraint: NSLayoutConstraint?
  var trailingConstraint: NSLayoutConstraint?
  var bottomConstraint: NSLayoutConstraint?
  var batchUpdateDepth = 0
  var needsVisualRefresh = false
  var needsContentLayoutRefresh = false

  // MARK: - Interaction & behavior configuration

  /// Ignores duplicate `touchUpInside` / `primaryActionTriggered` deliveries within this interval (seconds). `0` disables throttling.
  ///
  /// Throttling is applied in `sendAction(_:to:for:)` because UIKit often dispatches `UIAction` / target-action by calling
  /// `sendAction` directly, without going through `sendActions(for:)` (so overriding only `sendActions` would not intercept taps).
  public var minimumTapInterval: TimeInterval = 0
  var lastPrimaryActionDeliveryTime: CFAbsoluteTime = 0
  /// `UIEvent.timestamp` of the last accepted user interaction wave (touches / presses); used to allow every `sendAction` in the same event.
  var lastThrottledInteractionEventTimestamp: TimeInterval = -1

  /// Expands or shrinks the tappable rect in `point(inside:with:)` without changing layout.
  /// Negative insets enlarge the target (same semantics as `CGRect.inset(by:)` with negative edges).
  public var hitTestEdgeInsets: UIEdgeInsets = .zero

  /// When `true`, applies `disabledDimmingAlpha` on top of resolved appearance while `isEnabled == false` (skipped while `isLoading`).
  public var automaticallyDimsWhenDisabled: Bool = true
  /// Multiplier applied to resolved appearance alpha when `automaticallyDimsWhenDisabled` is active.
  public var disabledDimmingAlpha: CGFloat = 0.55

  /// `true` while `setLoading(true, …)` is active; primary actions are suppressed and interaction is forced off until cleared.
  public internal(set) var isLoading: Bool = false
  /// Spinner + optional status row layout while loading. Ignored until the next time loading becomes active unless you call `applyLoadingPresentation(_:)`.
  public var loadingPresentationStyle: LoadingPresentationStyle = .overlay(dimmedContentAlpha: 0.35)
  /// When non-`nil`, sets `UIActivityIndicatorView.color` for the built-in loading spinner. When `nil`, the system default tint is used.
  public var loadingActivityIndicatorColor: UIColor? {
    didSet { syncLoadingActivityIndicatorColor() }
  }
  var userInteractionEnabledBeforeLoading: Bool = true

  /// Minimum finger-down duration before `UILongPressGestureRecognizer` enters `.began`.
  public var longPressMinimumDuration: TimeInterval = 0.5 {
    didSet { longPressRecognizer.minimumPressDuration = longPressMinimumDuration }
  }

  /// Interval between `onLongPressRepeatTick` callbacks after recognition begins. `0` disables repeat ticks.
  public var longPressRepeatTickInterval: TimeInterval = 0.1

  /// Invoked when a long press is first recognized (after `longPressMinimumDuration`).
  public var onLongPressBegan: (() -> Void)?
  /// Invoked when the long-press gesture ends, fails, or is cancelled.
  public var onLongPressEnded: (() -> Void)?
  /// Invoked once when recognition begins and on each timer tick while the finger stays down (see `longPressRepeatTickInterval`).
  public var onLongPressRepeatTick: (() -> Void)?

  let backgroundGradientLayer = CAGradientLayer()
  let loadingOverlayHost = UIView()
  let loadingRowStack = UIStackView()
  let loadingMessageLabel = UILabel()
  let loadingIndicator = UIActivityIndicatorView(style: .medium)
  let longPressRecognizer = UILongPressGestureRecognizer()
  /// `Timer` is not `Sendable`; only created/invalidated on the main run loop for long-press repeat.
  nonisolated(unsafe) var longPressRepeatTimer: Timer?

  static let paddedImageCache = NSCache<NSString, UIImage>()
  /// Internal feedback trigger source used to route interaction feedback.
  ///
  /// `FKButton` supports two independent feedback channels (haptics and sound),
  /// and this enum keeps the dispatch path unified for both channels.
  enum InteractionFeedbackTrigger {
    /// Triggered when the button first enters highlighted state.
    case pressDown
    /// Triggered when a primary action is delivered (`touchUpInside` / `primaryActionTriggered`).
    case primaryAction
  }

  // Tracks which control events are currently being dispatched. Used to throttle primary events only.
  var currentlySendingControlEvents: UIControl.Event = []

  var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  var cachedPressDownSoundURL: URL?
  var cachedPressDownSoundID: SystemSoundID?
  var cachedPrimaryActionSoundURL: URL?
  var cachedPrimaryActionSoundID: SystemSoundID?

  @available(iOS 13.4, *)
  var pointerInteraction: UIPointerInteraction?

  var isPointerHovered: Bool = false {
    didSet { applyPointerHoverVisualsIfNeeded() }
  }

  // MARK: - Initialization

  /// Creates a button with default content (`.textOnly`).
  public init() {
    self.content = .default
    super.init(frame: .zero)
    commonInit()
  }
  
  /// Creates a button with a custom frame and default content (`.textOnly`).
  public override init(frame: CGRect) {
    self.content = .default
    super.init(frame: frame)
    commonInit()
  }
  
  /// Creates a button with an initial content model.
  public init(content: FKButton.Content) {
    self.content = content
    super.init(frame: .zero)
    commonInit()
  }
  
  /// Storyboard/XIB initializer.
  public required init?(coder: NSCoder) {
    self.content = .default
    super.init(coder: coder)
    commonInit()
  }

  // MARK: - Highlight-driven UIControl overrides

  open override var isEnabled: Bool {
    didSet {
      requestVisualRefresh()
    }
  }
  
  open override var isSelected: Bool {
    didSet {
      requestVisualRefresh()
    }
  }
  
  open override var isHighlighted: Bool {
    didSet {
      requestVisualRefresh()
      let appearance = resolveAppearance()
      let feedback = appearance.interaction.isHighlightFeedbackEnabled
      let shouldScale = !UIAccessibility.isReduceMotionEnabled
      if isHighlighted, feedback {
        emitInteractionFeedback(for: .pressDown)
      }
      UIView.animate(withDuration: 0.12) {
        self.alpha = self.resolvedAlpha(for: appearance) * self.disabledVisualMultiplier()
        self.transform = (self.isHighlighted && feedback && shouldScale)
          ? CGAffineTransform(scaleX: appearance.interaction.pressedScale, y: appearance.interaction.pressedScale)
          : .identity
      }
    }
  }
  deinit {
    longPressRepeatTimer?.invalidate()
    if let cachedPressDownSoundID {
      AudioServicesDisposeSystemSoundID(cachedPressDownSoundID)
    }
    if let cachedPrimaryActionSoundID {
      AudioServicesDisposeSystemSoundID(cachedPrimaryActionSoundID)
    }
  }
}
