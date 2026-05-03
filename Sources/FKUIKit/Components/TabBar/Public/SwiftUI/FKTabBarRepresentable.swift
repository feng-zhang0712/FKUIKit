#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper for `FKTabBar`.
///
/// Selection sync rules:
/// - User taps update the binding via `onSelectionChanged`.
/// - When the visible strip’s item-ID sequence changes (add/remove/reorder/hidden toggles), the binding is updated from the UIKit control so it tracks `reload` policies (`preserveSelection`, etc.).
/// - Programmatic binding updates apply with `notify: false` to avoid feedback loops and spurious delegate callbacks.
@MainActor
public struct FKTabBarRepresentable: UIViewRepresentable {
  public typealias UIViewType = FKTabBar

  private let items: [FKTabBarItem]
  @Binding private var selectedIndex: Int
  private let configuration: FKTabBarConfiguration?

  /// Creates a SwiftUI bridge for `FKTabBar`.
  ///
  /// - Important: Keep item IDs stable across updates so selection preservation can work correctly.
  public init(
    items: [FKTabBarItem],
    selectedIndex: Binding<Int>,
    configuration: FKTabBarConfiguration? = nil
  ) {
    self.items = items
    self._selectedIndex = selectedIndex
    self.configuration = configuration
  }

  public func makeUIView(context: Context) -> FKTabBar {
    let view = FKTabBar(items: items, selectedIndex: selectedIndex, configuration: configuration ?? FKTabBarDefaults.defaultConfiguration)
    view.onSelectionChanged = { _, index, _ in
      context.coordinator.selectedIndex.wrappedValue = index
    }
    context.coordinator.lastVisibleItemIDs = items.filter { !$0.isHidden }.map(\.id)
    return view
  }

  public func updateUIView(_ uiView: FKTabBar, context: Context) {
    if let configuration { uiView.configuration = configuration }

    let visibleIDs = items.filter { !$0.isHidden }.map(\.id)
    let structureChanged =
      !context.coordinator.lastVisibleItemIDs.isEmpty && visibleIDs != context.coordinator.lastVisibleItemIDs

    uiView.reload(items: items, updatePolicy: .preserveSelection)
    context.coordinator.lastVisibleItemIDs = visibleIDs

    if structureChanged {
      if context.coordinator.selectedIndex.wrappedValue != uiView.selectedIndex {
        context.coordinator.selectedIndex.wrappedValue = uiView.selectedIndex
      }
      return
    }

    if uiView.selectedIndex != selectedIndex {
      uiView.setSelectedIndex(selectedIndex, animated: true, notify: false, reason: .programmatic)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(selectedIndex: $selectedIndex)
  }

  @MainActor
  public final class Coordinator {
    fileprivate var selectedIndex: Binding<Int>
    /// Used to detect visible-strip structural changes so selection can sync tab bar → SwiftUI without fighting valid binding updates.
    fileprivate var lastVisibleItemIDs: [String] = []
    init(selectedIndex: Binding<Int>) {
      self.selectedIndex = selectedIndex
    }
  }
}
#endif

