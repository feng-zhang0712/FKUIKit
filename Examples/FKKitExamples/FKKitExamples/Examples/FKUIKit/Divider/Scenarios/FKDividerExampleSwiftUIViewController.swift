import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Hosts `FKDividerView` for side-by-side UIKit/SwiftUI comparison.
final class FKDividerExampleSwiftUIViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI"
    view.backgroundColor = .systemBackground
    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKDividerSwiftUIScreen())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    host.view.backgroundColor = .clear
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
    #else
    let label = UILabel()
    label.text = "SwiftUI is not available on this build."
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    #endif
  }
}

#if canImport(SwiftUI)
private struct FKDividerSwiftUIScreen: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("FKDividerView")
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)

        FKDividerView(
          configuration: .init(
            direction: .horizontal,
            lineStyle: .solid,
            color: .separator
          )
        )
        .frame(height: 1)

        FKDividerView(
          configuration: .init(
            direction: .horizontal,
            lineStyle: .dashed,
            dashPattern: [6, 3],
            showsGradient: true,
            gradientStartColor: .systemPink,
            gradientEndColor: .systemPurple
          )
        )
        .frame(height: 1)

        HStack {
          Text("Leading")
          FKDividerView(configuration: .init(direction: .vertical, color: .systemBlue))
            .frame(width: 1, height: 36)
          Text("Trailing")
        }
      }
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
  }
}
#endif
