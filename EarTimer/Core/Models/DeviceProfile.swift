import Foundation
import SwiftData

/// 一只耳机的档案：用来做「按设备」统计、配色、置顶、单设备预算。
@Model
final class DeviceProfile {
    @Attribute(.unique) var key: String
    /// 最近一次看到的名称（设备改名会更新）
    var name: String
    var channelRaw: String
    var firstSeenAt: Date
    var lastSeenAt: Date
    /// 0...5，决定 UI 里这只耳机的点缀色
    var accentIndex: Int
    var isFavorite: Bool
    /// 单设备每日预算（秒），0 表示跟随全局
    var dailyBudgetSeconds: Int

    init(
        key: String,
        name: String,
        channel: AudioChannel = .music,
        firstSeenAt: Date = .now,
        lastSeenAt: Date = .now,
        accentIndex: Int = 0,
        isFavorite: Bool = false,
        dailyBudgetSeconds: Int = 0
    ) {
        self.key = key
        self.name = name
        self.channelRaw = channel.rawValue
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.accentIndex = accentIndex
        self.isFavorite = isFavorite
        self.dailyBudgetSeconds = dailyBudgetSeconds
    }

    var channel: AudioChannel {
        get { AudioChannel(rawValue: channelRaw) ?? .other }
        set { channelRaw = newValue.rawValue }
    }
}
