import Foundation

/// 会话时间的来源。决定了这个时长「有多准」，UI 必须把它显示出来。
enum SessionSource: String, Codable, CaseIterable, Sendable {
    /// App 在前台，逐秒观察路由变化，精度最高
    case live
    /// App 在后台/挂起，靠路由变更通知补记
    case routeChange
    /// 由「快捷指令 + 蓝牙自动化」在连接/断开瞬间写入，App 完全不用在运行
    case shortcut
    /// App 被杀或长时间挂起，只能按最后一次心跳向前推算
    case inferred
    /// 用户手动开始 / 手动结束
    case manual

    func title(_ language: AppLanguage) -> String {
        let key: L10n.Key
        switch self {
        case .live: key = .sourceLive
        case .routeChange: key = .sourceRouteChange
        case .shortcut: key = .sourceShortcut
        case .inferred: key = .sourceInferred
        case .manual: key = .sourceManual
        }
        return L10n.t(key, language)
    }

    /// 小于 1 视为近似值，UI 上要打标
    var confidence: Double {
        switch self {
        case .live: 1.0
        case .shortcut: 0.98
        case .routeChange: 0.92
        case .manual: 0.9
        case .inferred: 0.55
        }
    }

    var isEstimated: Bool { confidence < 0.8 }

    /// 多个来源描述同一次连接时，保留精度更高的那个
    var priority: Int {
        switch self {
        case .shortcut: 5
        case .live: 4
        case .routeChange: 3
        case .manual: 2
        case .inferred: 1
        }
    }
}
