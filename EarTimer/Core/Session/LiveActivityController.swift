import Foundation
import ActivityKit
import os

/// 耳机连接时的灵动岛 / 锁屏实时计时。
/// 只要用户允许，App 在后台被挂起后系统仍会显示计时（用的是 `Text(timerInterval:)`，不依赖 App 刷新）。
@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var activity: Activity<EarActivityAttributes>?
    private let log = Logger(subsystem: "com.yg.eartimer", category: "LiveActivity")

    private init() {}

    private var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(deviceName: String, startedAt: Date) {
        guard isSupported else { return }
        if activity != nil { return }
        // 系统里可能残留上一轮（App 被杀时来不及 end）
        Task { await endAllStale() }

        let attributes = EarActivityAttributes(deviceName: deviceName, startedAt: startedAt)
        let content = ActivityContent(
            state: EarActivityAttributes.ContentState(
                startedAt: startedAt,
                todayTotalBefore: SessionEngine.shared.state.todayAccumulated,
                goalSeconds: SettingsStore.shared.dailyBudget,
                isEstimated: false
            ),
            staleDate: nil
        )
        do {
            activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            log.error("start failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func end(finalDuration: TimeInterval) {
        guard let activity else { return }
        self.activity = nil
        let before = max(0, SessionEngine.shared.state.todayAccumulated - finalDuration)
        let content = ActivityContent(
            state: EarActivityAttributes.ContentState(
                startedAt: activity.attributes.startedAt,
                todayTotalBefore: before,
                goalSeconds: SettingsStore.shared.dailyBudget,
                isEstimated: false
            ),
            staleDate: .now
        )
        Task { await activity.end(content, dismissalPolicy: .after(.now + 30)) }
    }

    private func endAllStale() async {
        for activity in Activity<EarActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
