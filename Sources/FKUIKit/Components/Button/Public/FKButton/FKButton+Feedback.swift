import AudioToolbox
import UIKit

extension FKButton {
  // MARK: - Sound feedback

  func syncSoundFeedbackResourcesIfNeeded() {
    syncCustomSoundResource(
      for: soundFeedbackConfiguration.pressDownSound,
      cachedURL: &cachedPressDownSoundURL,
      cachedSoundID: &cachedPressDownSoundID
    )
    syncCustomSoundResource(
      for: soundFeedbackConfiguration.primaryActionSound,
      cachedURL: &cachedPrimaryActionSoundURL,
      cachedSoundID: &cachedPrimaryActionSoundID
    )
  }

  func syncCustomSoundResource(
    for sound: FKButtonSoundFeedbackConfiguration.Sound,
    cachedURL: inout URL?,
    cachedSoundID: inout SystemSoundID?
  ) {
    guard case .customFileURL(let url) = sound else {
      cachedURL = nil
      disposeCachedSoundIfNeeded(soundID: &cachedSoundID)
      return
    }
    guard cachedURL != url else { return }
    cachedURL = url
    disposeCachedSoundIfNeeded(soundID: &cachedSoundID)
    var createdSoundID: SystemSoundID = 0
    let status = AudioServicesCreateSystemSoundID(url as CFURL, &createdSoundID)
    guard status == kAudioServicesNoError else {
      cachedURL = nil
      return
    }
    cachedSoundID = createdSoundID
  }

  func playSoundFeedback(
    for sound: FKButtonSoundFeedbackConfiguration.Sound,
    cachedCustomSoundID: SystemSoundID?
  ) {
    switch sound {
    case .system(let systemSoundID):
      AudioServicesPlaySystemSound(systemSoundID)
    case .customFileURL:
      guard let cachedCustomSoundID else { return }
      AudioServicesPlaySystemSound(cachedCustomSoundID)
    }
  }

  func emitInteractionFeedback(for trigger: InteractionFeedbackTrigger) {
    switch trigger {
    case .pressDown:
      if hapticsConfiguration.onPressDown {
        impactFeedbackGenerator.impactOccurred()
      }
      if soundFeedbackConfiguration.onPressDown {
        playSoundFeedback(for: soundFeedbackConfiguration.pressDownSound, cachedCustomSoundID: cachedPressDownSoundID)
      }
    case .primaryAction:
      if hapticsConfiguration.onPrimaryAction {
        impactFeedbackGenerator.impactOccurred()
      }
      if soundFeedbackConfiguration.onPrimaryAction {
        playSoundFeedback(for: soundFeedbackConfiguration.primaryActionSound, cachedCustomSoundID: cachedPrimaryActionSoundID)
      }
    }
  }

  func disposeCachedSoundIfNeeded(soundID: inout SystemSoundID?) {
    guard let unwrappedSoundID = soundID else { return }
    AudioServicesDisposeSystemSoundID(unwrappedSoundID)
    soundID = nil
  }
  
  // MARK: - Pointer interaction (iPadOS)

  func syncPointerInteractionIfNeeded() {
    guard #available(iOS 13.4, *), traitCollection.userInterfaceIdiom == .pad || traitCollection.userInterfaceIdiom == .mac else {
      return
    }
    if pointerConfiguration.isEnabled {
      if pointerInteraction == nil {
        let interaction = UIPointerInteraction(delegate: self)
        addInteraction(interaction)
        pointerInteraction = interaction
      }
    } else {
      if let interaction = pointerInteraction {
        removeInteraction(interaction)
        pointerInteraction = nil
      }
      isPointerHovered = false
    }
  }

  func applyPointerHoverVisualsIfNeeded() {
    guard pointerConfiguration.isEnabled, pointerConfiguration.showsHoverHighlight else { return }
    // Keep simple: apply an alpha multiplier on top of current computed alpha.
    if isPointerHovered {
      alpha *= pointerConfiguration.hoverAlphaMultiplier
    } else {
      requestVisualRefresh()
    }
  }
}
