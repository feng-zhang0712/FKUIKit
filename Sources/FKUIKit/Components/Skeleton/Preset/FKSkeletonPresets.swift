//
// FKSkeletonPresets.swift
//

import UIKit

/// Ready-made skeleton layouts for common UI patterns.
/// Each preset returns a fully-constrained `FKSkeletonContainerView`.
public enum FKSkeletonPresets {

  // MARK: - List row (avatar + two text lines)

  /// A typical list row: avatar on the left, two text lines on the right.
  public static func listRow(
    avatarSize: CGFloat = 44,
    spacing: CGFloat = 12,
    avatarStyle: FKSkeletonAvatarStyle = .circle,
    titleLineWidthRatio: CGFloat = 0.85,
    subtitleLineWidthRatio: CGFloat = 0.55,
    titleLineHeight: CGFloat = 14,
    subtitleLineHeight: CGFloat = 12,
    configuration: FKSkeletonConfiguration? = nil
  ) -> FKSkeletonContainerView {
    let container = FKSkeletonContainerView()
    container.configuration = configuration

    let avatar = FKSkeletonView()
    switch avatarStyle {
    case .circle:
      avatar.layer.cornerRadius = avatarSize / 2
    case .rounded(let r):
      avatar.layer.cornerRadius = r
    }
    avatar.layer.maskedCorners = .all

    let titleLine = FKSkeletonView()
    titleLine.layer.cornerRadius = 4

    let subtitleLine = FKSkeletonView()
    subtitleLine.layer.cornerRadius = 4

    [avatar, titleLine, subtitleLine].forEach { container.addSkeletonSubview($0) }

    let titleM = min(1, max(0.05, titleLineWidthRatio))
    let subM = min(1, max(0.05, subtitleLineWidthRatio))
    let inset: CGFloat = 16

    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      avatar.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: avatarSize),
      avatar.heightAnchor.constraint(equalToConstant: avatarSize),

