import UIKit
import FKCoreKit

final class FKNetworkExampleViewController: UIViewController {
  private let network: Networkable
  private var cancellableTask: Cancellable?
  private var uploadTask: Cancellable?
  private var downloadTask: Cancellable?
  private var storedResumeData: Data?

  private let textView = UITextView()
  private let stackView = UIStackView()

  init() {
    network = FKNetworkExampleViewController.makeClient()
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKNetwork"
    view.backgroundColor = .systemBackground
    setupLayout()
    appendLog("FKNetwork demo initialized.")
  }

  deinit {
    cancellableTask?.cancel()
    uploadTask?.cancel()
    downloadTask?.cancel()
  }

  private static func makeClient() -> FKNetworkClient {
    let config = FKNetworkConfiguration.shared
    config.environmentMap = [
      .development: .init(
        baseURL: URL(string: "https://jsonplaceholder.typicode.com")!,
        timeout: 20,
        defaultHeaders: ["Accept": "application/json"]
      )
    ]
    config.environment = .development
    config.commonQueryItems = ["source": "FKNetworkExample"]
    config.callbackOnMainQueue = true
    config.logger = FKDefaultNetworkLogger()
    if #available(iOS 12.0, *) {
      config.networkStatusProvider = FKNetworkReachability()
    }
    return FKNetworkClient(config: config)
  }

  private func setupLayout() {
    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false

    let actions: [(String, Selector)] = [
      ("GET (Closure)", #selector(runGetRequest)),
      ("POST (Closure)", #selector(runPostRequest)),
      ("GET with Common Params", #selector(runCommonParamsRequest)),
      ("GET with Custom Header", #selector(runCustomHeaderRequest)),
      ("GET (async/await)", #selector(runAsyncAwaitRequest)),
      ("Cached Request", #selector(runCachedRequest)),
      ("Cancelable Request", #selector(runCancelableRequest)),
      ("Cancel Current Request", #selector(cancelCurrentRequest)),
      ("Upload with Progress", #selector(runUploadRequest)),
      ("Download with Progress", #selector(runDownloadRequest)),
      ("Resume Download", #selector(resumeDownloadRequest)),
      ("Clear Logs", #selector(clearLogs)),
    ]

    for action in actions {
      let button = UIButton(type: .system)
      button.setTitle(action.0, for: .normal)
      button.contentHorizontalAlignment = .left
      button.addTarget(self, action: action.1, for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }

    textView.isEditable = false
    textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    textView.backgroundColor = .secondarySystemBackground
    textView.layer.cornerRadius = 10
    textView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stackView)
    view.addSubview(textView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      textView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),
      textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
    ])
  }

  @objc private func runGetRequest() {
    appendLog("➡️ GET /users/1")
    cancellableTask = network.send(FKNetworkGETRequest(userID: 1)) { [weak self] result in
      switch result {
      case let .success(user):
        self?.appendLog("✅ GET success: \(user.name), email: \(user.email ?? "nil")")
      case let .failure(error):
        self?.appendLog("❌ GET failed: \(error.localizedDescription)")
      }
    }
  }

  @objc private func runPostRequest() {
    appendLog("➡️ POST /posts")
    cancellableTask = network.send(
      FKNetworkPOSTRequest(
        title: "FKNetwork Demo",
        body: "POST request from FKNetwork example",
        userID: 1
      )
    ) { [weak self] result in
      switch result {
      case let .success(post):
        self?.appendLog("✅ POST success: id=\(post.id ?? -1), title=\(post.title)")
      case let .failure(error):
        self?.appendLog("❌ POST failed: \(error.localizedDescription)")
      }
    }
  }

  @objc private func runCommonParamsRequest() {
    appendLog("➡️ GET with common query params")
    cancellableTask = network.send(FKNetworkCommonQueryRequest()) { [weak self] result in
      switch result {
      case let .success(list):
        self?.appendLog("✅ Common params request success: count=\(list.posts.count)")
      case let .failure(error):
        self?.appendLog("❌ Common params request failed: \(error.localizedDescription)")
      }
    }
  }

  @objc private func runCustomHeaderRequest() {
    appendLog("➡️ GET with custom request header")
    cancellableTask = network.send(FKNetworkCustomHeaderRequest()) { [weak self] result in
      switch result {
      case let .success(list):
        self?.appendLog("✅ Custom header request success: count=\(list.posts.count)")
      case let .failure(error):
        self?.appendLog("❌ Custom header request failed: \(error.localizedDescription)")
      }
    }
  }

  @objc private func runAsyncAwaitRequest() {
    appendLog("➡️ async/await GET /users/2")
    Task { [weak self] in
      guard let self else { return }
      do {
        let user = try await network.send(FKNetworkGETRequest(userID: 2))
        appendLog("✅ async/await success: \(user.name)")
      } catch {
        appendLog("❌ async/await failed: \(error.localizedDescription)")
      }
    }
  }

  @objc private func runCachedRequest() {
    appendLog("➡️ Cached GET /users/1 (memory + disk, ttl=120s)")
    cancellableTask = network.send(FKNetworkCachedRequest(userID: 1)) { [weak self] result in
      switch result {
      case let .success(user):
        self?.appendLog("✅ Cached request success: \(user.name)")
      case let .failure(error):
        self?.appendLog("❌ Cached request failed: \(error.localizedDescription)")
      }
    }
  }

  @objc private func runCancelableRequest() {
    appendLog("➡️ Start cancellable request")
    cancellableTask = network.send(FKNetworkCancellableRequest()) { [weak self] result in
      switch result {
      case let .success(list):
        self?.appendLog("✅ Cancellable request completed: count=\(list.posts.count)")
      case let .failure(error):
        self?.appendLog("❌ Cancellable request failed: \(error.localizedDescription)")
      }
    }
  }

  @objc private func cancelCurrentRequest() {
    cancellableTask?.cancel()
    uploadTask?.cancel()
    downloadTask?.cancel()
    appendLog("🛑 Active request cancelled.")
  }

  @objc private func runUploadRequest() {
    appendLog("➡️ Upload demo file with progress")
    let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("fk-upload-demo.txt")
    do {
      let data = Data("FKNetwork upload demo".utf8)
      try data.write(to: tempFile, options: .atomic)
    } catch {
      appendLog("❌ Failed to create upload file: \(error.localizedDescription)")
      return
    }

    var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
    request.httpMethod = "POST"
    uploadTask = network.upload(request, fileURL: tempFile, progress: { [weak self] progress in
      self?.appendLog(String(format: "⬆️ Upload progress: %.0f%%", progress * 100))
    }, completion: { [weak self] result in
      switch result {
      case let .success(data):
        self?.appendLog("✅ Upload success: response bytes=\(data.count)")
      case let .failure(error):
        self?.appendLog("❌ Upload failed: \(error.localizedDescription)")
      }
    })
  }

  @objc private func runDownloadRequest() {
    appendLog("➡️ Download file with progress")
    var request = URLRequest(url: URL(string: "https://speed.hetzner.de/1MB.bin")!)
    request.httpMethod = "GET"
    storedResumeData = nil

    downloadTask = network.download(request, resumeData: nil, progress: { [weak self] progress in
      self?.appendLog(String(format: "⬇️ Download progress: %.0f%%", progress * 100))
    }, completion: { [weak self] result in
      self?.handleDownloadResult(result)
    })
  }

  @objc private func resumeDownloadRequest() {
    guard let resumeData = storedResumeData else {
      appendLog("ℹ️ No resume data. Start download and cancel first.")
      return
    }
    appendLog("➡️ Resume download from resumeData")
    var request = URLRequest(url: URL(string: "https://speed.hetzner.de/1MB.bin")!)
    request.httpMethod = "GET"

    downloadTask = network.download(request, resumeData: resumeData, progress: { [weak self] progress in
      self?.appendLog(String(format: "⬇️ Resume progress: %.0f%%", progress * 100))
    }, completion: { [weak self] result in
      self?.handleDownloadResult(result)
    })
  }

  private func handleDownloadResult(_ result: Result<(fileURL: URL, resumeData: Data?), NetworkError>) {
    switch result {
    case let .success((tempURL, _)):
      let destination = FileManager.default.temporaryDirectory.appendingPathComponent("fk-download-demo.bin")
      do {
        if FileManager.default.fileExists(atPath: destination.path) {
          try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
        appendLog("✅ Download success: \(destination.path)")
      } catch {
        appendLog("❌ Move downloaded file failed: \(error.localizedDescription)")
      }
    case let .failure(error):
      if case let .underlying(underlyingError as NSError) = error,
         let data = underlyingError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
        storedResumeData = data
        appendLog("⚠️ Download interrupted, resumeData captured.")
      }
      appendLog("❌ Download failed: \(error.localizedDescription)")
    }
  }

  @objc private func clearLogs() {
    textView.text = ""
  }

  private func appendLog(_ message: String) {
    let prefix = DateFormatter.logFormatter.string(from: Date())
    let line = "[\(prefix)] \(message)\n"
    textView.text.append(line)
    let range = NSRange(location: max(textView.text.count - 1, 0), length: 1)
    textView.scrollRangeToVisible(range)
  }
}

private extension DateFormatter {
  static let logFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
