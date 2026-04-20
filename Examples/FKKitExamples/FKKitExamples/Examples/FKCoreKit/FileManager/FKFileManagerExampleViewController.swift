import FKCoreKit
import UIKit

/// Interactive and copy-ready demo for FKFileManager.
/// Each button maps to one production-ready usage scenario.
final class FKFileManagerExampleViewController: UIViewController {
  // MARK: - UI

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let outputView = UITextView()

  // MARK: - State

  private let manager = FKFileManager.shared
  private var activeDownloadTaskID: Int?

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKFileManager"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendOutput("FKFileManager example loaded.")
  }

  // MARK: - Layout

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8

    outputView.translatesAutoresizingMaskIntoConstraints = false
    outputView.isEditable = false
    outputView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    outputView.backgroundColor = .secondarySystemBackground
    outputView.layer.cornerRadius = 8

    let actions: [(String, Selector)] = [
      ("1) Get Sandbox Directories", #selector(demoSandboxDirectories)),
      ("2) File Operations (Create/Delete/Move/Rename)", #selector(demoFileOperations)),
      ("3) Read/Write Text + JSON + Codable (async)", #selector(demoReadWriteAsync)),
      ("4) Read/Write via Closure Callback", #selector(demoReadWriteClosure)),
      ("5) Write Image Data", #selector(demoWriteImage)),
      ("6) Breakpoint Download Start", #selector(demoStartDownload)),
      ("7) Download Pause", #selector(demoPauseDownload)),
      ("8) Download Resume", #selector(demoResumeDownload)),
      ("9) Download Cancel", #selector(demoCancelDownload)),
      ("10) Single File Upload", #selector(demoSingleUpload)),
      ("11) Multi File Upload", #selector(demoMultiUpload)),
      ("12) Cache Size + Clean Cache", #selector(demoCacheOperations)),
      ("13) Zip Compress + Decompress", #selector(demoZipOperations)),
      ("14) Check Exists + File Info", #selector(demoFileInfo)),
      ("Clear On-screen Output", #selector(clearOutput)),
    ]

    for (title, selector) in actions {
      let button = UIButton(type: .system)
      button.setTitle(title, for: .normal)
      button.contentHorizontalAlignment = .left
      button.addTarget(self, action: selector, for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(outputView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.54),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      outputView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      outputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      outputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      outputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  // MARK: - 1) Get Sandbox Directories

  @objc private func demoSandboxDirectories() {
    let documents = manager.directoryURL(.documents)
    let caches = manager.directoryURL(.caches)
    let temporary = manager.directoryURL(.temporary)
    appendOutput("Documents: \(documents.path)")
    appendOutput("Caches: \(caches.path)")
    appendOutput("Tmp: \(temporary.path)")
  }

  // MARK: - 2) File Operations

  @objc private func demoFileOperations() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let docs = self.manager.directoryURL(.documents)
        let demoDir = docs.appendingPathComponent("FKFileManagerDemo", isDirectory: true)
        let source = demoDir.appendingPathComponent("source.txt")
        let moved = demoDir.appendingPathComponent("moved.txt")

        try await self.manager.createDirectory(at: demoDir, intermediate: true)
        try await self.manager.writeContent(.text("Initial content"), to: source)
        try await self.manager.moveItem(from: source, to: moved)
        let renamed = try await self.manager.renameItem(at: moved, newName: "renamed.txt")
        try await self.manager.removeItem(at: renamed)
        appendOutput("File operations completed successfully.")
      } catch {
        appendOutput("File operations failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 3) Read/Write Text/JSON/Codable (async/await)

  @objc private func demoReadWriteAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let docs = self.manager.directoryURL(.documents)
        let folder = docs.appendingPathComponent("FKFileManagerDemo", isDirectory: true)
        try await self.manager.createDirectory(at: folder, intermediate: true)

        let textURL = folder.appendingPathComponent("note.txt")
        try await self.manager.writeContent(.text("Hello FKFileManager"), to: textURL)
        let text = try await self.manager.readText(from: textURL)
        appendOutput("Text read: \(text)")

        let jsonURL = folder.appendingPathComponent("sample.json")
        try await self.manager.writeContent(
          .jsonObject([
            "module": AnySendable("FKFileManager"),
            "version": AnySendable(1),
            "stable": AnySendable(true),
          ]),
          to: jsonURL
        )
        let jsonData = try await self.manager.readData(from: jsonURL)
        appendOutput("JSON bytes: \(jsonData.count)")

        let modelURL = folder.appendingPathComponent("profile.json")
        let profile = FKPersistedTransfer(
          id: 1001,
          kind: .upload,
          state: .running,
          sourceURL: URL(string: "https://example.com/file.txt")!,
          destinationPath: folder.path,
          updatedAt: Date()
        )
        try await self.manager.writeModel(profile, to: modelURL)
        let loaded: FKPersistedTransfer = try await self.manager.readModel(FKPersistedTransfer.self, from: modelURL)
        appendOutput("Codable model read: \(loaded)")
      } catch {
        appendOutput("Read/write async failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 4) Closure callback usage

  @objc private func demoReadWriteClosure() {
    let docs = manager.directoryURL(.documents)
    let url = docs.appendingPathComponent("FKFileManagerDemo/closure.txt")

    manager.writeContent(.text("Written by closure API"), to: url, completion: { [weak self] writeResult in
      guard let self else { return }
      switch writeResult {
      case .success:
        self.appendOutput("Closure write succeeded.")
        Task { @MainActor [weak self] in
          guard let self else { return }
          self.manager.readText(from: url, completion: { [weak self] readResult in
            guard let self else { return }
            switch readResult {
            case let .success(text):
              self.appendOutput("Closure read text: \(text)")
            case let .failure(error):
              self.appendOutput("Closure read failed: \(error.localizedDescription)")
            }
          })
        }
      case let .failure(error):
        self.appendOutput("Closure write failed: \(error.localizedDescription)")
      }
    })
  }

  // MARK: - 5) Write image data

  @objc private func demoWriteImage() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let image = Self.makeDemoImage()
        guard let pngData = image.pngData() else {
          self.appendOutput("Image conversion failed.")
          return
        }
        let imageURL = self.manager.directoryURL(.documents).appendingPathComponent("FKFileManagerDemo/demo.png")
        try await self.manager.writeContent(.data(pngData), to: imageURL)
        appendOutput("Image written: \(imageURL.lastPathComponent), bytes: \(pngData.count)")
      } catch {
        appendOutput("Write image failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 6~9) Breakpoint download

  @objc private func demoStartDownload() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      guard let sourceURL = URL(string: "https://raw.githubusercontent.com/github/gitignore/main/Swift.gitignore") else {
        self.appendOutput("Download URL is invalid.")
        return
      }

      let request = FKDownloadRequest(
        sourceURL: sourceURL,
        destinationDirectory: self.manager.directoryURL(.caches),
        fileName: "Swift.gitignore",
        allowsBackground: true
      )

      do {
        let taskID = try await self.manager.download(
          request,
          progress: { [weak self] progress in
            self?.appendOutput("Download progress: \(Int(progress.progress * 100))% (\(progress.completedBytes)/\(progress.totalBytes))")
          },
          completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(output):
              self.appendOutput("Download completed: \(output.fileURL.path)")
            case let .failure(error):
              self.appendOutput("Download failed: \(error.localizedDescription)")
            }
          }
        )
        self.activeDownloadTaskID = taskID
        self.appendOutput("Download started. TaskID: \(taskID)")
      } catch {
        self.appendOutput("Download start failed: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoPauseDownload() {
    Task { @MainActor [weak self] in
      guard let self, let taskID = self.activeDownloadTaskID else {
        self?.appendOutput("No active download task.")
        return
      }
      await self.manager.pauseDownload(taskID: taskID)
      self.appendOutput("Download paused. TaskID: \(taskID)")
    }
  }

  @objc private func demoResumeDownload() {
    Task { @MainActor [weak self] in
      guard let self, let taskID = self.activeDownloadTaskID else {
        self?.appendOutput("No paused download task.")
        return
      }
      await self.manager.resumeDownload(taskID: taskID)
      self.appendOutput("Download resumed. TaskID: \(taskID)")
    }
  }

  @objc private func demoCancelDownload() {
    Task { @MainActor [weak self] in
      guard let self, let taskID = self.activeDownloadTaskID else {
        self?.appendOutput("No download task to cancel.")
        return
      }
      await self.manager.cancel(taskID: taskID)
      self.activeDownloadTaskID = nil
      self.appendOutput("Download canceled. TaskID: \(taskID)")
    }
  }

  // MARK: - 10~11) Single / Multi file upload

  @objc private func demoSingleUpload() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let fileURL = try await self.createUploadFile(name: "single-upload.txt", content: "Single file upload from FKFileManager.")
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        let uploadRequest = FKUploadRequest(
          urlRequest: request,
          files: [FKUploadFile(fieldName: "file", fileURL: fileURL)],
          formFields: ["scene": "single"]
        )

        _ = try await self.manager.upload(
          uploadRequest,
          progress: { [weak self] progress in
            self?.appendOutput("Single upload progress: \(Int(progress.progress * 100))%")
          },
          completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(value):
              self.appendOutput("Single upload success, response bytes: \(value.responseData.count)")
            case let .failure(error):
              self.appendOutput("Single upload failed: \(error.localizedDescription)")
            }
          }
        )
      } catch {
        appendOutput("Single upload setup failed: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoMultiUpload() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let first = try await self.createUploadFile(name: "multi-1.txt", content: "First file.")
        let second = try await self.createUploadFile(name: "multi-2.txt", content: "Second file.")

        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        let uploadRequest = FKUploadRequest(
          urlRequest: request,
          files: [
            FKUploadFile(fieldName: "files", fileURL: first),
            FKUploadFile(fieldName: "files", fileURL: second),
          ],
          formFields: ["scene": "multi"]
        )

        self.manager.upload(uploadRequest, completion: { [weak self] (result: Result<Int, FKFileManagerError>) in
          guard let self else { return }
          switch result {
          case let .success(taskID):
            self.appendOutput("Multi upload started via closure. TaskID: \(taskID)")
          case let .failure(error):
            self.appendOutput("Multi upload failed: \(error.localizedDescription)")
          }
        })
      } catch {
        appendOutput("Multi upload setup failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 12) Cache size + clean cache

  @objc private func demoCacheOperations() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let cacheURL = self.manager.directoryURL(.caches)
        let sizeBefore = try await self.manager.directorySize(at: cacheURL)
        appendOutput("Cache size before clean: \(sizeBefore) bytes")
        try await self.manager.clearCaches()
        let sizeAfter = try await self.manager.directorySize(at: cacheURL)
        appendOutput("Cache size after clean: \(sizeAfter) bytes")
      } catch {
        appendOutput("Cache operation failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 13) Zip compress + decompress

  @objc private func demoZipOperations() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let docs = self.manager.directoryURL(.documents)
      let source = docs.appendingPathComponent("FKFileManagerDemo")
      let zip = docs.appendingPathComponent("FKFileManagerDemo.zip")
      let unzipDir = docs.appendingPathComponent("FKFileManagerDemo_Unzipped", isDirectory: true)

      do {
        try await self.manager.zipItem(at: source, to: zip)
        appendOutput("Zip success: \(zip.path)")
      } catch {
        appendOutput("Zip result: \(error.localizedDescription)")
      }

      do {
        try await self.manager.unzipItem(at: zip, to: unzipDir)
        appendOutput("Unzip success: \(unzipDir.path)")
      } catch {
        appendOutput("Unzip result: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 14) Exists + info

  @objc private func demoFileInfo() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let target = self.manager.directoryURL(.documents).appendingPathComponent("FKFileManagerDemo/note.txt")
        let exists = self.manager.exists(at: target)
        appendOutput("Exists(\(target.lastPathComponent)): \(exists)")
        if exists {
          let info = try await self.manager.fileInfo(at: target)
          appendOutput("FileInfo -> size: \(info.sizeInBytes), mime: \(info.mimeType), modified: \(String(describing: info.modifiedAt))")
        }
      } catch {
        appendOutput("Read file info failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Helpers

  @objc private func clearOutput() {
    outputView.text = ""
    appendOutput("On-screen output cleared.")
  }

  /// Creates a temp text file used for upload scenarios.
  private func createUploadFile(name: String, content: String) async throws -> URL {
    let url = manager.directoryURL(.temporary).appendingPathComponent(name)
    try await manager.writeContent(.text(content), to: url)
    return url
  }

  /// Appends one line into on-screen log.
  private nonisolated func appendOutput(_ message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let line = "[\(DateFormatter.fileManagerDemoFormatter.string(from: Date()))] \(message)\n"
      self.outputView.text.append(line)
      let range = NSRange(location: max(self.outputView.text.count - 1, 0), length: 1)
      self.outputView.scrollRangeToVisible(range)
    }
  }

  /// Draws a small in-memory image for write-image demo.
  private static func makeDemoImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120))
    return renderer.image { context in
      UIColor.systemBlue.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
      UIColor.white.setFill()
      context.fill(CGRect(x: 16, y: 16, width: 88, height: 88))
    }
  }
}

private extension DateFormatter {
  static let fileManagerDemoFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
