import UIKit
import FKCompositeKit

/// Builds a ``FKFilterPanelFactory`` bound to a shared ``FKFilterExampleDemoState`` (no per-kind no-op parameters at call sites).
enum FKFilterExamplePanelFactoryBuilder {
  @MainActor
  static func makeFactory(
    bindingTo state: FKFilterExampleState,
    onTagsSelectionEmptied: (() -> Void)? = nil
  ) -> FKFilterPanelFactory {
    FKFilterPanelFactory(
      sourcesByPanelKind: [
        .hierarchy: .twoColumnList(
          model: { state.knowledgeModel },
          onChange: { state.knowledgeModel = $0 },
          configuration: .init(
            leftCellStyle: FKFilterExampleAppearance.panelSidebarListCellStyle,
            rightCellStyle: FKFilterExampleAppearance.panelListCellStyle
          )
        ),
        .dualHierarchy: .twoColumnGrid(
          model: { state.courseModel },
          onChange: { state.courseModel = $0 },
          configuration: .init(
            itemHeight: 36,
            itemColumns: 2,
            pillStyle: FKFilterExampleAppearance.panelPillStyle
          )
        ),
        .gridPrimary: .chips(
          sections: { state.fileTypeSections },
          onChange: { state.fileTypeSections = $0 },
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
          sections: { state.platformSections },
          onChange: { state.platformSections = $0 },
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
          sections: { state.tagsSections },
          onChange: { newSections in
            state.tagsSections = newSections
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
          section: { state.sortSection },
          onChange: { state.sortSection = $0 },
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
