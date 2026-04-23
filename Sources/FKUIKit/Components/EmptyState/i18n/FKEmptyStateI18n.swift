import Foundation

/// Supported locale identifiers for built-in EmptyState copy.
///
/// The enum is intentionally conservative; callers can still provide any custom locale
/// by injecting their own translator implementation.
///
/// - Note: Built-in messages include an Arabic sample (`ar`) to exercise RTL layout paths.
public enum FKEmptyStateLocale: String, CaseIterable, Equatable, Sendable {
  case en
  case zhCN = "zh-CN"
  case ja
  case es
  case ar
}

/// Lightweight key wrapper to prevent accidental free-form string misuse.
///
/// Key conventions used by the built-in dictionary:
/// - Titles: `empty.<segment>.title`
/// - Descriptions: `empty.<segment>.description`
/// - Action labels: `empty.action.<name>`
///
/// Where `<segment>` is produced by `FKEmptyStateFactory.keySegment(for:)`.
public struct FKEmptyStateI18nKey: Hashable, Sendable {
  public var rawValue: String
  public init(_ rawValue: String) { self.rawValue = rawValue }
}

/// Minimal translation protocol used by the factory and core module.
///
/// Keeping it small makes it easy to bridge existing localization stacks
/// (e.g. JSON bundles, remote dictionaries, or feature-flagged copy services).
public protocol FKEmptyStateTranslating: Sendable {
  func translate(
    _ key: FKEmptyStateI18nKey,
    locale: FKEmptyStateLocale,
    variables: [String: String]
  ) -> String
}

public struct FKEmptyStateDictionaryTranslator: FKEmptyStateTranslating {
  public typealias Dictionary = [FKEmptyStateLocale: [FKEmptyStateI18nKey: String]]

  public var dictionary: Dictionary
  public var fallbackLocale: FKEmptyStateLocale

  public init(dictionary: Dictionary, fallbackLocale: FKEmptyStateLocale = .en) {
    self.dictionary = dictionary
    self.fallbackLocale = fallbackLocale
  }

  public func translate(
    _ key: FKEmptyStateI18nKey,
    locale: FKEmptyStateLocale,
    variables: [String: String]
  ) -> String {
    // Fallback chain favors explicit locale first, then fallback locale, then key echo.
    // Echoing the key makes missing translations visible in QA instead of silently blank text.
    //
    // Trade-off: key echo is noisy but intentional; open-source users typically prefer
    // visibility over silent failure during integration.
    let template =
      dictionary[locale]?[key]
      ?? dictionary[fallbackLocale]?[key]
      ?? key.rawValue
    return FKEmptyStateMessageFormat.interpolate(template: template, variables: variables)
  }
}

public enum FKEmptyStateMessageFormat {
  /// Replaces `{token}` placeholders with values from `variables`.
  ///
  /// Unknown placeholders are intentionally preserved to surface integration mistakes.
  ///
  /// - Design choice: This intentionally does not implement pluralization or ICU formatting to
  ///   keep the module lightweight. If your product needs advanced formatting, wrap it behind
  ///   `FKEmptyStateTranslating`.
  public static func interpolate(template: String, variables: [String: String]) -> String {
    guard template.contains("{"), !variables.isEmpty else { return template }
    var result = template
    for (k, v) in variables {
      result = result.replacingOccurrences(of: "{\(k)}", with: v)
    }
    return result
  }
}

