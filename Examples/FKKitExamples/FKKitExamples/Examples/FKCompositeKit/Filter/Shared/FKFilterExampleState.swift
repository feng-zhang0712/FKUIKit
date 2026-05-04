import Foundation
import FKCompositeKit

/// Mutable filter models for examples; paired with ``FKFilterExamplePanelFactoryBuilder``.
@MainActor
final class FKFilterExampleState {
  var knowledgeModel: FKFilterTwoColumnModel?
  var courseModel: FKFilterTwoColumnModel?
  var fileTypeSections: [FKFilterSection] = []
  var platformSections: [FKFilterSection] = []
  var tagsSections: [FKFilterSection] = []
  var sortSection: FKFilterSection?

  init() {}

  /// All six panels populated (full hub demo).
  static func presetFullHub() -> FKFilterExampleState {
    let s = FKFilterExampleState()
    s.knowledgeModel = FKFilterExampleStaticData.knowledgeTwoColumn
    s.courseModel = FKFilterExampleStaticData.courseTwoColumn
    s.fileTypeSections = FKFilterExampleStaticData.fileTypeSections
    s.platformSections = FKFilterExampleStaticData.platformSections
    s.tagsSections = FKFilterExampleStaticData.tagsSections
    s.sortSection = FKFilterExampleStaticData.sortSection
    return s
  }

  /// Equal-width strip: platform + course grid + tags.
  static func presetEqualBusiness() -> FKFilterExampleState {
    let s = FKFilterExampleState()
    s.courseModel = FKFilterExampleStaticData.courseTwoColumn
    s.platformSections = FKFilterExampleStaticData.platformSections
    s.tagsSections = FKFilterExampleStaticData.tagsSections
    return s
  }

  /// Equal-width strip: knowledge tree + file types + sort.
  static func presetEqualKnowledge() -> FKFilterExampleState {
    let s = FKFilterExampleState()
    s.knowledgeModel = FKFilterExampleStaticData.knowledgeTwoColumn
    s.fileTypeSections = FKFilterExampleStaticData.fileTypeSections
    s.sortSection = FKFilterExampleStaticData.sortSection
    return s
  }
}
