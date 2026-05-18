import Foundation

/// Infers container, delivery mode, and suggested engine from a URL.
public enum FKMediaFormatProbe {

  /// Probes the given URL using extension, scheme, and optional HTTP metadata.
  public static func probe(url: URL, headers: [String: String]? = nil) -> FKMediaFormatDescriptor {
    let scheme = (url.scheme ?? "").lowercased()
    let ext = url.pathExtension.lowercased()
    let contentType = headers?["Content-Type"] ?? headers?["content-type"]

    if let contentType {
      if let fromMIME = descriptorFromMIME(contentType, url: url) {
        return fromMIME
      }
    }

    if scheme == "rtmp" || scheme == "rtmps" {
      return FKMediaFormatDescriptor(
        container: .flv,
        mediaType: .multiplex,
        suggestedEngine: .extended,
        delivery: .rtmp,
        isLive: true,
        allowsAVFoundation: false,
        allowsExtended: true
      )
    }

    if scheme == "rtsp" {
      return FKMediaFormatDescriptor(
        container: .unknown,
        mediaType: .multiplex,
        suggestedEngine: .extended,
        delivery: .rtsp,
        isLive: true,
        allowsAVFoundation: false,
        allowsExtended: true
      )
    }

    if ext == "m3u8" || url.absoluteString.lowercased().contains(".m3u8") {
      let isLive = url.absoluteString.lowercased().contains("live")
      return FKMediaFormatDescriptor(
        container: .m3u8,
        mediaType: .multiplex,
        suggestedEngine: .avFoundation,
        delivery: .hls(onDemand: !isLive),
        isLive: isLive,
        allowsAVFoundation: true,
        allowsExtended: false
      )
    }

    if ext == "mpd" {
      return FKMediaFormatDescriptor(
        container: .mpd,
        mediaType: .multiplex,
        suggestedEngine: .extended,
        delivery: .dash,
        isLive: false,
        allowsAVFoundation: false,
        allowsExtended: true
      )
    }

    if ext == "flv" || url.absoluteString.lowercased().contains(".flv") {
      return FKMediaFormatDescriptor(
        container: .flv,
        mediaType: .multiplex,
        suggestedEngine: .extended,
        delivery: .httpFLV,
        isLive: true,
        allowsAVFoundation: false,
        allowsExtended: true
      )
    }

    return descriptorFromExtension(ext, url: url)
  }

  // MARK: - Private

  private static func descriptorFromExtension(_ ext: String, url: URL) -> FKMediaFormatDescriptor {
    let container = FKMediaContainer(rawValue: ext) ?? .unknown
    let mediaType = mediaType(for: container)
    let avContainers: Set<FKMediaContainer> = [
      .mp4, .m4v, .mov, .threeGP, .threeG2,
      .m4a, .aac, .mp3, .wav, .aiff, .caf, .amr, .m3u8,
    ]
    let extendedOnly: Set<FKMediaContainer> = [
      .mkv, .webm, .avi, .wmv, .asf, .flv, .f4v,
      .mpg, .mpeg, .vob, .rm, .rmvb, .ogv, .mxf,
      .ogg, .oga, .wma, .ape, .pls, .xspf, .mpd,
    ]
    let hybrid: Set<FKMediaContainer> = [.ts, .mts, .m2ts, .dv, .flac, .opus, .m3u]

    let allowsAV = avContainers.contains(container) || hybrid.contains(container)
    let allowsExtended = extendedOnly.contains(container) || hybrid.contains(container) || container == .unknown

    let delivery: FKMediaDelivery = {
      if url.isFileURL { return .file }
      if ["http", "https"].contains(url.scheme?.lowercased() ?? "") { return .progressiveHTTP }
      return .file
    }()

    if !allowsAV && !allowsExtended {
      return FKMediaFormatDescriptor(
        container: container,
        mediaType: mediaType,
        suggestedEngine: .avFoundation,
        delivery: delivery,
        isLive: false,
        allowsAVFoundation: false,
        allowsExtended: false
      )
    }

    let suggested: FKMediaEngineKind = {
      if extendedOnly.contains(container) { return .extended }
      if avContainers.contains(container) { return .avFoundation }
      if hybrid.contains(container) { return .avFoundation }
      return allowsAV ? .avFoundation : .extended
    }()

    return FKMediaFormatDescriptor(
      container: container,
      mediaType: mediaType,
      suggestedEngine: suggested,
      delivery: delivery,
      isLive: false,
      allowsAVFoundation: allowsAV,
      allowsExtended: allowsExtended
    )
  }

  private static func descriptorFromMIME(_ mime: String, url: URL) -> FKMediaFormatDescriptor? {
    let lower = mime.lowercased()
    if lower.contains("mpegurl") || lower.contains("m3u8") {
      return probe(url: url, headers: nil)
    }
    if lower.contains("mp4") {
      return descriptorFromExtension("mp4", url: url)
    }
    if lower.contains("quicktime") {
      return descriptorFromExtension("mov", url: url)
    }
    if lower.contains("mpeg") && lower.contains("audio") {
      return descriptorFromExtension("mp3", url: url)
    }
    return nil
  }

  private static func mediaType(for container: FKMediaContainer) -> FKMediaType {
    switch container {
    case .m4a, .aac, .mp3, .wav, .aiff, .caf, .amr, .flac, .ogg, .oga, .opus, .wma, .ape:
      return .audio
    case .mp4, .m4v, .mov, .mkv, .webm, .avi, .wmv, .flv, .threeGP, .threeG2, .mts, .m2ts, .ts, .dv, .ogv, .mxf, .mpg, .mpeg, .vob, .rm, .rmvb, .f4v, .asf:
      return .video
    case .m3u8, .m3u, .pls, .xspf, .mpd, .unknown:
      return .multiplex
    }
  }
}