public enum FKEmptyStateBuiltInMessages {
  public static let `default` = FKEmptyStateDictionaryTranslator(
    dictionary: [
      .en: [
        FKEmptyStateI18nKey("empty.empty.title"): "Nothing here yet",
        FKEmptyStateI18nKey("empty.empty.description"): "There is no data to display.",
        FKEmptyStateI18nKey("empty.noResults.title"): "No results",
        FKEmptyStateI18nKey("empty.noResults.description"): "No matches for “{query}”. Try a different keyword.",
        FKEmptyStateI18nKey("empty.error.title"): "Something went wrong",
        FKEmptyStateI18nKey("empty.error.description"): "We couldn’t load the content. Please try again.",
        FKEmptyStateI18nKey("empty.offline.title"): "You’re offline",
        FKEmptyStateI18nKey("empty.offline.description"): "Check your connection and try again.",
        FKEmptyStateI18nKey("empty.permissionDenied.title"): "Access denied",
        FKEmptyStateI18nKey("empty.permissionDenied.description"): "You don’t have permission to view this content.",
        FKEmptyStateI18nKey("empty.notFound.title"): "Not found",
        FKEmptyStateI18nKey("empty.notFound.description"): "The requested resource doesn’t exist.",
        FKEmptyStateI18nKey("empty.maintenance.title"): "Under maintenance",
        FKEmptyStateI18nKey("empty.maintenance.description"): "We’re performing scheduled maintenance. Please try again later.",
        FKEmptyStateI18nKey("empty.loading.title"): "Loading",
        FKEmptyStateI18nKey("empty.loading.description"): "Please wait…",
        FKEmptyStateI18nKey("empty.newUser.title"): "Welcome",
        FKEmptyStateI18nKey("empty.newUser.description"): "Let’s get you started.",
        FKEmptyStateI18nKey("empty.action.retry"): "Retry",
        FKEmptyStateI18nKey("empty.action.refresh"): "Refresh",
        FKEmptyStateI18nKey("empty.action.clearFilters"): "Clear filters",
        FKEmptyStateI18nKey("empty.action.create"): "Create",
        FKEmptyStateI18nKey("empty.action.contactAdmin"): "Contact admin",
        FKEmptyStateI18nKey("empty.action.learnMore"): "Learn more",
      ],
      .zhCN: [
        FKEmptyStateI18nKey("empty.empty.title"): "暂无内容",
        FKEmptyStateI18nKey("empty.empty.description"): "这里还没有数据可展示。",
        FKEmptyStateI18nKey("empty.noResults.title"): "未找到结果",
        FKEmptyStateI18nKey("empty.noResults.description"): "没有与“{query}”匹配的结果，请尝试其他关键词。",
        FKEmptyStateI18nKey("empty.error.title"): "加载失败",
        FKEmptyStateI18nKey("empty.error.description"): "暂时无法加载内容，请稍后重试。",
        FKEmptyStateI18nKey("empty.offline.title"): "网络不可用",
        FKEmptyStateI18nKey("empty.offline.description"): "请检查网络连接后重试。",
        FKEmptyStateI18nKey("empty.permissionDenied.title"): "无权限访问",
        FKEmptyStateI18nKey("empty.permissionDenied.description"): "你没有权限查看此内容。",
        FKEmptyStateI18nKey("empty.notFound.title"): "未找到",
        FKEmptyStateI18nKey("empty.notFound.description"): "请求的资源不存在。",
        FKEmptyStateI18nKey("empty.maintenance.title"): "维护中",
        FKEmptyStateI18nKey("empty.maintenance.description"): "服务正在维护，请稍后再试。",
        FKEmptyStateI18nKey("empty.loading.title"): "加载中",
        FKEmptyStateI18nKey("empty.loading.description"): "请稍候…",
        FKEmptyStateI18nKey("empty.newUser.title"): "欢迎使用",
        FKEmptyStateI18nKey("empty.newUser.description"): "我们来快速开始吧。",
        FKEmptyStateI18nKey("empty.action.retry"): "重试",
        FKEmptyStateI18nKey("empty.action.refresh"): "刷新",
        FKEmptyStateI18nKey("empty.action.clearFilters"): "清空筛选",
        FKEmptyStateI18nKey("empty.action.create"): "创建",
        FKEmptyStateI18nKey("empty.action.contactAdmin"): "联系管理员",
        FKEmptyStateI18nKey("empty.action.learnMore"): "了解更多",
      ],
      .ar: [
        FKEmptyStateI18nKey("empty.noResults.title"): "لا توجد نتائج",
        FKEmptyStateI18nKey("empty.noResults.description"): "لا توجد نتائج لـ “{query}”. جرّب كلمة مختلفة.",
        FKEmptyStateI18nKey("empty.action.retry"): "إعادة المحاولة",
      ],
    ]
  )
}
