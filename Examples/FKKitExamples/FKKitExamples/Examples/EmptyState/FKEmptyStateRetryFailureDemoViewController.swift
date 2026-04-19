//
// FKEmptyStateRetryFailureDemoViewController.swift
//
// Simulates: user taps Retry → loading → after a delay, request still fails (error again).
//

import FKUIKit
import UIKit

// MARK: - Retry / fail loop

/// Demonstrates transitioning `.error` → `.loading` → `.error` with updated copy.
final class FKEmptyStateRetryFailureDemoViewController: UIViewController {

  // MARK: Properties

  private lazy var tableView: UITableView = {
    let t = UITableView(frame: .zero, style: .insetGrouped)
    t.translatesAutoresizingMaskIntoConstraints = false
    t.dataSource = self
    t.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    return t
  }()

  /// Increments on each retry tap to vary title/body after repeated failures.
  private var attemptIndex = 0

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Retry → fails"
    view.backgroundColor = .systemGroupedBackground
    navigationItem.prompt = "Tap Retry; wait ~2.5s; error returns"

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    showInitialError()
  }

  // MARK: Flow

  private func showInitialError() {
    attemptIndex = 0
    applyErrorOverlay(message: "Couldn’t load data. Check your network.", isRetrying: false)
  }

  /// Builds either a loading or error `FKEmptyStateModel` and applies it to `tableView`.
  private func applyErrorOverlay(message: String, isRetrying: Bool) {
    var model = FKEmptyStateModel.scenario(.loadFailed)
      .withImage(UIImage(systemName: "wifi.exclamationmark"))
      .withDescription(message)
    model.phase = isRetrying ? .loading : .error
    model.backgroundColor = .systemBackground
    if isRetrying {
      model.loadingMessage = "Retrying…"
      model.title = nil
      model.description = nil
      model.hidesDescriptionForLoadingPhase = true
    } else {
      model.loadingMessage = nil
      model.title = attemptIndex > 0 ? "Still can’t load" : "Couldn’t load"
      model.hidesDescriptionForLoadingPhase = false
    }

    tableView.fk_applyEmptyState(
      model,
      animated: true,
      actionHandler: { [weak self] in
        self?.startRetryFlow()
      }
    )
  }

  private func startRetryFlow() {
    attemptIndex += 1
    applyErrorOverlay(message: "Retry in progress…", isRetrying: true)

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
      guard let self else { return }
      let msg: String
      if self.attemptIndex >= 3 {
        msg = "Server is still unreachable (simulated). Error code: \(-1009 + self.attemptIndex)."
      } else {
        msg = "The request failed again. You can retry or leave this screen."
      }
      self.applyErrorOverlay(message: msg, isRetrying: false)
    }
  }
}

// MARK: - UITableViewDataSource

extension FKEmptyStateRetryFailureDemoViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
  }
}
