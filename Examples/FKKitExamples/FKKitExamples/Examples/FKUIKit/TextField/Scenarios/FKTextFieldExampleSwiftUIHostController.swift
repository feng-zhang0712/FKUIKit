import UIKit
import SwiftUI
import FKUIKit

final class FKTextFieldExampleSwiftUIHostController: UIHostingController<FKTextFieldSwiftUIExampleView> {
  init() {
    super.init(rootView: FKTextFieldSwiftUIExampleView())
    title = "SwiftUI"
  }

  @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder, rootView: FKTextFieldSwiftUIExampleView())
  }
}

struct FKTextFieldSwiftUIExampleView: View {
  @State private var rawText: String = ""

  var body: some View {
    let config = FKTextFieldConfiguration(
      inputRule: FKTextFieldInputRule(formatType: .phoneNumber),
      placeholder: "Enter phone number in SwiftUI"
    )
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("SwiftUI TextField Example")
          .font(.headline)
        Text("Uses FKTextFieldRepresentable from FKUIKit, so UIKit formatting and validation stay consistent.")
          .font(.footnote)
          .foregroundColor(.secondary)
        FKTextFieldRepresentable(rawText: $rawText, configuration: config)
          .frame(height: 44)
        Text("Raw: \(rawText)")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
      .padding(16)
    }
    .background(Color(.systemGroupedBackground))
  }
}
