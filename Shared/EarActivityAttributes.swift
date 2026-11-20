import Foundation
import ActivityKit

/// Live Activity 的静态属性：整场连接不变的部分。
/// 放在主 App 与 Widget 共享的目录里，两边都能编译。
struct EarActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startedAt: Date
        /// 本次开始之前，今天已经听了多久
        var todayTotalBefore: TimeInterval
        var goalSeconds: TimeInterval
        var isEstimated: Bool

        var todayProjected: TimeInterval {
            todayTotalBefore + max(0, Date.now.timeIntervalSince(startedAt))
        }
    }

    var deviceName: String
    var startedAt: Date
}
