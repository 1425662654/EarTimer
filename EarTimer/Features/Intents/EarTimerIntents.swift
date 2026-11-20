import AppIntents
import Foundation
import os

/// 「EarTimer · 开始记录」——由「快捷指令 → 个人自动化 → 蓝牙 → 连接时」触发。
///
/// # 为什么这是唯一能做到「App 关着也自动计时」的通道
///
/// iOS 给第三方 App 的三条路，只有第三条能同时满足「自动 + App 不在运行」：
///
/// 1. `AVAudioSession.routeChangeNotification`
///    只在 App 存活时送达。App 被杀后没有任何补发。
///
/// 2. `CoreBluetooth` 状态恢复（`CBCentralManagerOptionRestoreIdentifierKey` + `bluetooth-central`）
///    理论上能被系统在后台重新拉起，但对 AirPods **不成立**：
///    AirPods 建立经典蓝牙（A2DP）连接后会停止 BLE 广播，扫描侧看不到「已连接」事件。
///    另外 TN3115 明确：用户从多任务强制退出后永不重启；iOS 26 起还要求配件经
///    `AccessorySetupKit` 配对才会触发重启。
///
/// 3. **快捷指令个人自动化（蓝牙触发）+ AppIntent**
///    Apple 官方确认「蓝牙」属于可设置「运行前询问 = 关闭」的触发器，
///    触发时不唤起界面、不需要 App 在前台。`openAppWhenRun = false` 让 intent
///    在纯后台进程里跑。
///
/// 因此 intent 里**直接写数据库**（`SharedSessionStore`），而不是只丢一个时间戳
/// 等 App 下次打开再补 —— 后者会导致「App 一直不打开，记录就一直是空的」。
///
/// 文案说明：AppIntent 的 `title` / `description` 是 `LocalizedStringResource`，
/// 系统在快捷指令里展示它时只认编译期字面量，**无法在运行时根据 App 内语言切换**。
/// 所以这里用双语并列（"开始记录 / Start session"），保证任何一种语言的用户都看得懂。
struct StartTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start session / 开始记录"
    static var description: IntentDescription = IntentDescription(
        "Writes a session immediately when headphones connect. The app does not need to be open. / 耳机连上时立刻写入一条记录，不需要打开 App。"
    )
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Device name / 设备名")
    var deviceName: String?

    init() {}

    init(deviceName: String? = nil) {
        self.deviceName = deviceName
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let now = Date.now
        let language = LanguageResolver.current()

        // 写数据库（App 可能完全没运行，所以走独立容器）
        let created = SharedSessionStore.begin(deviceName: deviceName, at: now, language: language)

        // 同时更新跨进程快照，供小组件 / 实况立即反映
        var state = SharedDefaults.readState()
        state.isConnected = true
        state.deviceName = (deviceName?.isEmpty == false ? deviceName! : state.deviceName)
        state.sessionStartedAt = now
        state.source = .shortcut
        SharedDefaults.writeState(state)

        // 兼容旧路径：保留时间戳标记，App 启动时用它校准
        SharedDefaults.suite.set(now.timeIntervalSince1970, forKey: SharedDefaults.Keys.shortcutStart)
        SharedDefaults.suite.set(now.timeIntervalSince1970, forKey: SharedDefaults.Keys.heartbeat)

        let message = created
            ? L10n.t(.intentStartDone, language)
            : L10n.t(.intentStartAlready, language)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

/// 「EarTimer · 结束记录」——蓝牙断开时触发
struct StopTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "End session / 结束记录"
    static var description: IntentDescription = IntentDescription(
        "Closes the session immediately when headphones disconnect. The app does not need to be open. / 耳机断开时立刻收尾，不需要打开 App。"
    )
    static var openAppWhenRun: Bool = false

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let now = Date.now
        let language = LanguageResolver.current()
        let closed = SharedSessionStore.end(at: now)

        var state = SharedDefaults.readState()
        state.isConnected = false
        state.sessionStartedAt = nil
        state.todayAccumulated = SharedSessionStore.todayTotal(now: now)
        SharedDefaults.writeState(state)

        SharedDefaults.suite.set(now.timeIntervalSince1970, forKey: SharedDefaults.Keys.shortcutStop)
        SharedDefaults.suite.set(state.todayAccumulated, forKey: SharedDefaults.Keys.todayTotal)

        let message = closed
            ? L10n.t(.intentStopDone, language)
            : L10n.t(.intentStopNothing, language)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

/// 查询今天累计。可在快捷指令里当变量用，也能接进「早安播报」。
struct TodayTotalIntent: AppIntent {
    static var title: LocalizedStringResource = "Today's time / 今日时长"
    static var description: IntentDescription = IntentDescription(
        "Returns the total connected time for today. / 返回今天的累计连接时长。"
    )
    static var openAppWhenRun: Bool = false

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let language = LanguageResolver.current()
        let total = SharedSessionStore.todayTotal()
        let message = "\(L10n.t(.intentTodayPrefix, language)) \(DurationText.human(total, language))"
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

/// 一键查看配置步骤。用户最容易卡在「找不到蓝牙自动化」这一步。
struct SetupGuideIntent: AppIntent {
    static var title: LocalizedStringResource = "Setup guide / 配置步骤"
    static var description = IntentDescription(
        "Opens EarTimer and shows how to set up the Bluetooth automation. / 打开 EarTimer 并显示蓝牙自动化的配置方法。"
    )
    static var openAppWhenRun: Bool = true

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        SharedDefaults.suite.set(true, forKey: SharedDefaults.Keys.showSetupGuide)
        let language = LanguageResolver.current()
        return .result(dialog: IntentDialog(stringLiteral: L10n.t(.intentGuideDone, language)))
    }
}

struct EarTimerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTrackingIntent(),
            phrases: [
                "Start my \(.applicationName) session",
                "Start tracking with \(.applicationName)"
            ],
            shortTitle: "Start",
            systemImageName: "play.circle"
        )
        AppShortcut(
            intent: StopTrackingIntent(),
            phrases: [
                "End my \(.applicationName) session",
                "Stop tracking with \(.applicationName)"
            ],
            shortTitle: "End",
            systemImageName: "stop.circle"
        )
        AppShortcut(
            intent: TodayTotalIntent(),
            phrases: ["How long have I used headphones with \(.applicationName)"],
            shortTitle: "Today",
            systemImageName: "clock"
        )
    }
}
