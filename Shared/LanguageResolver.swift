import Foundation

/// 语言解析的纯函数版本。放在 Shared，因为主 App、Widget、Intent 三个进程都要用，
/// 而 `LanguageStore` 是主 App 专属的 @Observable 单例，扩展里拿不到。
enum LanguageResolver {
    /// 从 App Group 读当前语言；没有存储值时默认英文
    static func current(_ defaults: UserDefaults = SharedDefaults.suite) -> AppLanguage {
        let raw = defaults.string(forKey: SharedDefaults.Keys.language)
        return AppLanguage(rawValue: raw ?? "") ?? .english
    }

    static func text(_ key: L10n.Key, defaults: UserDefaults = SharedDefaults.suite) -> String {
        L10n.t(key, current(defaults))
    }
}
