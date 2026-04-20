import Foundation

#if os(iOS)
import QuickLook
import UIKit

public extension FKFileManager {
  /// Builds activity controller for quick file sharing.
  func makeShareController(for fileURL: URL) -> UIActivityViewController {
    UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
  }

  /// Builds Quick Look preview controller for one local file.
  ///
  /// Keep the returned data source strongly referenced while presenting.
  func makePreviewController(for fileURL: URL) -> (controller: QLPreviewController, dataSource: QLPreviewControllerDataSource) {
    let dataSource = FKSingleFilePreviewDataSource(fileURL: fileURL)
    let controller = QLPreviewController()
    controller.dataSource = dataSource
    return (controller, dataSource)
  }
}

/// Data source for Quick Look single-file preview.
public final class FKSingleFilePreviewDataSource: NSObject, QLPreviewControllerDataSource {
  private let fileURL: URL

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

  public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    fileURL as NSURL
  }
}
#endif
