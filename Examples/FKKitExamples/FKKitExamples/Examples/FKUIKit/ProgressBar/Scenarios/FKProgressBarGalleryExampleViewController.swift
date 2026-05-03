import FKUIKit
import UIKit

fileprivate struct FKProgressBarGalleryRow {
  let title: String
  let subtitle: String
  let configuration: FKProgressBarConfiguration
  let progress: CGFloat
  let buffer: CGFloat
  let indeterminate: Bool
}

/// Matches ``FKProgressBar`` layout rules closely enough for table rows: fixed height must cover track/ring **and** any label that extends outside the track rect.
fileprivate enum FKProgressBarGalleryBarHeight {
  static func required(for c: FKProgressBarConfiguration) -> CGFloat {
    let ins = c.layout.contentInsets
    let lh = ceil(c.label.font.lineHeight)
    let pad = c.label.padding

    switch c.layout.variant {
    case .ring:
      let d = c.layout.ringDiameter ?? 36
      // Extra vertical room so stroke + optional label are not clipped by the fixed row height.
      let strokeSlop = c.layout.ringLineWidth * 2 + 8
      var labelExtra: CGFloat = 0
      switch c.label.placement {
      case .above, .below:
        labelExtra = lh + pad * 2
      case .centeredOnTrack:
        labelExtra = lh + pad
      case .leading, .trailing:
        labelExtra = max(0, lh + pad * 2 - d * 0.25)
      case .none:
        break
      }
      return max(52, d + ins.top + ins.bottom + labelExtra + strokeSlop)

    case .linear:
      if c.layout.axis == .vertical {
        // Height must cover the vertical track and any label that shares the same vertical span (e.g. `.leading`).
        var h = c.layout.trackThickness + ins.top + ins.bottom + 8
        switch c.label.placement {
        case .leading, .trailing:
          h = ins.top + ins.bottom + max(c.layout.trackThickness, lh + pad * 2) + 6
        case .above, .below:
          h += lh + pad * 2
        case .centeredOnTrack:
          h = ins.top + ins.bottom + max(c.layout.trackThickness, lh + pad) + 6
        case .none:
          break
        }
        return max(120, h)
      }
      var h = c.layout.trackThickness + ins.top + ins.bottom + 6
      switch c.label.placement {
      case .above, .below:
        h += lh + pad * 2
      case .leading, .trailing:
        h = ins.top + ins.bottom + max(c.layout.trackThickness, lh + pad * 2)
      case .centeredOnTrack:
        h = ins.top + ins.bottom + max(c.layout.trackThickness, lh + pad)
      case .none:
        break
      }
      return max(28, h)
    }
  }
}

/// Side-by-side presets illustrating common ``FKProgressBar`` product patterns (buffered download, stepped install, ring activity, etc.).
final class FKProgressBarGalleryDemoViewController: UITableViewController {

  /// Slightly inset track/ring inside the bar so labels and strokes are not clipped at the cell edge.
  private enum GalleryChrome {
    static func apply(_ c: inout FKProgressBarConfiguration) {
      c.layout.contentInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    }
  }

  /// Width that matches ``FKProgressBar`` ring intrinsic layout (diameter + centered label band + insets + stroke slop).
  fileprivate static func galleryRingControlWidth(for c: FKProgressBarConfiguration) -> CGFloat {
    let d = CGFloat(c.layout.ringDiameter ?? 36)
    let ins = c.layout.contentInsets
    let strokeSlop = c.layout.ringLineWidth + 8
    var centeredLabel: CGFloat = 0
    if c.label.placement == .centeredOnTrack {
      centeredLabel = ceil(c.label.font.lineHeight) + c.label.padding
    }
    return d + centeredLabel + ins.left + ins.right + strokeSlop
  }

