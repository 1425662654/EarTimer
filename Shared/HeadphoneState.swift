import Foundation

/// 当前耳机连接状态。值类型，方便跨 Widget / Live Activity / 主 App 传递。
struct HeadphoneState: Codable, Equatable, Sendable {
    var isConnected: Bool
    var deviceName: String
    var deviceKey: String
    var channel: AudioChannel
    /// 本次开始的时刻；未连接时为 nil
    var sessionStartedAt: Date?
    /// 今天累计（不含进行中的部分，进行中由 UI 加上去）
    var todayAccumulated: TimeInterval
    /// 本次会话的来源精度
    var source: SessionSource

    static let disconnected = HeadphoneState(
        isConnected: false,
        deviceName: "",
        deviceKey: "",
        channel: .other,
        sessionStartedAt: nil,
        todayAccumulated: 0,
        source: .live
    )

    func elapsed(now: Date = .now) -> TimeInterval {
        guard let start = sessionStartedAt, isConnected else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    /// 今天的总时长 = 已完成的 + 进行中的
    func todayTotal(now: Date = .now) -> TimeInterval {
        todayAccumulated + elapsed(now: now)
    }
}
