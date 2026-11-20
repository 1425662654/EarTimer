import Foundation
import SwiftData
import Observation
import os

/// 会话引擎：把「音频路由变化」翻译成「一条可统计的记录」。
///
/// 它是 App 里唯一写 SessionRecord 的地方 —— 所有奇怪的时序问题
/// （重连、通道切换、被杀、心跳断裂）都收口在这里，UI 只读。
@MainActor
@Observable
final class SessionEngine {
    static let shared = SessionEngine()

    private(set) var state: HeadphoneState = .disconnected
    private(set) var openSession: SessionRecord?
    private(set) var lastError: String?

    private var context: ModelContext?
    private var observer: AudioRouteObserver?
    private let settings = SettingsStore.shared
    private let log = Logger(subsystem: "com.yg.eartimer", category: "Engine")

    private init() {}

    func configure(context: ModelContext, observer: AudioRouteObserver) {
        self.context = context
        if self.observer == nil {
            self.observer = observer
            observer.onChange = { [weak self] previous, next in
                self?.handleRouteChange(from: previous, to: next)
            }
        }
    }

    // MARK: - 生命周期

    func start() {
        guard settings.isTrackingEnabled else { return }
        guard let observer else { return }
        observer.activateSession()
        observer.start()
        observer.refresh(notify: false)
        reconcile(observer: observer)
    }

    func stop() {
        observer?.stop()
    }

    /// 每次回到前台：用当前真值校正一次，并清掉 App 被杀期间留下的「僵尸会话」
    func syncOnForeground(observer: AudioRouteObserver) {
        guard settings.isTrackingEnabled else { return }
        observer.activateSession()
        observer.refresh(notify: false)
        reconcile(observer: observer)
        heartbeat()
    }

    // MARK: - 路由变化

    private func handleRouteChange(from previous: AudioOutputDevice?, to next: AudioOutputDevice?) {
        let wasHeadphone = previous?.channel.isHeadphone == true
        let isHeadphone = next?.channel.isHeadphone == true

        if !wasHeadphone, isHeadphone, let next {
            begin(with: next)
        } else if wasHeadphone, !isHeadphone {
            end(at: .now, estimated: false, note: nil)
        } else if wasHeadphone, isHeadphone, let next {
            if previous?.key != next.key {
                // 换了另一只耳机：严格说是两次连接
                end(at: .now, estimated: false, note: nil)
                begin(with: next)
            } else if previous?.channel != next.channel, next.channel == .call {
                // 同一只耳机 A2DP → HFP（来电）：算通话，不拆会话
                openSession?.hadCall = true
                openSession?.channel = .call
                save()
            }
        } else {
            return
        }
        heartbeat()
    }

    // MARK: - 开始 / 结束

    private func begin(with device: AudioOutputDevice) {
        // 去重：App 被唤起时可能已经有一条 open 记录
        if let open = fetchOpenSession(), open.deviceKey == device.key {
            openSession = open
            publishState(startedAt: open.startedAt, device: device)
            return
        }
        if let open = fetchOpenSession() {
            // 旧会话没有正确关闭，先按当前时刻收尾
            close(open, at: .now, estimated: true)
        }

        let effectiveStart = settings.pendingShortcutStart.map { min($0, .now) } ?? .now
        let source: SessionSource = settings.pendingShortcutStart == nil ? .live : .shortcut
        settings.pendingShortcutStart = nil

        let record = SessionRecord(
            deviceKey: device.key,
            deviceName: device.name,
            startedAt: effectiveStart,
            channel: device.channel,
            source: source,
            averageVolume: observer?.systemVolume() ?? 0
        )
        context?.insert(record)
        upsertProfile(for: device)
        save()
        openSession = record
        publishState(startedAt: record.startedAt, device: device)
        ReminderScheduler.shared.scheduleForSession(
            startedAt: record.startedAt,
            todayAccumulated: state.todayAccumulated
        )
    }

    func end(at date: Date = .now, estimated: Bool = false, note: String? = nil) {
        guard let open = openSession ?? fetchOpenSession() else {
            publishState(startedAt: nil, device: nil)
            return
        }
        // state.todayAccumulated 来自 todayAccumulated(excluding: openSession)，
        // 本身就已经排除了本次会话 —— 这里不能再减一次 duration，
        // 否则「本次开始前的累计」会被算成负数，已超支的用户每次新会话结束都会重复收到达成通知。
        let before = state.todayAccumulated
        let budget = settings.dailyBudget

        close(open, at: date, estimated: estimated)
        openSession = nil
        publishState(startedAt: nil, device: nil)
        LiveActivityController.shared.end(finalDuration: open.duration(now: date))
        ReminderScheduler.shared.cancelSessionReminders()

        // 跨过预算线才提醒一次；已超支时不重复打扰
        if settings.notifyOnGoal, budget > 0, before < budget, state.todayAccumulated >= budget {
            ReminderScheduler.shared.notifyGoalReached(total: state.todayAccumulated)
        }
    }

    func toggleManually() {
        if let open = openSession ?? fetchOpenSession() {
            close(open, at: .now, estimated: false)
            openSession = nil
            publishState(startedAt: nil, device: nil)
            LiveActivityController.shared.end(finalDuration: open.duration())
            ReminderScheduler.shared.cancelSessionReminders()
        } else if let device = observer?.current {
            begin(with: device)
        }
    }