  /// Row height that matches ``GalleryCell`` constraints (title + subtitle + bar + layout margins). Required so UITableView does not apply a transient `Encapsulated-Layout-Height` of 44pt, which conflicts with the vertical chain.
  private static func galleryRowHeight(for row: FKProgressBarGalleryRow, tableViewWidth: CGFloat) -> CGFloat {
    let w = max(1, tableViewWidth)
    // Inset grouped: content width is narrower than the table; underestimate → clipped subtitles.
    let labelWidth = max(160, w - 64)
    let titleFont = UIFont.preferredFont(forTextStyle: .headline)
    let subFont = UIFont.preferredFont(forTextStyle: .footnote)
    let titleH = ceil(
      (row.title as NSString).boundingRect(
        with: CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: titleFont],
        context: nil
      ).height
    )
    let subH = ceil(
      (row.subtitle as NSString).boundingRect(
        with: CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: subFont],
        context: nil
      ).height
    )
    let barTop: CGFloat = row.configuration.layout.variant == .ring ? 20 : 12
    let barH = FKProgressBarGalleryBarHeight.required(for: row.configuration)
    let inner = titleH + 4 + subH + barTop + barH + 6
    // Matches typical `UITableViewCell` contentView ↔ `layoutMarginsGuide` vertical spacing (see `UIView-topMargin-guide-constraint` / bottom in logs).
    let marginGuideVerticalGutter: CGFloat = 8 + 8
    return inner + marginGuideVerticalGutter
  }

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Builds rows with `var` mutations so we stay compatible with Swift 6 memberwise `init` argument ordering on ``FKProgressBarConfiguration``.
  private lazy var rows: [FKProgressBarGalleryRow] = Self.buildGalleryRows()

  private static func buildGalleryRows() -> [FKProgressBarGalleryRow] {
    var out: [FKProgressBarGalleryRow] = []

    do {
      var c = FKProgressBarConfiguration()
      c.appearance.showsBuffer = false
      c.label.placement = .none
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Default horizontal",
        subtitle: "Baseline system colors, no buffer.",
        configuration: c,
        progress: 0.42,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.appearance.bufferColor = UIColor.systemBlue.withAlphaComponent(0.28)
      c.appearance.showsBuffer = true
      c.label.placement = .below
      c.label.format = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Buffered stream",
        subtitle: "Primary + buffer fills (media / large file UX).",
        configuration: c,
        progress: 0.38,
        buffer: 0.76,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.layout.trackThickness = 8
      c.appearance.fillStyle = .gradientAlongProgress
      c.appearance.progressColor = .systemIndigo
      c.appearance.progressGradientEndColor = .systemCyan
      c.motion.prefersSpringAnimation = true
      c.motion.animationDuration = 0.55
      c.label.placement = .trailing
      c.label.format = .percentFractional
      c.label.fractionDigits = 1
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Gradient + spring",
        subtitle: "FillStyle.gradientAlongProgress + spring motion.",
        configuration: c,
        progress: 0.67,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.layout.trackThickness = 10
      c.layout.segmentCount = 10
      c.layout.segmentGapFraction = 0.1
      c.layout.linearCapStyle = .round
      c.label.placement = .above
      c.label.format = .normalizedValue
      c.label.fractionDigits = 2
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Segmented (10)",
        subtitle: "Discrete chunks for multi-step installers.",
        configuration: c,
        progress: 0.5,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.layout.axis = .vertical
      c.layout.trackThickness = 10
      c.appearance.showsBuffer = true
      c.label.placement = .leading
      c.label.format = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Vertical axis",
        subtitle: "Tall layout: intrinsic width, flexible height.",
        configuration: c,
        progress: 0.55,
        buffer: 0.8,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.layout.variant = .ring
      c.layout.ringLineWidth = 6
      c.layout.ringDiameter = 88
      c.appearance.fillStyle = .gradientAlongProgress
      c.appearance.progressColor = .systemPurple
      c.appearance.progressGradientEndColor = .systemPink
      c.label.placement = .centeredOnTrack
      c.label.format = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Ring determinate",
        subtitle: "Circular stroke; gradient fill approximated on ring.",
        configuration: c,
        progress: 0.73,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.layout.variant = .ring
      c.layout.ringLineWidth = 5
      c.layout.ringDiameter = 96
      c.appearance.trackColor = .tertiarySystemFill
      c.appearance.bufferColor = UIColor.systemGreen.withAlphaComponent(0.35)
      c.appearance.progressColor = .systemGreen
      c.appearance.showsBuffer = true
      c.label.placement = .centeredOnTrack
      c.label.format = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Ring + buffer",
        subtitle: "Buffered arc behind primary stroke.",
        configuration: c,
        progress: 0.4,
        buffer: 0.65,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.layout.trackThickness = 6
      c.motion.indeterminateStyle = .marquee
      c.motion.indeterminatePeriod = 1.1
      c.label.placement = .none
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Indeterminate marquee (linear)",
        subtitle: "Activity without numeric progress.",
        configuration: c,
        progress: 0,
        buffer: 0,
        indeterminate: true
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.layout.variant = .ring
      c.layout.ringLineWidth = 5
      c.layout.ringDiameter = 100
      c.motion.indeterminateStyle = .breathing
      c.motion.indeterminatePeriod = 1.4
      c.label.placement = .centeredOnTrack
      c.label.format = .percentInteger
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Indeterminate breathing (ring)",
        subtitle: "Soft opacity pulse on ring track.",
        configuration: c,
        progress: 0.2,
        buffer: 0,
        indeterminate: true
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.label.placement = .centeredOnTrack
      c.label.format = .logicalRangeValue
      c.label.logicalMinimum = 0
      c.label.logicalMaximum = 512
      c.label.valuePrefix = ""
      c.label.valueSuffix = " MB"
      c.label.usesSemanticTextColor = true
      let f = NumberFormatter()
      f.numberStyle = .decimal
      f.maximumFractionDigits = 0
      c.label.numberFormatter = f
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Logical range label",
        subtitle: "Maps 0…1 to MB with prefix/suffix.",
        configuration: c,
        progress: 0.3125,
        buffer: 0,
        indeterminate: false
      ))
    }
    do {
      var c = FKProgressBarConfiguration()
      c.layout.trackThickness = 6
      c.layout.trackCornerRadius = 2
      c.layout.linearCapStyle = .square
      c.appearance.trackBorderWidth = 1
      c.appearance.trackBorderColor = .separator
      c.appearance.progressBorderWidth = 1
      c.appearance.progressBorderColor = .label
      GalleryChrome.apply(&c)
      out.append(FKProgressBarGalleryRow(
        title: "Borders + square caps",
        subtitle: "Outlined track and progress for dense dashboards.",
        configuration: c,
        progress: 0.88,
        buffer: 0,
        indeterminate: false
      ))
    }

    return out
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Preset gallery"
    tableView.register(GalleryCell.self, forCellReuseIdentifier: GalleryCell.reuseId)
    tableView.estimatedRowHeight = 140
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let row = rows[indexPath.row]
    let tw = tableView.bounds.width > 1 ? tableView.bounds.width : UIScreen.main.bounds.width
    return Self.galleryRowHeight(for: row, tableViewWidth: tw)
  }

  override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    let row = rows[indexPath.row]
    let tw = tableView.bounds.width > 1 ? tableView.bounds.width : UIScreen.main.bounds.width
    return Self.galleryRowHeight(for: row, tableViewWidth: tw)
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: GalleryCell.reuseId, for: indexPath) as! GalleryCell
    let row = rows[indexPath.row]
    cell.configure(row: row)
    return cell
  }
}

