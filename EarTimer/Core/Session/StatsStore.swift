import Foundation
import SwiftData
import Observation

/// 所有统计查询的入口。纯函数式输入 → 结构体，方便单测与预览。
@MainActor
@Observable
final class StatsStore {
    private(set) var snapshot: StatsSnapshot = .empty
    private(set) var dailyTotals: [DailyTotal] = []
    private(set) var deviceTotals: [DeviceTotal] = []
    private(set) var hourBuckets: [HourBucket] = []
    private(set) var heatmap: [DailyTotal] = []

    private var context: ModelContext?

    init(context: ModelContext? = nil) {
        self.context = context
    }

    func attach(context: ModelContext) {
        self.context = context
    }

    func refresh(state: HeadphoneState? = nil) {
        guard let context else { return }
        let now = Date.now
        let today = DayBounds.interval(ofDayContaining: now)
        let week = DayBounds.interval(ofWeekContaining: now)

        let all = (try? context.fetch(FetchDescriptor<SessionRecord>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)]))) ?? []

        let liveState = state ?? SessionEngine.shared.state
        let todaySeconds = all.reduce(0.0) { $0 + $1.overlap(with: today) }
        let weekSeconds = all.reduce(0.0) { $0 + $1.overlap(with: week) }
        let allSeconds = all.reduce(0.0) { $0 + $1.duration(now: now) }

        let closed = all.filter { !$0.isOpen }
        let longest = closed.map { $0.duration(now: now) }.max() ?? 0

        snapshot = StatsSnapshot(
            state: liveState,
            todayTotal: todaySeconds,
            weekTotal: weekSeconds,
            allTimeTotal: allSeconds,
            sessionCount: closed.count,
            longestSession: longest,
            currentStreakDays: streak(from: all, now: now)
        )

        // 近 7 天
        dailyTotals = DayBounds.recentDays(7, now: now).map { day in
            let interval = DayBounds.interval(ofDayContaining: day, calendar: .app)
            let seconds = all.reduce(0.0) { $0 + $1.overlap(with: interval) }
            return DailyTotal(day: interval.start, seconds: seconds)
        }

        // 近 30 天热力
        heatmap = DayBounds.recentDays(30, now: now).map { day in
            let interval = DayBounds.interval(ofDayContaining: day, calendar: .app)
            let seconds = all.reduce(0.0) { $0 + $1.overlap(with: interval) }
            return DailyTotal(day: interval.start, seconds: seconds)
        }

        // 按设备（近 30 天）
        var byDevice: [String: (String, TimeInterval)] = [:]
        let window = DateInterval(
            start: DayBounds.startOfDay(Calendar.app.date(byAdding: .day, value: -29, to: now) ?? now),
            end: now
        )
        for row in all {
            let seconds = row.overlap(with: window)
            guard seconds > 0 else { continue }
            let existing = byDevice[row.deviceKey]
            byDevice[row.deviceKey] = (row.deviceName, (existing?.1 ?? 0) + seconds)
        }
        deviceTotals = byDevice
            .map { DeviceTotal(key: $0.key, name: $0.value.0, seconds: $0.value.1) }
            .sorted { $0.seconds > $1.seconds }

        // 时段分布（全量，24 桶）
        var buckets = Array(repeating: 0.0, count: 24)
        let cal = Calendar.app
        for row in all {
            let hours = hourSplit(row, calendar: cal, now: now)
            for (h, s) in hours { buckets[h] += s }
        }
        hourBuckets = buckets.enumerated().map { HourBucket(hour: $0.offset, seconds: $0.element) }

        // 连续天数
        if snapshot.currentStreakDays > 0 {
            SharedDefaults.suite.set(snapshot.currentStreakDays, forKey: SharedDefaults.Keys.streak)
        }
    }

    /// 会话跨小时拆分
    private func hourSplit(_ row: SessionRecord, calendar: Calendar, now: Date) -> [(Int, TimeInterval)] {
        var result: [(Int, TimeInterval)] = []
        var cursor = row.startedAt
        let end = row.endedAt ?? now
        var guardCount = 0
        while cursor < end && guardCount < 26 {
            let hour = calendar.component(.hour, from: cursor)
            let hourInterval = calendar.dateInterval(of: .hour, for: cursor)
            let segmentEnd = min(hourInterval?.end ?? end, end)
            result.append((hour, segmentEnd.timeIntervalSince(cursor)))
            cursor = segmentEnd
            guardCount += 1
        }
        return result
    }

    /// 连续天数：从今天往前数；今天还没戴就从昨天数，避免早上打开 App 时归零
    private func streak(from rows: [SessionRecord], now: Date) -> Int {
        let cal = Calendar.app
        let daySet = Set(rows.map { cal.startOfDay(for: $0.startedAt) })
        var day = DayBounds.startOfDay(now)

        if !daySet.contains(day) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var count = 0
        while daySet.contains(day) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    func rows(for day: Date) -> [SessionRecord] {
        guard let context else { return [] }
        let interval = DayBounds.interval(ofDayContaining: day)
        let start = interval.start
        let end = interval.end
        // 只按 startedAt 过滤会漏掉「昨夜连到今早」的会话，所以放宽一个窗口再精确过滤
        let wideStart = Calendar.app.date(byAdding: .hour, value: -24, to: start) ?? start
        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.startedAt < end && $0.startedAt >= wideStart },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return ((try? context.fetch(descriptor)) ?? [])
            .filter { $0.overlap(with: interval) > 0 }
    }
}
