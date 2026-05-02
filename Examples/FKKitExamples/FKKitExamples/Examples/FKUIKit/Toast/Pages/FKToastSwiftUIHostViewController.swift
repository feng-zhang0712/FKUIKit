import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class FKToastSwiftUIHostViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI Bridge"
    view.backgroundColor = .systemBackground
    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKToastSwiftUISurface())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
    #endif
  }
}

#if canImport(SwiftUI)
private struct FKToastSwiftUISurface: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("SwiftUI triggers the same `FKToastExamplePlaybook` helpers as UIKit.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Button("Basic Placement Example") { FKToastExamplePlaybook.showBasicPlacementAndStyle() }.buttonStyle(.borderedProminent)
        Button("Queue + Coalesce Example") { FKToastExamplePlaybook.burstQueueExample(); FKToastExamplePlaybook.dedupeCoalesceExample() }.buttonStyle(.bordered)
        Button("HUD Progress Example") { FKToastExamplePlaybook.showHUDProgress() }.buttonStyle(.bordered)
        Button("Action Snackbar Example") { FKToastExamplePlaybook.showActionSnackbarExample(announcementEnabled: true) }.buttonStyle(.bordered)
      }
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
  }
}
#endif
