import Foundation
import OSLog

/// App Group 常量与跨进程共享的小数据。
/// 只共享「当前状态 + 聚合数」，历史记录仍然只在 SwiftData 里，避免双写。
enum SharedDefaults {
    static let appGroup = "group.com.yg.eartimer"

    enum Keys {
        static let currentState = "et.shared.state"
        static let shortcutStart = "et.pending.shortcutStart"
        static let shortcutStop = "et.pending.shortcutStop"
        static let heartbeat = "et.pending.heartbeat"
        static let todayTotal = "et.shared.todayTotal"
        static let goalSeconds = "et.shared.goalSeconds"
        static let streak = "et.shared.streak"
        static let pendingDeviceName = "et.pending.deviceName"
        static let guideCompleted = "et.guide.completed"
        static let showSetupGuide = "et.pending.showSetupGuide"
        static let language = "et.settings.language"
    }

    /// 扩展/Intents 里 App Group 可能拿不到（未签名调试），回退到 standard 保证不崩
    static var suite: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    private static let log = Logger(subsystem: "com.yg.eartimer", category: "Shared")

    static func writeState(_ state: HeadphoneState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        let d = suite
        d.set(data, forKey: Keys.currentState)
        d.set(state.todayTotal(), forKey: Keys.todayTotal)
    }

    static func readState() -> HeadphoneState {
        guard let data = suite.data(forKey: Keys.currentState) else { return .disconnected }
        guard let state = try? JSONDecoder().decode(HeadphoneState.self, from: data) else {
            log.error("state decode failed")
            return .disconnected
        }
        return state
    }

    static func clearState() {
        writeState(.disconnected)
    }
}
