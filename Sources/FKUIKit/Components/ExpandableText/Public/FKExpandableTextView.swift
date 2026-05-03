import SwiftUI
import UIKit

/// Non-scrolling text view that reports a vertical intrinsic size so SwiftUI does not compress it to one line.
private final class FKExpandableTextSizingTextView: UITextView {
  override func layoutSubviews() {
    super.layoutSubviews()
    invalidateIntrinsicContentSize()
  }

  override var intrinsicContentSize: CGSize {
    guard !isScrollEnabled else { return super.intrinsicContentSize }
    let w = bounds.width > 1 ? bounds.width : (frame.width > 1 ? frame.width : 0)
    guard w > 1 else {
      return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    let h = sizeThatFits(CGSize(width: w, height: .greatestFiniteMagnitude)).height
    return CGSize(width: UIView.noIntrinsicMetric, height: max(1, ceil(h)))
  }
}

/// SwiftUI bridge to ``FKExpandableTextLinkedTextViewController`` (rich text, links, expansion).
@available(iOS 15.0, *)
@MainActor
public struct FKExpandableTextView: UIViewRepresentable {
  public var attributedText: NSAttributedString
  public var configuration: FKExpandableTextConfiguration
  @Binding public var isExpanded: Bool
  public var onExpansionChange: ((FKExpandableTextState) -> Void)?
  public var onLinkTapped: ((URL) -> Void)?

  public init(
    attributedText: NSAttributedString,
    configuration: FKExpandableTextConfiguration = FKExpandableText.defaultConfiguration,
    isExpanded: Binding<Bool> = .constant(false),
    onExpansionChange: ((FKExpandableTextState) -> Void)? = nil,
    onLinkTapped: ((URL) -> Void)? = nil
  ) {
    self.attributedText = attributedText
    self.configuration = configuration
    _isExpanded = isExpanded
    self.onExpansionChange = onExpansionChange
    self.onLinkTapped = onLinkTapped
  }

  public func makeUIView(context: Context) -> UITextView {
    let textView = FKExpandableTextSizingTextView()
    textView.backgroundColor = .clear
    textView.setContentCompressionResistancePriority(.required, for: .vertical)
    textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    context.coordinator.bind(to: textView)
    return textView
  }

  public func updateUIView(_: UITextView, context: Context) {
    context.coordinator.configuration = configuration
    context.coordinator.onExpansionChange = onExpansionChange
    context.coordinator.onLinkTapped = onLinkTapped
    context.coordinator.setText(attributedText)
    context.coordinator.setExpanded(isExpanded, animated: false)
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(
      configuration: configuration,
      onExpansionChange: onExpansionChange,
      onLinkTapped: onLinkTapped
    ) { newState in
      isExpanded = (newState == .expanded)
    }
  }
}

@available(iOS 15.0, *)
public extension FKExpandableTextView {
  @MainActor
  final class Coordinator {
    var configuration: FKExpandableTextConfiguration
    var onExpansionChange: ((FKExpandableTextState) -> Void)?
    var onLinkTapped: ((URL) -> Void)?

    private var controller: FKExpandableTextLinkedTextViewController?
    private let updateExpansionBinding: (FKExpandableTextState) -> Void

    init(
      configuration: FKExpandableTextConfiguration,
      onExpansionChange: ((FKExpandableTextState) -> Void)?,
      onLinkTapped: ((URL) -> Void)?,
      updateExpansionBinding: @escaping (FKExpandableTextState) -> Void
    ) {
      self.configuration = configuration
      self.onExpansionChange = onExpansionChange
      self.onLinkTapped = onLinkTapped
      self.updateExpansionBinding = updateExpansionBinding
    }

    func bind(to textView: UITextView) {
      let controller = FKExpandableTextLinkedTextViewController(textView: textView, configuration: configuration)
      controller.onLinkTapped = { [weak self] url in
        self?.onLinkTapped?(url)
      }
      controller.onExpansionChange = { [weak self] state in
        self?.updateExpansionBinding(state)
        self?.onExpansionChange?(state)
      }
      self.controller = controller
    }

    func setText(_ text: NSAttributedString) {
      controller?.setConfiguration(configuration)
      controller?.setText(text)
    }

    func setExpanded(_ isExpanded: Bool, animated: Bool) {
      controller?.setExpanded(isExpanded, animated: animated)
    }
  }
}
