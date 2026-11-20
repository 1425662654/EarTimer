import Foundation
import Observation

/// 设置项。内存里是 `@Observable` 的存储属性，磁盘上落在 UserDefaults（App Group）。
///
/// 为什么不用 `didSet`：`@Observable` 宏会把存储属性重写成带观察的存取器，
/// 与 `didSet` / `willSet` 冲突。这里改成「存储属性 + 显式 `persist()`」，
/// 视图侧用 `onChange(of: persistSignature)` 触发落盘 —— 每次改动都会写，代价可忽略。
@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    // MARK: - 存储属性（观察 + 绑定都靠它们）

    var isTrackingEnabled: Bool
    var includeWired: Bool
    var inferWhileSuspended: Bool
    var liveActivitiesEnabled: Bool
    var notifyOnGoal: Bool

    /// 连续佩戴提醒（分钟），0 = 关闭
    var continuousWearMinutes: Int
    /// 每日听音预算（分钟），0 = 不设目标
    var dailyBudgetMinutes: Int
    /// 摘下后多久算结束（分钟）
    var idleGapMinutes: Int
    var accentStyle: Int

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let prefix = "et."

    private enum Key: String {
        case tracking, wired, infer, liveActivity, goalNotify, wear, budget, gap, accent
    }

    init(defaults: UserDefaults = SharedDefaults.suite) {
        self.defaults = defaults
        isTrackingEnabled = defaults.object(forKey: prefix + Key.tracking.rawValue) as? Bool ?? true
        includeWired = defaults.object(forKey: prefix + Key.wired.rawValue) as? Bool ?? false
        inferWhileSuspended = defaults.object(forKey: prefix + Key.infer.rawValue) as? Bool ?? true
        liveActivitiesEnabled = defaults.object(forKey: prefix + Key.liveActivity.rawValue) as? Bool ?? true
        notifyOnGoal = defaults.object(forKey: prefix + Key.goalNotify.rawValue) as? Bool ?? false
        continuousWearMinutes = defaults.object(forKey: prefix + Key.wear.rawValue) as? Int ?? 60
        dailyBudgetMinutes = defaults.object(forKey: prefix + Key.budget.rawValue) as? Int ?? 300
        idleGapMinutes = defaults.object(forKey: prefix + Key.gap.rawValue) as? Int ?? 3
        accentStyle = defaults.object(forKey: prefix + Key.accent.rawValue) as? Int ?? 0
    }

    // MARK: - 落盘

    /// 全部设置的快照串，用于视图侧判断「有变化才写」
    var persistSignature: String {
        [
            String(isTrackingEnabled), String(includeWired), String(inferWhileSuspended),
            String(liveActivitiesEnabled), String(notifyOnGoal),
            String(continuousWearMinutes), String(dailyBudgetMinutes),
            String(idleGapMinutes), String(accentStyle)
        ].joined(separator: "|")
    }

    func persist() {
        defaults.set(isTrackingEnabled, forKey: prefix + Key.tracking.rawValue)
        defaults.set(includeWired, forKey: prefix + Key.wired.rawValue)
        defaults.set(inferWhileSuspended, forKey: prefix + Key.infer.rawValue)
        defaults.set(liveActivitiesEnabled, forKey: prefix + Key.liveActivity.rawValue)
        defaults.set(notifyOnGoal, forKey: prefix + Key.goalNotify.rawValue)
        defaults.set(continuousWearMinutes, forKey: prefix + Key.wear.rawValue)
        defaults.set(dailyBudgetMinutes, forKey: prefix + Key.budget.rawValue)
        defaults.set(idleGapMinutes, forKey: prefix + Key.gap.rawValue)
        defaults.set(accentStyle, forKey: prefix + Key.accent.rawValue)
    }

    // MARK: - 派生

    var dailyBudget: TimeInterval { TimeInterval(dailyBudgetMinutes) * 60 }
    var continuousWearThreshold: TimeInterval { TimeInterval(continuousWearMinutes) * 60 }
    var idleGap: TimeInterval { TimeInterval(idleGapMinutes) * 60 }

    // MARK: - 跨进程时间戳
    // 这几项不进观察系统：它们由快捷指令 / 引擎写，视图不需要据此重绘，
    // 但必须**立刻**落到 App Group，否则跨进程看不到。

    var pendingShortcutStart: Date? {
        get {
            let t = defaults.double(forKey: SharedDefaults.Keys.shortcutStart)
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: SharedDefaults.Keys.shortcutStart)
        }
    }

    var pendingShortcutStop: Date? {
        get {
            let t = defaults.double(forKey: SharedDefaults.Keys.shortcutStop)
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: SharedDefaults.Keys.shortcutStop)
        }
    }

    /// 心跳：最后一次「我确信这一刻耳机还连着」的时刻
    var lastHeartbeat: Date? {
        get {
            let t = defaults.double(forKey: SharedDefaults.Keys.heartbeat)
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set {
            defaults.set(newValue?.timeIntervalSince1970 ?? 0, forKey: SharedDefaults.Keys.heartbeat)
        }
    }

    /// 消费并清空断开标记，避免同一次断开被重复结算
    func consumeStopMark() -> Date? {
        let value = pendingShortcutStop
        pendingShortcutStop = nil
        return value
    }
}
