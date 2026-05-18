import FKUIKit
import UIKit

/// Schedules a short sleep timer for demo purposes.
@MainActor
final class FKAudioPlayerSleepTimerExampleViewController: FKAudioPlayerExampleShellViewController {

  private let timerLabel = UILabel()

  override func viewDidLoad() {
    title = "Sleep timer"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Demo timers fire after 15 seconds. The player pauses when the timer elapses."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    timerLabel.font = .preferredFont(forTextStyle: .footnote)
    timerLabel.textColor = .secondaryLabel
    timerLabel.text = "No timer scheduled"

    let schedule = FKAudioPlayerExampleLayout.makePrimaryButton("Sleep in 15s", action: UIAction { [weak self] _ in
      let fire = Date().addingTimeInterval(15)
      self?.player.setSleepTimer(fireDate: fire)
      self?.timerLabel.text = "Timer fires at \(Self.formatter.string(from: fire))"
    })
    let cancel = FKAudioPlayerExampleLayout.makeSecondaryButton("Cancel timer", action: UIAction { [weak self] _ in
      self?.player.setSleepTimer(fireDate: nil)
      self?.timerLabel.text = "Timer cancelled"
    })
    let stack = UIStackView(arrangedSubviews: [timerLabel, schedule, cancel])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
  }

  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter
  }()
}
