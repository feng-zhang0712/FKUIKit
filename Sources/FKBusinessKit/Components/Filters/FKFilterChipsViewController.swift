import UIKit

final class FKFilterChipCell: UICollectionViewCell {
  static let reuseID = "FKFilterChipCell"

  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.layer.cornerRadius = 6
    contentView.layer.cornerCurve = .continuous
    let scale = max(traitCollection.displayScale, 1)
    contentView.layer.borderWidth = 1 / scale

    label.font = .preferredFont(forTextStyle: .callout)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(label)

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
    ])

    isAccessibilityElement = true
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func apply(_ item: FKFilterOptionItem) {
    label.text = item.title
    accessibilityLabel = item.title
    accessibilityTraits = item.isSelected ? [.button, .selected] : [.button]

    if !item.isEnabled {
      contentView.backgroundColor = .systemGray6
      contentView.layer.borderColor = UIColor.separator.cgColor
      label.textColor = .secondaryLabel
      contentView.alpha = 0.6
      isUserInteractionEnabled = false
      return
    }

    contentView.alpha = 1.0
    isUserInteractionEnabled = true

    if item.isSelected {
      contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.10)
      contentView.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.55).cgColor
      label.textColor = .systemRed
    } else {
      contentView.backgroundColor = .systemBackground
      contentView.layer.borderColor = UIColor.separator.cgColor
      label.textColor = .label
    }
  }
}

public final class FKFilterChipsViewController: UIViewController {
  public struct Configuration: Sendable {
    public var columns: Int
    public var interitemSpacing: CGFloat
    public var lineSpacing: CGFloat
    public var contentInsets: UIEdgeInsets
    /// Row height for chip cells and preferred-content height estimation.
    public var itemRowHeight: CGFloat
    /// When set, limits panel height so content taller than this scrolls inside the collection view.
    public var maxPresentedHeight: CGFloat?

    public init(
      columns: Int = 4,
      interitemSpacing: CGFloat = 10,
      lineSpacing: CGFloat = 12,
      contentInsets: UIEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12),
      itemRowHeight: CGFloat = 40,
      maxPresentedHeight: CGFloat? = nil
    ) {
      self.columns = max(columns, 1)
      self.interitemSpacing = interitemSpacing
      self.lineSpacing = lineSpacing
      self.contentInsets = contentInsets
      self.itemRowHeight = max(itemRowHeight, 32)
      self.maxPresentedHeight = maxPresentedHeight
    }
  }

  private var sections: [FKFilterSection]
  private let config: Configuration
  private let onChange: ([FKFilterSection]) -> Void
  private let onSelectItem: ((FKFilterID?, FKFilterOptionItem, FKFilterSelectionMode) -> Void)?
  private let allowsMultipleSelection: Bool
  private var lastCollectionBoundsSize: CGSize = .zero

  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = config.interitemSpacing
    layout.minimumLineSpacing = config.lineSpacing
    layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.backgroundColor = .systemBackground
    cv.allowsMultipleSelection = allowsMultipleSelection
    cv.translatesAutoresizingMaskIntoConstraints = false
    cv.register(FKFilterChipCell.self, forCellWithReuseIdentifier: FKFilterChipCell.reuseID)
    cv.dataSource = self
    cv.delegate = self
    cv.alwaysBounceVertical = true
    return cv
  }()

  public init(
    sections: [FKFilterSection],
    configuration: Configuration = .init(),
    onChange: @escaping ([FKFilterSection]) -> Void,
    onSelectItem: ((FKFilterID?, FKFilterOptionItem, FKFilterSelectionMode) -> Void)? = nil,
    allowsMultipleSelection: Bool = false
  ) {
    self.sections = sections
    self.config = configuration
    self.onChange = onChange
    self.onSelectItem = onSelectItem
    self.allowsMultipleSelection = allowsMultipleSelection
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  public override var preferredContentSize: CGSize {
    get {
      let full = estimatedContentHeight()
      let h: CGFloat
      if let cap = config.maxPresentedHeight {
        h = min(full, cap)
      } else {
        h = full
      }
      return CGSize(width: 0, height: max(h, 80))
    }
    set { super.preferredContentSize = newValue }
  }

  /// Height from model + grid geometry only (does not depend on a laid-out width).
  private func estimatedContentHeight() -> CGFloat {
    let columns = CGFloat(config.columns)
    let itemCount = sections.reduce(0) { $0 + $1.items.count }
    let rows = ceil(CGFloat(max(itemCount, 1)) / columns)
    let insetV = config.contentInsets.top + config.contentInsets.bottom
    let rowH = config.itemRowHeight
    let body = rows * rowH + max(0, rows - 1) * config.lineSpacing
    return max(insetV + body, 72)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard collectionView.bounds.size != lastCollectionBoundsSize else { return }
    lastCollectionBoundsSize = collectionView.bounds.size
    collectionView.collectionViewLayout.invalidateLayout()
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.collectionView.collectionViewLayout.invalidateLayout()
      self?.collectionView.layoutIfNeeded()
    })
  }
}

extension FKFilterChipsViewController: UICollectionViewDataSource {
  public func numberOfSections(in collectionView: UICollectionView) -> Int { sections.count }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    sections[section].items.count
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FKFilterChipCell.reuseID, for: indexPath)
    guard let chip = cell as? FKFilterChipCell else { return cell }
    chip.apply(sections[indexPath.section].items[indexPath.item])
    return chip
  }
}

extension FKFilterChipsViewController: UICollectionViewDelegateFlowLayout {
  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let insets = config.contentInsets
    let usable = collectionView.bounds.inset(by: insets)
    let columns = CGFloat(config.columns)
    let spacing = config.interitemSpacing * (columns - 1)
    let width = floor((usable.width - spacing) / columns)
    let h = config.itemRowHeight
    return CGSize(width: max(width, 44), height: h)
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    config.contentInsets
  }

  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    updateSelection(at: indexPath)
  }

  public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    updateSelection(at: indexPath)
  }

  private func updateSelection(at indexPath: IndexPath) {
    var section = sections[indexPath.section]
    let tapped = section.items[indexPath.item]
    let tappedID = tapped.id

    let effectiveMode: FKFilterSelectionMode = (allowsMultipleSelection && section.selectionMode == .multiple) ? .multiple : .single

    switch effectiveMode {
    case .single:
      for i in section.items.indices {
        section.items[i].isSelected = (section.items[i].id == tappedID)
      }
    case .multiple:
      for i in section.items.indices where section.items[i].id == tappedID {
        section.items[i].isSelected.toggle()
      }
    }

    sections[indexPath.section] = section
    collectionView.reloadSections(IndexSet(integer: indexPath.section))
    onChange(sections)
    onSelectItem?(section.id, tapped, effectiveMode)
  }
}

