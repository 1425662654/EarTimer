import Foundation

/// App 界面语言。用户可在设置里切换，默认英文。
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case chinese = "zh"

    var id: String { rawValue }

    /// 切换器上显示的名字，两种语言下都用自己的母语写，避免用户看不懂
    var nativeName: String {
        switch self {
        case .english: "English"
        case .chinese: "中文"
        }
    }

    /// 极短标签，用于右上角小胶囊
    var shortName: String {
        switch self {
        case .english: "EN"
        case .chinese: "中"
        }
    }

    /// 给了语言就按它，没给就跟随全局设置
    static func resolve(_ language: AppLanguage) -> AppLanguage { language }
}
