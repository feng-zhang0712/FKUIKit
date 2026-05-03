import UIKit
import FKUIKit

public extension FKAnchoredDropdownConfiguration {
  /// Default configuration tuned for an anchored dropdown below a top tab bar.
  static var `default`: FKAnchoredDropdownConfiguration {
    var tab = FKTabBarConfiguration()
    tab.layout.isScrollable = true
    tab.layout.widthMode = .intrinsic
    tab.layout.itemSpacing = 8
    tab.layout.contentInsets = .init(top: 0, leading: 12, bottom: 0, trailing: 12)
    tab.layout.contentAlignment = .leading
    tab.appearance.backgroundStyle = .solid(.systemBackground)
    tab.appearance.indicatorStyle = .none
    tab.appearance.showsDivider = false

    var presentation = FKPresentationConfiguration.default
    presentation.cornerRadius = 10
    presentation.backdropStyle = .dim(alpha: 0.25)
    presentation.dismissBehavior = .init(allowsTapOutside: true, allowsSwipe: true, allowsBackdropTap: true)
    presentation.keyboardAvoidance = .init(isEnabled: true, strategy: .interactive, additionalBottomInset: 8, targetScrollView: nil)
    presentation.safeAreaPolicy = .contentRespectsSafeArea
    presentation.rotationHandling = .relayoutAnimated
    return FKAnchoredDropdownConfiguration(
      tabBarConfiguration: tab,
      presentationConfiguration: presentation,
      switchAnimationStyle: .replaceInPlace(animation: .crossfade(duration: 0.18))
    )
  }
}
