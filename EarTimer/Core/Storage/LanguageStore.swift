import SwiftUI
import Observation

/// 语言设置的唯一来源。放在环境里，视图用 `@Environment(LanguageStore.self)` 读。
///
/// 关键设计：**首页标题固定为 `EarTimer`，不参与本地化**。
/// 因为它是产品名，翻译成中文只会削弱识别度。其余所有文案都跟随当前语言。
@MainActor
@Observable
final class LanguageStore {
    static let shared = LanguageStore()

    var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            SharedDefaults.suite.set(language.rawValue, forKey: SharedDefaults.Keys.language)
        }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = SharedDefaults.suite) {
        self.defaults = defaults
        self.language = LanguageResolver.current(defaults)
    }

    /// 便捷取词
    func t(_ key: L10n.Key) -> String {
        L10n.t(key, language)
    }
}
