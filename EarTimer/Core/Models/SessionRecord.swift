import Foundation
import SwiftData

/// 一次「耳机连上 → 断开」的完整记录。
@Model
final class SessionRecord {
    /// 稳定业务主键。SwiftData 自身的 `persistentModelID` 会随迁移变化，
    /// 快捷指令 / Live Activity / 通知之间互相引用时用这个。
    @Attribute(.unique) var sessionID: UUID
    /// 设备标识（规范化后的端口名，见 AudioOutputDevice.key）
    var deviceKey: String
    /// 展示用设备名，断开时快照，之后改设备名也不影响历史
    var deviceName: String

    var startedAt: Date
    /// nil 表示「正在进行中」
    var endedAt: Date?

    var channelRaw: String
    var sourceRaw: String
    /// 这次连接里是否发生过通话（听歌途中来电，路由会切到 HFP）
    var hadCall: Bool
    /// App 被杀/挂起导致无法确定精确断开时间
    var isEstimated: Bool
    /// 用户备注
    var note: String?

    /// 断开前的平均系统音量 0...1，用于听力负荷估算
    var averageVolume: Double

    init(
        sessionID: UUID = UUID(),
        deviceKey: String,
        deviceName: String,
        startedAt: Date,
        endedAt: Date? = nil,
        channel: AudioChannel = .music,
        source: SessionSource = .live,
        hadCall: Bool = false,
        isEstimated: Bool = false,
        note: String? = nil,
        averageVolume: Double = 0
    ) {
        self.sessionID = sessionID
        self.deviceKey = deviceKey
        self.deviceName = deviceName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.channelRaw = channel.rawValue
        self.sourceRaw = source.rawValue
        self.hadCall = hadCall
        self.isEstimated = isEstimated
        self.note = note
        self.averageVolume = averageVolume
    }

    var channel: AudioChannel {
        get { AudioChannel(rawValue: channelRaw) ?? .other }
        set { channelRaw = newValue.rawValue }
    }

    var source: SessionSource {
        get { SessionSource(rawValue: sourceRaw) ?? .live }
        set { sourceRaw = newValue.rawValue }
    }

    var isOpen: Bool { endedAt == nil }

    func duration(now: Date = .now) -> TimeInterval {
        max(0, (endedAt ?? now).timeIntervalSince(startedAt))
    }

    /// 与某个时间区间的重叠时长。跨零点的会话会被精确切分。
    /// 进行中的会话按「此刻」结算，不能按区间末尾算，否则会把未来也计进去。
    func overlap(with interval: DateInterval, now: Date = .now) -> TimeInterval {
        let end = endedAt ?? min(now, interval.end)
        let lower = max(startedAt, interval.start)
        let upper = min(end, interval.end)
        return max(0, upper.timeIntervalSince(lower))
    }
}
