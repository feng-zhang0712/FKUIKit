//
//  FKButtonExampleCategoryViewControllers.swift
//  FKKitExamples
//

import UIKit

final class FKButtonExampleBasicsViewController: FKButtonExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    addDemoSection(title: "Text only", content: makeTextOnlyExample())
    addDemoSection(title: "Icon only", content: makeIconOnlyExample())
    addDemoSection(title: "Composition", content: makeCompositionExample())
    if let last = rootStackView.arrangedSubviews.last {
      rootStackView.setCustomSpacing(22, after: last)
    }
  }
}

final class FKButtonExampleLayoutViewController: FKButtonExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    addDemoSection(title: "Vertical layout", content: makeVerticalLayoutExample())
    addDemoSection(title: "Capsule corner", content: makeCapsuleCornerExample())
    addDemoSection(title: "No border", content: makeNoBorderExample())
    addDemoSection(title: "Different length", content: makeDifferentLengthExample())
    addDemoSection(title: "Subtitle · text only", content: makeSubtitleTextOnlyExample())
    addDemoSection(title: "Subtitle · text and image", content: makeSubtitleTextAndImageExample())
    addDemoSection(title: "Subtitle · vertical axis", content: makeSubtitleVerticalAxisExample())
    addDemoSection(title: "Subtitle · toggle presence", content: makeSubtitleTogglePresenceExample())
    addDemoSection(title: "Content kind · cycle all", content: makeContentKindCycleAllExample())
    addDemoSection(title: "Content kind · picker", content: makeContentKindPickerExample())
    addDemoSection(title: "Content kind · text ↔ custom", content: makeContentKindTextCustomPingPongExample())
    addDemoSection(title: "Content kind · placement cycle", content: makeContentKindPlacementCycleExample())
    addDemoSection(title: "Content kind · vertical cycle", content: makeContentKindVerticalCycleExample())
    if let last = rootStackView.arrangedSubviews.last {
      rootStackView.setCustomSpacing(22, after: last)
    }
  }
}

final class FKButtonExampleInteractionViewController: FKButtonExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    addDemoSection(title: "Tap interval (anti double-tap)", content: makeThrottleExamples())
    addDemoSection(title: "Hit test expansion", content: makeHitTestExpansionExample())
    addDemoSection(title: "Long press callbacks", content: makeLongPressExamples())
    addDemoSection(title: "Chaining API", content: makeChainingExample())
    if let last = rootStackView.arrangedSubviews.last {
      rootStackView.setCustomSpacing(22, after: last)
    }
  }
}

final class FKButtonExampleAppearanceViewController: FKButtonExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    addDemoSection(title: "Gradient & highlight control", content: makeGradientAndHighlightControlExample())
    addDemoSection(title: "Disabled dimming", content: makeDisabledDimmingExample())
    addDemoSection(title: "Image ↔ title spacing", content: makeImageTitleSpacingExample())
    if let last = rootStackView.arrangedSubviews.last {
      rootStackView.setCustomSpacing(22, after: last)
    }
  }
}

final class FKButtonExampleLoadingViewController: FKButtonExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    addDemoSection(title: "Loading presentations", content: makeLoadingExamples())
    if let last = rootStackView.arrangedSubviews.last {
      rootStackView.setCustomSpacing(22, after: last)
    }
  }
}

final class FKButtonExampleAdvancedViewController: FKButtonExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    addDemoSection(title: "GlobalStyle snapshot", content: makeGlobalStyleSnapshotExample())
    addDemoSection(title: "Storyboard / XIB", content: makeStoryboardAttributesHint())
    if let last = rootStackView.arrangedSubviews.last {
      rootStackView.setCustomSpacing(22, after: last)
    }
  }
}