// MARK: - Cell

private final class GalleryCell: UITableViewCell {
  static let reuseId = "GalleryCell"

  private let bar = FKProgressBar()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private var barHeightConstraint: NSLayoutConstraint!
  private var barWidthToMargins: NSLayoutConstraint!
  private var verticalBarWidth: NSLayoutConstraint?
  private var ringBarWidth: NSLayoutConstraint?
  private var barTopToSubtitle: NSLayoutConstraint!

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    contentView.clipsToBounds = true
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0
    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    [titleLabel, subtitleLabel, bar].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    contentView.addSubview(titleLabel)
    contentView.addSubview(subtitleLabel)
    contentView.addSubview(bar)
    barHeightConstraint = bar.heightAnchor.constraint(equalToConstant: 44)
    barHeightConstraint.priority = UILayoutPriority(999)
    barWidthToMargins = bar.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.widthAnchor, multiplier: 0.86)
    barTopToSubtitle = bar.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

      barTopToSubtitle,
      bar.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      barWidthToMargins,
      bar.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
      barHeightConstraint,
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Stop CA indeterminate animations and reset values so the next row does not inherit layers or timing state.
    bar.stopIndeterminate()
    bar.isIndeterminate = false
    bar.setProgress(0, buffer: 0, animated: false)
    verticalBarWidth?.isActive = false
    verticalBarWidth = nil
    ringBarWidth?.isActive = false
    ringBarWidth = nil
    barWidthToMargins.isActive = true
    barTopToSubtitle.constant = 12
    titleLabel.text = nil
    subtitleLabel.text = nil
  }

  func configure(row: FKProgressBarGalleryRow) {
    titleLabel.text = row.title
    subtitleLabel.text = row.subtitle

    let c = row.configuration
    verticalBarWidth?.isActive = false
    verticalBarWidth = nil
    ringBarWidth?.isActive = false
    ringBarWidth = nil
    barTopToSubtitle.constant = c.layout.variant == .ring ? 20 : 12

    if c.layout.variant == .ring {
      barWidthToMargins.isActive = false
      let rw = FKProgressBarGalleryDemoViewController.galleryRingControlWidth(for: c)
      let nw = bar.widthAnchor.constraint(equalToConstant: rw)
      nw.priority = .required
      nw.isActive = true
      ringBarWidth = nw
    } else if c.layout.variant == .linear, c.layout.axis == .vertical {
      barWidthToMargins.isActive = false
      let w = c.layout.trackThickness + c.layout.contentInsets.left + c.layout.contentInsets.right + 56
      let nw = bar.widthAnchor.constraint(equalToConstant: w)
      nw.priority = .required
      nw.isActive = true
      verticalBarWidth = nw
    } else {
      barWidthToMargins.isActive = true
    }

    bar.configuration = row.configuration
    bar.setProgress(row.progress, buffer: row.buffer, animated: false)
    bar.isIndeterminate = row.indeterminate

    barHeightConstraint.constant = FKProgressBarGalleryBarHeight.required(for: c)
    setNeedsLayout()
    layoutIfNeeded()
  }
}
