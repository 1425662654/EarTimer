import Foundation

enum DayBounds {
    static func startOfDay(_ date: Date, calendar: Calendar = .app) -> Date {
        calendar.startOfDay(for: date)
    }

    static func interval(ofDayContaining date: Date, calendar: Calendar = .app) -> DateInterval {
        calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 86_400)
    }

    static func interval(ofWeekContaining date: Date, calendar: Calendar = .app) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 604_800)
    }

    /// 最近 n 天（含今天），按时间正序
    static func recentDays(_ count: Int, now: Date = .now, calendar: Calendar = .app) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0..<max(0, count)).reversed().map {
            calendar.date(byAdding: .day, value: -$0, to: today) ?? today
        }
    }
}

/// 分析结果都是纯值类型，方便缓存、单元测试、preview 注入
struct DailyTotal: Identifiable, Hashable, Sendable {
    var day: Date
    var seconds: TimeInterval
    var id: Date { day }
}

struct DeviceTotal: Identifiable, Hashable, Sendable {
    var key: String
    var name: String
    var seconds: TimeInterval
    var id: String { key }
}

struct HourBucket: Identifiable, Hashable, Sendable {
    var hour: Int
    var seconds: TimeInterval
    var id: Int { hour }
}

struct StatsSnapshot: Equatable, Sendable {
    var state: HeadphoneState = .disconnected
    var todayTotal: TimeInterval = 0
    var weekTotal: TimeInterval = 0
    var allTimeTotal: TimeInterval = 0
    var sessionCount: Int = 0
    var longestSession: TimeInterval = 0
    var currentStreakDays: Int = 0

    static let empty = StatsSnapshot()
}
