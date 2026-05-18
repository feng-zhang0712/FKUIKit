import AVFoundation
import Foundation
import UIKit

/// Result of loading waveform samples from an asset.
public enum FKAudioWaveformLoadResult: Sendable {
  case success(sampleCount: Int)
  case noAudioTrack
  case unreadableAsset
  case readFailed(String)
}

/// Static peak waveform for a media file (decode once; does not animate with playback).
@MainActor
public final class FKAudioWaveformView: UIView {

  private var samples: [Float] = []
  private var loadTask: Task<FKAudioWaveformLoadResult, Never>?

  public var barColor: UIColor = .systemBlue

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isAccessibilityElement = true
    accessibilityTraits = .updatesFrequently
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Extracts and normalizes peak samples from a media URL (downloads remote files locally first).
  @discardableResult
  public func loadWaveform(from url: URL, sampleCount: Int = 80) async -> FKAudioWaveformLoadResult {
    loadTask?.cancel()
    let task = Task { await performLoad(url: url, sampleCount: sampleCount) }
    loadTask = task
    return await task.value
  }

  /// Extracts waveform samples from an asset (uses ``AVURLAsset/url`` when available).
  @discardableResult
  public func loadWaveform(from asset: AVAsset, sampleCount: Int = 80) async -> FKAudioWaveformLoadResult {
    if let urlAsset = asset as? AVURLAsset {
      return await loadWaveform(from: urlAsset.url, sampleCount: sampleCount)
    }
    clearSamples()
    return .readFailed("Only URL-based assets are supported for waveform extraction.")
  }

  public override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext(), !samples.isEmpty else { return }

    context.setFillColor(UIColor.secondarySystemFill.cgColor)
    context.fill(rect)

    let barSlotWidth = rect.width / CGFloat(samples.count)
    let maxBarHeight = rect.height * 0.88
    context.setFillColor(barColor.cgColor)
    for (index, sample) in samples.enumerated() {
      let barHeight = max(2, CGFloat(sample) * maxBarHeight)
      let x = CGFloat(index) * barSlotWidth + barSlotWidth * 0.15
      let barWidth = max(1, barSlotWidth * 0.7)
      let y = (rect.height - barHeight) / 2
      context.fill(CGRect(x: x, y: y, width: barWidth, height: barHeight))
    }
  }

  // MARK: - Private

  private func performLoad(url: URL, sampleCount: Int) async -> FKAudioWaveformLoadResult {
    if Task.isCancelled {
      clearSamples()
      return .readFailed("Cancelled")
    }

    do {
      let localURL = try await localMediaURL(for: url)
      let shouldDeleteTemporary = !url.isFileURL
      defer {
        if shouldDeleteTemporary {
          try? FileManager.default.removeItem(at: localURL)
        }
      }

      let asset = AVURLAsset(
        url: localURL,
        options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
      )
      let tracks = try await asset.load(.tracks)
      guard let track = tracks.first(where: { $0.mediaType == .audio }) else {
        clearSamples()
        return .noAudioTrack
      }

      let readable = try await asset.load(.isReadable)
      guard readable else {
        clearSamples()
        return .unreadableAsset
      }

      let reader = try AVAssetReader(asset: asset)
      let output = AVAssetReaderTrackOutput(
        track: track,
        outputSettings: [
          AVFormatIDKey: kAudioFormatLinearPCM,
          AVLinearPCMIsFloatKey: false,
          AVLinearPCMBitDepthKey: 16,
          AVLinearPCMIsBigEndianKey: false,
          AVLinearPCMIsNonInterleaved: false,
        ]
      )
      output.alwaysCopiesSampleData = false
      reader.add(output)

      guard reader.startReading() else {
        clearSamples()
        return .readFailed(reader.error?.localizedDescription ?? "AVAssetReader could not start.")
      }

      var values: [Float] = []
      let sampleBudget = sampleCount * 400
      while reader.status == .reading, values.count < sampleBudget {
        if Task.isCancelled {
          reader.cancelReading()
          clearSamples()
          return .readFailed("Cancelled")
        }
        guard let sampleBuffer = output.copyNextSampleBuffer() else { break }
        appendPCMLevels(from: sampleBuffer, into: &values, limit: sampleBudget)
      }

      if reader.status == .failed {
        clearSamples()
        return .readFailed(reader.error?.localizedDescription ?? "AVAssetReader failed.")
      }

      guard !values.isEmpty else {
        clearSamples()
        return .readFailed("No PCM samples were decoded.")
      }

      let chunk = max(1, values.count / sampleCount)
      let downsampled = stride(from: 0, to: values.count, by: chunk).map { index -> Float in
        let slice = values[index..<min(index + chunk, values.count)]
        return slice.max() ?? 0
      }
      let peaks = Array(downsampled.prefix(sampleCount))
      let peak = peaks.max() ?? 0
      guard peak > 0 else {
        clearSamples()
        return .readFailed("Waveform peaks are zero.")
      }

      samples = peaks.map { min(1, $0 / peak) }
      setNeedsDisplay()
      return .success(sampleCount: samples.count)
    } catch {
      clearSamples()
      if Task.isCancelled {
        return .readFailed("Cancelled")
      }
      return .readFailed(error.localizedDescription)
    }
  }

  private func localMediaURL(for url: URL) async throws -> URL {
    if url.isFileURL {
      return url
    }
    return try await downloadTemporaryCopy(from: url)
  }

  private func downloadTemporaryCopy(from url: URL) async throws -> URL {
    let (data, response) = try await URLSession.shared.data(from: url)
    if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
      throw URLError(.badServerResponse)
    }
    guard !data.isEmpty else {
      throw URLError(.zeroByteResource)
    }
    let ext = url.pathExtension.isEmpty ? "mp3" : url.pathExtension
    let fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("fk-waveform-\(UUID().uuidString).\(ext)")
    try data.write(to: fileURL, options: .atomic)
    return fileURL
  }

  private func appendPCMLevels(
    from sampleBuffer: CMSampleBuffer,
    into values: inout [Float],
    limit: Int
  ) {
    guard let block = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
    var length = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    CMBlockBufferGetDataPointer(
      block,
      atOffset: 0,
      lengthAtOffsetOut: nil,
      totalLengthOut: &length,
      dataPointerOut: &dataPointer
    )
    guard let dataPointer, length > 0 else { return }

    let int16Count = length / MemoryLayout<Int16>.size
    dataPointer.withMemoryRebound(to: Int16.self, capacity: int16Count) { pointer in
      for index in 0..<int16Count where values.count < limit {
        let level = Float(abs(pointer[index])) / Float(Int16.max)
        values.append(level)
      }
    }
  }

  private func clearSamples() {
    samples = []
    setNeedsDisplay()
  }
}
