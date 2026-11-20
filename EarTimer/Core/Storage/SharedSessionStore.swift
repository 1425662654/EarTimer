import Foundation
import SwiftData
import os

/// 跨进程共享的数据存储。
///
/// 为什么需要它：快捷指令自动化触发 AppIntent 时，系统可能在**主 App 完全没运行**的
/// 情况下把 App 拉起来跑 intent —— 此时 SwiftUI 的 `App` 结构体不一定被完整初始化，
/// 主 App 里那个 `ModelContainer` 也就不存在。
///
/// 所以 intent **不能**依赖 App 单例，必须自己建一份指向同一个 App Group 数据库的容器。
/// 这是 App Intents 的硬性约束：「intent runs OFF your app's process, on the system's
/// schedule, possibly while the app is terminated — so it must construct its own store access」。
enum SharedSessionStore {

    static let log = Logger(subsystem: "com.yg.eartimer", category: "SharedStore")

    /// 指向 App Group 里的同一个 SQLite 文件。
    /// 每次调用都新建，是因为多进程访问同一个 ModelContainer 实例本身不安全，
    /// SwiftData 会在文件层做锁；建容器本身很便宜。
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([SessionRecord.self, DeviceProfile.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(SharedDefaults.appGroup),
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: config)
    }

    // MARK: - 供 AppIntent 调用（不需要 App 在运行）

    /// 开始一次会话。若已有未结束的会话则先按此刻收尾，避免脏数据。
    /// - Returns: 是否真的新建了记录
    @discardableResult
    static func begin(
        deviceName: String?,
        at date: Date,
        source: SessionSource = .shortcut,
        language: AppLanguage = .english
    ) -> Bool {
        do {
            let container = try makeContainer()
            let context = ModelContext(container)

            if let existing = openRecord(in: context) {
                // 同一次连接被重复触发：只更新时间戳，不新建
                existing.startedAt = min(existing.startedAt, date)
                existing.source = source
                if let deviceName, !deviceName.isEmpty {
                    existing.deviceName = deviceName
                }
                try context.save()
                log.info("begin: reused open session")
                return false
            }

            let name = (deviceName?.isEmpty == false ? deviceName! : L10n.t(.defaultHeadphoneName, language))
            let record = SessionRecord(
                deviceKey: "bt://\(name.lowercased())",
                deviceName: name,
                startedAt: date,
                channel: .music,
                source: source
            )
            context.insert(record)
            upsertProfile(name: name, key: record.deviceKey, in: context)
            try context.save()
            log.info("begin: created session at \(date, privacy: .public)")
            return true
        } catch {
            log.error("begin failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// 结束当前未结束的会话。
    @discardableResult
    static func end(at date: Date, source: SessionSource = .shortcut) -> Bool {
        do {
            let container = try makeContainer()
            let context = ModelContext(container)
            guard let record = openRecord(in: context) else {
                log.info("end: no open session")
                return false
            }
            record.endedAt = max(date, record.startedAt)
            record.isEstimated = false
            record.source = source
            try context.save()
            log.info("end: closed after \(record.duration(), privacy: .public)s")
            return true
        } catch {
            log.error("end failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// 今天已完成的累计时长（秒），供 intent / 小组件读取
    static func todayTotal(now: Date = .now) -> TimeInterval {
        do {
            let container = try makeContainer()
            let context = ModelContext(container)
            let day = DayBounds.interval(ofDayContaining: now)
            let start = day.start
            let end = day.end
            let descriptor = FetchDescriptor<SessionRecord>(
                predicate: #Predicate { $0.startedAt >= start && $0.startedAt < end }
            )
            let rows = try context.fetch(descriptor)
            return rows.reduce(0.0) { $0 + $1.overlap(with: day, now: now) }
        } catch {
            log.error("todayTotal failed: \(error.localizedDescription, privacy: .public)")
            return 0
        }
    }

    // MARK: - 内部

    private static func openRecord(in context: ModelContext) -> SessionRecord? {
        var descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private static func upsertProfile(name: String, key: String, in context: ModelContext) {
        var descriptor = FetchDescriptor<DeviceProfile>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            existing.name = name
            existing.lastSeenAt = .now
        } else {
            let count = (try? context.fetchCount(FetchDescriptor<DeviceProfile>())) ?? 0
            context.insert(DeviceProfile(key: key, name: name, accentIndex: count % 6))
        }
    }
}
