#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper for `FKTabBar`.
///
/// This bridge is intentionally lightweight and focuses on header selection sync.
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
    return view
  }

  public func updateUIView(_ uiView: FKTabBar, context: Context) {
    if let configuration { uiView.configuration = configuration }
    uiView.reload(items: items, updatePolicy: .preserveSelection)
    if uiView.selectedIndex != selectedIndex {
      uiView.setSelectedIndex(selectedIndex, animated: true, reason: .programmatic)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(selectedIndex: $selectedIndex)
  }

  @MainActor
  public final class Coordinator {
    fileprivate var selectedIndex: Binding<Int>
    init(selectedIndex: Binding<Int>) {
      self.selectedIndex = selectedIndex
    }
  }
}
#endif

