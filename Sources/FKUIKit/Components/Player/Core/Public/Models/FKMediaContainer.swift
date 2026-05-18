import Foundation

/// Known media container inferred from a URL or file extension.
public enum FKMediaContainer: String, Sendable, Equatable, CaseIterable {
  case mp4
  case m4v
  case mov
  case threeGP = "3gp"
  case threeG2 = "3g2"
  case mts
  case m2ts
  case ts
  case dv
  case mkv
  case webm
  case avi
  case wmv
  case asf
  case flv
  case f4v
  case mpg
  case mpeg
  case vob
  case rm
  case rmvb
  case ogv
  case mxf
  case m4a
  case aac
  case mp3
  case wav
  case aiff
  case caf
  case amr
  case flac
  case ogg
  case oga
  case opus
  case wma
  case ape
  case m3u8
  case m3u
  case pls
  case xspf
  case mpd
  case unknown
}
