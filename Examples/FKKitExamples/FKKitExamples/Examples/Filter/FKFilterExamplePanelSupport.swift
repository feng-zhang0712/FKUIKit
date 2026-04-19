import UIKit
import FKCompositeKit

/// Builds `FKFilterPanelFactory` panels for each `FKFilterBarPresentation.PanelKind` in the sample app.
enum FKFilterExamplePanelSupport {
  @MainActor
  static func makePanel(
    kind: FKFilterBarPresentation.PanelKind,
    filterBar: FKFilterBarPresentation,
    knowledgeModel: FKFilterTwoColumnModel?,
    courseModel: FKFilterTwoColumnModel?,
    fileTypeSections: [FKFilterSection],
    platformSections: [FKFilterSection],
    tagsSections: [FKFilterSection],
    sortSection: FKFilterSection?,
    onKnowledgeChange: @escaping (FKFilterTwoColumnModel) -> Void,
    onCourseChange: @escaping (FKFilterTwoColumnModel) -> Void,
    onFileTypeChange: @escaping ([FKFilterSection]) -> Void,
    onPlatformChange: @escaping ([FKFilterSection]) -> Void,
    onTagsChange: @escaping ([FKFilterSection]) -> Void,
    onSortChange: @escaping (FKFilterSection) -> Void
  ) -> UIViewController? {
    let factory = FKFilterPanelFactory(
      sources: [
        .hierarchy: .twoColumnList(
          model: { knowledgeModel },
          onChange: onKnowledgeChange
        ),
        .dualHierarchy: .twoColumnGrid(
          model: { courseModel },
          onChange: onCourseChange,
          configuration: .init(
            itemHeight: 38,
            itemColumns: 2,
            heightBehavior: .fixed(460)
          )
        ),
        .gridPrimary: .chips(
          sections: { fileTypeSections },
          onChange: onFileTypeChange,
          configuration: .init(columns: 4)
        ),
        .gridSecondary: .chips(
          sections: { platformSections },
          onChange: onPlatformChange,
          configuration: .init(columns: 2)
        ),
        .tags: .chips(
          sections: { tagsSections },
          onChange: { newSections in
            onTagsChange(newSections)
            let selectedCount = newSections.flatMap(\.items).filter(\.isSelected).count
            if selectedCount == 0 { filterBar.updateBarTitle("标签", for: .tags) }
          },
          configuration: .init(columns: 2, heightBehavior: .capped(maximum: 320, minimum: 80))
        ),
        .singleList: .singleList(
          section: { sortSection },
          onChange: onSortChange,
          configuration: .init(
            cellStyle: .init(textAlignment: .center)
          )
        ),
      ],
      loadingTitle: "Loading...",
      wrapsTopHairline: true
    )
    return factory.makePanel(for: kind, using: filterBar)
  }
}
