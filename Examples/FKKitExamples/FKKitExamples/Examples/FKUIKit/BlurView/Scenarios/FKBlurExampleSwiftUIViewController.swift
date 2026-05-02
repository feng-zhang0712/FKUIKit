import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Scenario: SwiftUI

final class FKBlurSwiftUIHostVC: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI"
    view.backgroundColor = .systemBackground

    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKBlurSwiftUIScreen())
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
    label.text = "SwiftUI unavailable."
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
private struct FKBlurSwiftUIScreen: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 14) {
        Text("FKBlurView (SwiftUI)")
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)

        ZStack {
          RoundedRectangle(cornerRadius: 14)
            .fill(
              LinearGradient(
                colors: [.pink, .purple, .blue, .teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(height: 180)

          // In SwiftUI, use FKSwiftUIBlurView (UIViewRepresentable adapter).
          FKSwiftUIBlurView(
            configuration: FKBlurConfiguration(
              backend: .system(style: .systemMaterial)
            )
          )
          .frame(width: 260, height: 96)
          .clipShape(RoundedRectangle(cornerRadius: 16))

          Text("SwiftUI Blur")
            .font(.headline)
        }

        Text("Tip: for dynamic content, prefer the system backend (hardware materials). Use the custom backend only when you need full parameter control.")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
  }
}
#endif
