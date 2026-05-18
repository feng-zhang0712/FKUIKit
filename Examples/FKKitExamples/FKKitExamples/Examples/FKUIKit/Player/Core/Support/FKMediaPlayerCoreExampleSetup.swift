import FKUIKit

/// Registers Core-related example hooks before any extended URL is loaded.
enum FKMediaPlayerCoreExampleSetup {

  static func configureAtLaunch() {
    FKMediaPlayerExtended.registerExtendedEngineFactory(FKMediaExtendedEngineExampleFactory.shared)
  }
}
