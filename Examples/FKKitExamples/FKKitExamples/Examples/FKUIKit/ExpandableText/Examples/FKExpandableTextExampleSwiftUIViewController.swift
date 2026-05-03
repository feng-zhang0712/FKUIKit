import FKUIKit
import SwiftUI
import UIKit

private struct FKExpandableTextSwiftUIDemoView: View {
  @State private var isExpanded = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("SwiftUI bridge")
          .font(.title2.weight(.semibold))
        Text("`FKExpandableTextView` wraps the same `UITextView` controller as UIKit.")
          .font(.subheadline)
          .foregroundColor(.secondary)

        FKExpandableTextView(
          attributedText: FKExpandableTextExampleSupport.attributedRichText(),
          configuration: FKExpandableTextConfiguration(
            collapseRule: .lines(3),
            interactionMode: .buttonOnly
          ),
          isExpanded: $isExpanded,
          onExpansionChange: { _ in },
          onLinkTapped: { _ in }
        )
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)

        Button(isExpanded ? "Collapse" : "Expand") {
          isExpanded.toggle()
        }
        .buttonStyle(.borderedProminent)
      }
      .padding()
    }
    .navigationTitle("SwiftUI")
    .navigationBarTitleDisplayMode(.inline)
  }
}

final class FKExpandableTextExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"
    view.backgroundColor = .systemBackground

    let host = UIHostingController(rootView: FKExpandableTextSwiftUIDemoView())
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
  }
}