      titleLine.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: spacing),
      titleLine.heightAnchor.constraint(equalToConstant: titleLineHeight),
      titleLine.bottomAnchor.constraint(equalTo: container.centerYAnchor, constant: -4),
      titleLine.widthAnchor.constraint(
        equalTo: container.widthAnchor,
        multiplier: titleM,
        constant: -titleM * (avatarSize + spacing + inset)
      ),

      subtitleLine.leadingAnchor.constraint(equalTo: titleLine.leadingAnchor),
      subtitleLine.heightAnchor.constraint(equalToConstant: subtitleLineHeight),
      subtitleLine.topAnchor.constraint(equalTo: container.centerYAnchor, constant: 4),
      subtitleLine.widthAnchor.constraint(
        equalTo: container.widthAnchor,
        multiplier: subM,
        constant: -subM * (avatarSize + spacing + inset)
      ),
    ])

    return container
  }

  // MARK: - Card (image banner + text block)

  /// A card skeleton: full-width image banner on top, two text lines below.
  public static func card(
    bannerHeight: CGFloat = 160,
    horizontalInset: CGFloat = 16,
    verticalSpacing: CGFloat = 12,
    lineSpacing: CGFloat = 8,
    titleLineHeight: CGFloat = 16,
    bodyLineHeight: CGFloat = 13,
    titleWidthRatio: CGFloat = 0.75,
    bodyWidthRatio: CGFloat = 0.55,
    configuration: FKSkeletonConfiguration? = nil
  ) -> FKSkeletonContainerView {
    let container = FKSkeletonContainerView()
    container.configuration = configuration

    let banner = FKSkeletonView()
    banner.layer.cornerRadius = 0

    let titleLine = FKSkeletonView()
    titleLine.layer.cornerRadius = 4

    let bodyLine = FKSkeletonView()
    bodyLine.layer.cornerRadius = 4

    [banner, titleLine, bodyLine].forEach { container.addSkeletonSubview($0) }

    let tM = min(1, max(0.05, titleWidthRatio))
    let bM = min(1, max(0.05, bodyWidthRatio))

    NSLayoutConstraint.activate([
      banner.topAnchor.constraint(equalTo: container.topAnchor),
      banner.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      banner.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      banner.heightAnchor.constraint(equalToConstant: bannerHeight),

      titleLine.topAnchor.constraint(equalTo: banner.bottomAnchor, constant: verticalSpacing),
      titleLine.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: horizontalInset),
      titleLine.heightAnchor.constraint(equalToConstant: titleLineHeight),
      titleLine.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: tM, constant: -horizontalInset * 2 * tM),

      bodyLine.topAnchor.constraint(equalTo: titleLine.bottomAnchor, constant: lineSpacing),
      bodyLine.leadingAnchor.constraint(equalTo: titleLine.leadingAnchor),
      bodyLine.heightAnchor.constraint(equalToConstant: bodyLineHeight),
      bodyLine.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
      bodyLine.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: bM, constant: -horizontalInset * 2 * bM),
    ])

    return container
  }

  // MARK: - Text block (multiple lines)

  /// Stacked text-line placeholders. Supply `lineWidthRatios` with one value per line (e.g. `[1, 1, 0.9, 0.7]`)
  /// or rely on `lastLineWidthRatio` for the final line when the array is shorter.
  public static func textBlock(
    lineCount: Int? = nil,
    lineHeight: CGFloat? = nil,
    lineSpacing: CGFloat? = nil,
    lineWidthRatios: [CGFloat]? = nil,
    lastLineWidthRatio: CGFloat = 0.6,
    configuration: FKSkeletonConfiguration? = nil
  ) -> FKSkeletonContainerView {
    let container = FKSkeletonContainerView()
    let base = configuration ?? FKSkeleton.defaultConfiguration
    container.configuration = configuration

    let count = max(1, lineCount ?? base.defaultTextLineCount)
    let height = lineHeight ?? base.lineHeight
    let spacing = lineSpacing ?? base.lineSpacing

    var previous: FKSkeletonView?

    for index in 0..<count {
      let line = FKSkeletonView()
      line.layer.cornerRadius = height / 2
      container.addSkeletonSubview(line)

      let isLast = index == count - 1
      let ratio: CGFloat
      if let ratios = lineWidthRatios, index < ratios.count {
        ratio = min(1, max(0.05, ratios[index]))
      } else if isLast {
        ratio = min(1, max(0.05, lastLineWidthRatio))
      } else {
        ratio = 1
      }

      var constraints: [NSLayoutConstraint] = [
        line.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        line.heightAnchor.constraint(equalToConstant: height),
        line.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: ratio),
      ]

      if let prev = previous {
        constraints.append(line.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: spacing))
      } else {
        constraints.append(line.topAnchor.constraint(equalTo: container.topAnchor))
      }

      if isLast {
        constraints.append(line.bottomAnchor.constraint(equalTo: container.bottomAnchor))
      }

      NSLayoutConstraint.activate(constraints)
      previous = line
    }

    return container
  }

  // MARK: - Grid cell (image + label)

  /// A single grid cell: square image placeholder with a text line below.
  public static func gridCell(
    imageCornerRadius: CGFloat = 8,
    labelHeight: CGFloat = 13,
    verticalSpacing: CGFloat = 8,
    labelWidthRatio: CGFloat = 1,
    horizontalInset: CGFloat = 4,
    configuration: FKSkeletonConfiguration? = nil
  ) -> FKSkeletonContainerView {
    let container = FKSkeletonContainerView()
    container.configuration = configuration

    let image = FKSkeletonView()
    image.layer.cornerRadius = imageCornerRadius

    let label = FKSkeletonView()
    label.layer.cornerRadius = 4

    [image, label].forEach { container.addSkeletonSubview($0) }

    let lw = min(1, max(0.05, labelWidthRatio))

    NSLayoutConstraint.activate([
      image.topAnchor.constraint(equalTo: container.topAnchor),
      image.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      image.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      image.heightAnchor.constraint(equalTo: image.widthAnchor),

      label.topAnchor.constraint(equalTo: image.bottomAnchor, constant: verticalSpacing),
      label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: horizontalInset),
      label.heightAnchor.constraint(equalToConstant: labelHeight),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      label.widthAnchor.constraint(
        equalTo: container.widthAnchor,
        multiplier: lw,
        constant: -horizontalInset * 2 * lw
      ),
    ])

    return container
  }
}

private extension CACornerMask {
  static let all: CACornerMask = [
    .layerMinXMinYCorner, .layerMaxXMinYCorner,
    .layerMinXMaxYCorner, .layerMaxXMaxYCorner,
  ]
}
