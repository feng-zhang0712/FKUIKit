import Foundation
import FKBusinessKit

/// Data provider to keep UI decoupled from server / storage.
protocol FKFilterExampleDataProviding: Sendable {
  func fetchKnowledgeTwoColumnModel() async -> FKFilterTwoColumnModel
  func fetchCourseTwoColumnModel() async -> FKFilterTwoColumnModel
  func fetchFileTypeSections() async -> [FKFilterSection]
  func fetchPlatformSections() async -> [FKFilterSection]
  func fetchTagsSections() async -> [FKFilterSection]
  func fetchSortSection() async -> FKFilterSection
}

final class FKFilterExampleMockDataProvider: FKFilterExampleDataProviding, Sendable {
  func fetchKnowledgeTwoColumnModel() async -> FKFilterTwoColumnModel {
    try? await Task.sleep(nanoseconds: 120_000_000)
    let all = FKFilterTwoColumnModel.Category(id: .init(rawValue: "all"), title: "全部", isSelected: false)
    let laws = FKFilterTwoColumnModel.Category(id: .init(rawValue: "laws"), title: "法规库")
    let cases = FKFilterTwoColumnModel.Category(id: .init(rawValue: "cases"), title: "案例库")
    let allSections: [FKFilterSection] = []
    let lawSections: [FKFilterSection] = [
      .init(id: .init(rawValue: "laws-1"), selectionMode: .single, items: [.init(id: .init(rawValue: "laws-item-all"), title: "全部")]),
    ]
    let caseSections: [FKFilterSection] = [
      .init(
        id: .init(rawValue: "cases-1"),
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "cases-item-all"), title: "全部"),
          .init(id: .init(rawValue: "cases-item-1"), title: "职业道德准则"),
          .init(id: .init(rawValue: "cases-item-2"), title: "行业荣辱观"),
        ]
      ),
    ]
    return FKFilterTwoColumnModel(
      categories: [all, laws, cases],
      sectionsByCategoryID: [all.id: allSections, laws.id: lawSections, cases.id: caseSections]
    )
  }

  func fetchCourseTwoColumnModel() async -> FKFilterTwoColumnModel {
    try? await Task.sleep(nanoseconds: 120_000_000)
    let a = FKFilterTwoColumnModel.Category(id: .init(rawValue: "course-a"), title: "党建引领、行业规范", isSelected: false)
    let b = FKFilterTwoColumnModel.Category(id: .init(rawValue: "course-b"), title: "法律规范")
    let c = FKFilterTwoColumnModel.Category(id: .init(rawValue: "course-c"), title: "专业技能")
    let d = FKFilterTwoColumnModel.Category(id: .init(rawValue: "course-d"), title: "证监会网校")
    let simpleAll: [FKFilterSection] = [
      .init(id: .init(rawValue: "course-all-only"), selectionMode: .single, items: [.init(id: .init(rawValue: "course-all"), title: "全部")]),
    ]
    let cswSections: [FKFilterSection] = [
      .init(
        id: .init(rawValue: "csw-1"),
        title: "政治能力提升",
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "csw-1-1"), title: "党的二十大"),
          .init(id: .init(rawValue: "csw-1-2"), title: "党务干部"),
          .init(id: .init(rawValue: "csw-1-3"), title: "一把手"),
        ]
      ),
      .init(
        id: .init(rawValue: "csw-2"),
        title: "监管业务培训",
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "csw-2-1"), title: "发行上市"),
          .init(id: .init(rawValue: "csw-2-2"), title: "新三板"),
          .init(id: .init(rawValue: "csw-2-3"), title: "机构业务"),
        ]
      ),
    ]
    return FKFilterTwoColumnModel(
      categories: [a, b, c, d],
      sectionsByCategoryID: [a.id: simpleAll, b.id: simpleAll, c.id: simpleAll, d.id: cswSections]
    )
  }

  func fetchFileTypeSections() async -> [FKFilterSection] {
    try? await Task.sleep(nanoseconds: 120_000_000)
    return [
      .init(
        id: .init(rawValue: "file-types"),
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "file-all"), title: "全部"),
          .init(id: .init(rawValue: "file-word"), title: "Word"),
          .init(id: .init(rawValue: "file-excel"), title: "Excel"),
          .init(id: .init(rawValue: "file-ppt"), title: "PPT"),
          .init(id: .init(rawValue: "file-pdf"), title: "PDF"),
        ]
      )
    ]
  }

  func fetchPlatformSections() async -> [FKFilterSection] {
    try? await Task.sleep(nanoseconds: 120_000_000)
    return [
      .init(
        id: .init(rawValue: "platform"),
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "platform-all"), title: "全部"),
          .init(id: .init(rawValue: "platform-total"), title: "总平台"),
          .init(id: .init(rawValue: "platform-local"), title: "本机构"),
          .init(id: .init(rawValue: "platform-other"), title: "其他机构"),
        ]
      )
    ]
  }

  func fetchTagsSections() async -> [FKFilterSection] {
    try? await Task.sleep(nanoseconds: 120_000_000)
    return [
      .init(
        id: .init(rawValue: "tags"),
        selectionMode: .single,
        items: [
          .init(id: .init(rawValue: "tag-all"), title: "全部"),
          .init(id: .init(rawValue: "tag-ib"), title: "投资银行"),
          .init(id: .init(rawValue: "tag-sell"), title: "证券承销与保荐"),
          .init(id: .init(rawValue: "tag-ethics"), title: "职业道德"),
        ]
      )
    ]
  }

  func fetchSortSection() async -> FKFilterSection {
    try? await Task.sleep(nanoseconds: 120_000_000)
    return .init(
      id: .init(rawValue: "sort"),
      selectionMode: .single,
      items: [
        .init(id: .init(rawValue: "sort-latest"), title: "最新"),
        .init(id: .init(rawValue: "sort-hot"), title: "最热"),
        .init(id: .init(rawValue: "sort-good"), title: "好评"),
      ]
    )
  }
}
