#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

/// Standalone SwiftUI demo view (copy-ready).
///
/// - Notes:
///   - FKSwipeAction uses a background probe to discover an underlying UIKit `UITableView`/`UICollectionView`.
///   - No third-party introspection library is required.
@available(iOS 13.0, *)
struct FKSwipeActionSwiftUIDemoView: View {
  private let items = Array(0..<40)

  var body: some View {
    List(items, id: \.self) { row in
      VStack(alignment: .leading, spacing: 6) {
        Text("SwiftUI Row \(row)")
          .font(.headline)
        Text("Swipe left/right to reveal actions (UIKit list is discovered automatically).")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
      .padding(.vertical, 6)
    }
    .navigationTitle("SwiftUI SwipeAction")
    .fk_swipeAction { _ in
      // Key line: enable swipe actions in SwiftUI with one line.
      FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(
            id: "delete",
            title: "Delete",
            icon: UIImage(systemName: "trash.fill"),
            background: .color(.systemRed),
            layout: .iconTop,
            width: 86,
            cornerRadius: 14
          ) {},
          FKSwipeActionButton(
            id: "more",
            title: "More",
            icon: UIImage(systemName: "ellipsis"),
            background: .horizontalGradient(leading: .systemBlue, trailing: .systemTeal),
            layout: .iconLeading,
            width: 108,
            cornerRadius: 14
          ) {},
        ],
        allowedDirections: [.left],
        tapToClose: true
      )
    }
  }
}
#endif

