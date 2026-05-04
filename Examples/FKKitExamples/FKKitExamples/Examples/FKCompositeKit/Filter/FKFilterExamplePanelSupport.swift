import UIKit
import FKCompositeKit

/// Builds a ``FKFilterPanelFactory`` for each ``FKFilterPanelKind`` used in the sample app.
enum FKFilterExamplePanelSupport {
  @MainActor
  static func makePanelFactory(
    knowledgeModel: @escaping () -> FKFilterTwoColumnModel?,
    courseModel: @escaping () -> FKFilterTwoColumnModel?,
    fileTypeSections: @escaping () -> [FKFilterSection],
    platformSections: @escaping () -> [FKFilterSection],
    tagsSections: @escaping () -> [FKFilterSection],
    sortSection: @escaping () -> FKFilterSection?,
    onKnowledgeChange: @escaping (FKFilterTwoColumnModel) -> Void,
    onCourseChange: @escaping (FKFilterTwoColumnModel) -> Void,
    onFileTypeChange: @escaping ([FKFilterSection]) -> Void,
    onPlatformChange: @escaping ([FKFilterSection]) -> Void,
    onTagsChange: @escaping ([FKFilterSection]) -> Void,
    onSortChange: @escaping (FKFilterSection) -> Void,
    onTagsSelectionEmptied: (() -> Void)? = nil
  ) -> FKFilterPanelFactory {
    FKFilterPanelFactory(
      panelSources: [
        .hierarchy: .twoColumnList(
          model: knowledgeModel,
          onChange: onKnowledgeChange,
          configuration: .init(
            leftCellStyle: FKFilterExampleAppearance.panelListCellStyle,
            rightCellStyle: FKFilterExampleAppearance.panelListCellStyle
          )
        ),
        .dualHierarchy: .twoColumnGrid(
          model: courseModel,
          onChange: onCourseChange,
          configuration: .init(
            itemHeight: 36,
            itemColumns: 2,
            pillStyle: FKFilterExampleAppearance.panelPillStyle,
            heightBehavior: .automatic(minimum: 80)
          )
        ),
        .gridPrimary: .chips(
          sections: fileTypeSections,
          onChange: onFileTypeChange,
          configuration: .init(
            columns: 4,
            interitemSpacing: 8,
            lineSpacing: 10,
            contentInsets: .init(top: 10, left: 10, bottom: 10, right: 10),
            itemRowHeight: 38,
            pillStyle: FKFilterExampleAppearance.panelPillStyle
          )
        ),
        .gridSecondary: .chips(
          sections: platformSections,
          onChange: onPlatformChange,
          configuration: .init(
            columns: 2,
            interitemSpacing: 8,
            lineSpacing: 10,
            contentInsets: .init(top: 10, left: 10, bottom: 10, right: 10),
            itemRowHeight: 38,
            pillStyle: FKFilterExampleAppearance.panelPillStyle
          )
        ),
        .tags: .chips(
          sections: tagsSections,
          onChange: { newSections in
            onTagsChange(newSections)
            let selectedCount = newSections.flatMap(\.items).filter(\.isSelected).count
            if selectedCount == 0 {
              onTagsSelectionEmptied?()
            }
          },
          configuration: .init(
            columns: 2,
            interitemSpacing: 8,
            lineSpacing: 10,
            contentInsets: .init(top: 10, left: 10, bottom: 10, right: 10),
            itemRowHeight: 38,
            heightBehavior: .capped(maximum: 320, minimum: 80),
            pillStyle: FKFilterExampleAppearance.panelPillStyle
          )
        ),
        .singleList: .singleList(
          section: sortSection,
          onChange: onSortChange,
          configuration: .init(
            rowHeight: 44,
            cellStyle: FKFilterListCellStyle(
              textAlignment: .center
            )
          )
        ),
      ],
      loadingTitle: "Loading...",
      wrapsPanelWithTopHairline: true
    )
  }
}
