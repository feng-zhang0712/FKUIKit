import AVFoundation
import UIKit

/// Destination for video rendering. Used on the main actor only.
public enum FKMediaRenderTarget {
  case playerLayer(AVPlayerLayer)
  case containerView(UIView)
  case none
}