    /// BLE 通道事件（可选通道，只对非苹果 BLE 耳机有效）
    func handleBLEEvent(connected: Bool, name: String) {
        guard settings.isTrackingEnabled else { return }
        if connected {
            let device = AudioOutputDevice(
                name: name,
                portType: .bluetoothLE,
                uid: name,
                channel: .lowEnergy
            )
            if openSession == nil {
                begin(with: device)
            }
        } else if openSession != nil {
            end(at: .now)
        }
    }

    private func close(_ record: SessionRecord, at date: Date, estimated: Bool) {
        // 心跳推算的时间不能晚于用户实际摘下之后太久；下限取开始时间
        record.endedAt = max(date, record.startedAt)
        record.isEstimated = estimated || record.isEstimated
        if estimated { record.source = .inferred }
        record.averageVolume = max(record.averageVolume, observer?.systemVolume() ?? 0)
        save()
    }

    // MARK: - 校准

    /// 修复「App 没在跑 → 记录一直开着」的脏数据
    private func reconcile(observer: AudioRouteObserver) {
        let live = observer.current

        // 快捷指令记下了精确断开时刻：优先用它收尾
        if let stopMark = settings.consumeStopMark(), let open = fetchOpenSession() {
            close(open, at: max(stopMark, open.startedAt), estimated: false)
            open.source = .shortcut
            openSession = nil
            save()
            publishState(startedAt: nil, device: nil)
            return
        }

        guard let open = fetchOpenSession() else {
            // 没有 open 记录，但耳机其实连着（App 被杀期间连上的）
            if let live, settings.isTrackingEnabled {
                begin(with: live)
            }
            return
        }

        if let live, live.key == open.deviceKey {
            openSession = open
            publishState(startedAt: open.startedAt, device: live)
            return
        }

        // 快捷指令 / 手动开出来的会话不该被「没听到耳机」推断掉：
        // 自动化链路本来就不依赖路由，这里若收尾会把用户的记录砍短。
        if open.source == .shortcut || open.source == .manual {
            // 只有确实过了很久（默认 12 小时）才认为它是一条泄漏的记录
            let staleLimit: TimeInterval = 12 * 3600
            if Date.now.timeIntervalSince(open.startedAt) < staleLimit {
                openSession = open
                publishState(startedAt: open.startedAt, device: nil)
                return
            }
        }

        guard settings.inferWhileSuspended else {
            close(open, at: open.startedAt, estimated: true)
            openSession = nil
            publishState(startedAt: nil, device: nil)
            return
        }

        // 用最后一次心跳作为「还连着」的证明时刻
        let heartbeat = settings.lastHeartbeat ?? open.startedAt
        let cut = min(max(heartbeat, open.startedAt), .now)
        close(open, at: cut, estimated: true)
        openSession = nil
        publishState(startedAt: nil, device: nil)
    }

    // MARK: - 写入

    private func fetchOpenSession() -> SessionRecord? {
        guard let context else { return nil }
        var descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func upsertProfile(for device: AudioOutputDevice) {
        guard let context else { return }
        let key = device.key
        var descriptor = FetchDescriptor<DeviceProfile>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            existing.name = device.name
            existing.lastSeenAt = .now
            existing.channel = device.channel
        } else {
            let count = (try? context.fetchCount(FetchDescriptor<DeviceProfile>())) ?? 0
            context.insert(
                DeviceProfile(
                    key: key,
                    name: device.name,
                    channel: device.channel,
                    accentIndex: count % 6
                )
            )
        }
    }

    private func save() {
        do {
            try context?.save()
        } catch {
            lastError = error.localizedDescription
            log.error("save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - 发布

    private func heartbeat() {
        settings.lastHeartbeat = .now
        SharedDefaults.writeState(state)
    }

    private func publishState(startedAt: Date?, device: AudioOutputDevice?) {
        let today = todayAccumulated(excluding: openSession)
        state = HeadphoneState(
            isConnected: startedAt != nil,
            deviceName: device?.name ?? openSession?.deviceName ?? "",
            deviceKey: device?.key ?? openSession?.deviceKey ?? "",
            channel: device?.channel ?? .other,
            sessionStartedAt: startedAt,
            todayAccumulated: today,
            source: openSession?.source ?? .live
        )
        settings.lastHeartbeat = startedAt == nil ? settings.lastHeartbeat : .now
        SharedDefaults.writeState(state)

        if let startedAt, appShouldShowLiveActivity {
            LiveActivityController.shared.start(deviceName: state.deviceName, startedAt: startedAt)
        }
    }

    private var appShouldShowLiveActivity: Bool {
        settings.liveActivitiesEnabled
    }

    /// 今日已完成会话之和（不含进行中的那条）
    func todayAccumulated(excluding open: SessionRecord?, now: Date = .now) -> TimeInterval {
        guard let context else { return 0 }
        let day = DayBounds.interval(ofDayContaining: now)
        let start = day.start
        let end = day.end
        var descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.startedAt >= start && $0.startedAt < end },
            sortBy: [SortDescriptor(\.startedAt)]
        )
        descriptor.fetchLimit = 500
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows
            .filter { $0.sessionID != open?.sessionID }
            .reduce(0) { $0 + $1.overlap(with: day) }
    }
}
