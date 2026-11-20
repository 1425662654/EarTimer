import Foundation
import UserNotifications
import os

/// 本地提醒：连续佩戴、预算用尽、目标达成。
/// 全部用 `UNTimeIntervalNotificationTrigger`，App 不必常驻。
/// 文案跟随 App 内语言设置（`LanguageResolver.current()`），而不是系统语言。
@MainActor
final class ReminderScheduler {
    static let shared = ReminderScheduler()

    private let log = Logger(subsystem: "com.yg.eartimer", category: "Reminder")

    private var center: UNUserNotificationCenter { .current() }

    private init() {}

    enum Identifier {
        static let wear = "et.reminder.wear"
        static let budget = "et.reminder.budget"
        static let goal = "et.reminder.goal"
    }

    func requestAuthorization() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            log.error("auth failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 会话开始：安排「连续佩戴提醒」与「预算用尽提醒」
    func scheduleForSession(startedAt: Date, todayAccumulated: TimeInterval) {
        let language = LanguageResolver.current()
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.wear])

        let threshold = SettingsStore.shared.continuousWearThreshold
        if threshold > 0 {
            let fireAt = startedAt.addingTimeInterval(threshold)
            guard fireAt > .now else { return }
            let minutes = Int(threshold / 60)
            let content = UNMutableNotificationContent()
            content.title = language == .chinese ? "该让耳朵歇会儿了" : "Time for a break"
            content.body = language == .chinese
                ? "已经连续佩戴 \(minutes) 分钟，摘下耳机休息 5 分钟。"
                : "\(minutes) minutes connected. Take them off for a few minutes."
            content.sound = .default
            content.interruptionLevel = .active

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(60, fireAt.timeIntervalSinceNow),
                repeats: false
            )
            center.add(UNNotificationRequest(identifier: Identifier.wear, content: content, trigger: trigger))
        }

        let budget = SettingsStore.shared.dailyBudget
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.budget])
        guard budget > 0, todayAccumulated < budget else { return }
        let remaining = budget - todayAccumulated
        let content = UNMutableNotificationContent()
        content.title = language == .chinese ? "今天的听音预算用完了" : "Daily budget reached"
        content.body = language == .chinese
            ? "已听 \(DurationText.human(budget, language))，建议歇一歇。"
            : "You have listened for \(DurationText.human(budget, language)). Time for a rest."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(60, remaining + startedAt.timeIntervalSinceNow),
            repeats: false
        )
        center.add(UNNotificationRequest(identifier: Identifier.budget, content: content, trigger: trigger))
    }

    func cancelSessionReminders() {
        center.removePendingNotificationRequests(
            withIdentifiers: [Identifier.wear, Identifier.budget]
        )
    }

    func notifyGoalReached(total: TimeInterval) {
        guard SettingsStore.shared.notifyOnGoal else { return }
        let language = LanguageResolver.current()
        let content = UNMutableNotificationContent()
        content.title = language == .chinese ? "今日目标达成" : "Daily goal reached"
        content.body = language == .chinese
            ? "累计佩戴 \(DurationText.human(total, language))。"
            : "Total connected: \(DurationText.human(total, language))."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        center.add(
            UNNotificationRequest(identifier: Identifier.goal, content: content, trigger: trigger)
        )
    }
}
