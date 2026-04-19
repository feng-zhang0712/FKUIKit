//
//  FKNetworkExampleViewController.swift
//  FKKitExamples
//

import UIKit
import FKCompositeKit

/// Demonstrates FKCompositeKit networking: GET/POST, multipart upload, and file download.
final class FKNetworkExampleViewController: UIViewController {

  private let logView: UITextView = {
    let view = UITextView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isEditable = false
    view.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    view.backgroundColor = .secondarySystemGroupedBackground
    view.layer.cornerRadius = 10
    view.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    return view
  }()

  private lazy var stackView: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [
      makeButton(title: "GET (/todos/1)", action: #selector(runGetExample)),
      makeButton(title: "POST (/posts)", action: #selector(runPostExample)),
      makeButton(title: "Upload (multipart)", action: #selector(runUploadExample)),
      makeButton(title: "Download (image)", action: #selector(runDownloadExample)),
      makeButton(title: "Clear log", action: #selector(clearLogs)),
    ])
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .vertical
    stack.spacing = 10
    return stack
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKNetwork"
    view.backgroundColor = .systemGroupedBackground

    FKNetwork.configure {
      $0.baseURL = ""
      $0.logLevel = .verbose
      $0.timeoutInterval = 15
      $0.retryCount = 1
    }

    view.addSubview(stackView)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      logView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 14),
      logView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    appendLog("Network configured; requests use full URLs.")
  }

  // MARK: - Examples

  @objc private func runGetExample() {
    appendLog("GET /todos/1 …")
    Task {
      struct Todo: Decodable, Sendable {
        let id: Int
        let title: String
        let completed: Bool
      }

      do {
        let todo: Todo = try await FKNetwork.shared.get("https://jsonplaceholder.typicode.com/todos/1")
        appendLog("GET ok: id=\(todo.id), completed=\(todo.completed), title=\(todo.title)")
      } catch {
        appendLog("GET error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func runPostExample() {
    appendLog("POST /posts …")
    Task {
      struct PostResponse: Decodable, Sendable {
        let id: Int
        let title: String
      }

      do {
        let response: PostResponse = try await FKNetwork.shared.post(
          "https://jsonplaceholder.typicode.com/posts",
          json: [
            "title": "FKKit demo",
            "body": "Hello from FKNetwork",
            "userId": 1,
          ]
        )
        appendLog("POST ok: id=\(response.id), title=\(response.title)")
      } catch {
        appendLog("POST error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func runUploadExample() {
    appendLog("Multipart upload to httpbin …")
    Task {
      struct UploadEchoResponse: Decodable, Sendable {
        let headers: [String: String]?
        let url: String?
      }

      do {
        let payload = Data("FKNetwork upload demo".utf8)
        let fields = [FKMultipartField(name: "file", data: payload, filename: "demo.txt", mimeType: "text/plain")]
        let response: UploadEchoResponse = try await FKNetwork.shared.upload(
          path: "https://httpbin.org/post",
          fields: fields,
          onProgress: { [weak self] progress in
            Task { @MainActor [weak self] in
              self?.appendLog(String(format: "Upload progress: %.0f%%", progress * 100))
            }
          }
        )
        appendLog("Upload ok: url=\(response.url ?? "-"), headerCount=\(response.headers?.count ?? 0)")
      } catch {
        appendLog("Upload error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func runDownloadExample() {
    appendLog("Download image https://httpbin.org/image/png …")
    Task {
      do {
        let localURL = try await FKNetwork.download.download(
          url: "https://httpbin.org/image/png",
          onProgress: { [weak self] progress in
            Task { @MainActor [weak self] in
              self?.appendLog(String(format: "Download progress: %.0f%%", progress * 100))
            }
          }
        )
        appendLog("Download ok: \(localURL.lastPathComponent)")
      } catch {
        appendLog("Download error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Helpers

  @objc private func clearLogs() {
    logView.text = ""
  }

  private func makeButton(title: String, action: Selector) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    let button = UIButton(configuration: config, primaryAction: nil)
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  @MainActor
  private func appendLog(_ text: String) {
    let old = logView.text ?? ""
    let timestamp = Self.timeFormatter.string(from: Date())
    let next = old.isEmpty ? "[\(timestamp)] \(text)" : "\(old)\n[\(timestamp)] \(text)"
    logView.text = next
    let range = NSRange(location: max(0, next.count - 1), length: 1)
    logView.scrollRangeToVisible(range)
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
