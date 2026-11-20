import Foundation

/// 全量文案表。目标：**一个 key 都不能缺**，所以用「两份字典 + 启动自检」的方式，
/// 而不是 `Localizable.strings`——后者缺 key 时会静默回退到 key 本身，很难发现。
///
/// 之所以手写而不用 `.xcstrings`：这个 App 只有两种语言、文案量中等，
/// 手写能保证「英文与中文一一对应」在编译期就被编译器检查（switch 必须穷举）。
enum L10n {

    // MARK: - 入口

    static func t(_ key: Key, _ language: AppLanguage) -> String {
        switch language {
        case .english: key.english
        case .chinese: key.chinese
        }
    }

    // MARK: - 键

    enum Key {
        // Tab / 导航
        case tabHome, tabHistory, tabInsights, tabSettings

        // 首页
        case todayTotal, sessionElapsed, todayRemaining, todayGoal
        case goalDone, goalRemaining, goalUnset, goalReached
        case justConnected, restCountdown, restNow, connectedFor
        case lastSession, wearHeadphonesToStart
        case todayRecords, recordCountSuffix, emptyToday
        case disconnect, manualStart, notConnected, waitingForHeadphone
        case connectedChannel, connectedChannelShortcut, connectedChannelSource
        case breakHintTitle, gotIt, breakHintBody

        // 记录行 / 徽章
        case badgeInProgress, badgeEstimated, badgeHadCall
        case channelMusic, channelCall, channelLowEnergy, channelWired, channelOther
        case sourceLive, sourceRouteChange, sourceShortcut, sourceInferred, sourceManual

        // 历史
        case thisWeek, thisMonth, allTime, dailyAverage, weekOverWeek
        case historyEmptyTitle, historyEmptyBody, noRecordsYet

        // 记录详情
        case detailDuration, detailStart, detailEnd
        case detailSourceSection, detailHowRecorded, detailChannel
        case detailEstimatedNote, detailHadCallNote
        case detailNoteSection, detailNotePlaceholder
        case detailDelete, detailDeleteConfirmTitle, detailDeleteConfirmBody
        case cancel, save, delete

        // 洞察
        case insightsCumulative, insightsLongest, insightsStreak, streakUnit
        case insightsHeatmap, heatmapLess, heatmapMore
        case insightsByDevice, insightsByDeviceWindow, noDeviceData
        case insightsHourDistribution, hourAxisSuffix
        case insightsTodayLoad, loadComfortable, loadNormal, loadNearLimit, loadOver
        case loadAdviceComfortable, loadAdviceNormal, loadAdviceNear, loadAdviceOver

        // 设置
        case settingsTitle
        case accuracySection, bluetoothAutomation, automationActive, automationNotConfigured, automationPending
        case automationHintActive, automationHintNone, automationHintPending
        case accuracyFooter
        case automationSection, manualSetupGuide, manualSetupGuideSub
        case recordingSection, autoRecord, includeWired, inferWhileSuspended, liveActivityToggle
        case inferFooter
        case remindersSection, continuousWear, wearOff, minutes30, minutes45, minutes60, minutes90
        case dailyBudget, budgetUnlimited, hour1, hour2, hour3, hour5, hour8
        case goalNotify
        case dataSection, exportCSV, shareFile, eraseAll, eraseConfirmTitle, eraseConfirmBody
        case aboutSection, version, sessionEngine, engineRunning, engineIdle
        case privacyFooter
        case languageSection, languageLabel, languageFooter, done
        case setupAlertTitle, setupAlertBody

        // 引导
        case guideTitle, guideSkip, guideNext, guideOpenShortcuts, guideDone
        case guideStep1Title, guideStep1Body, guideStep1Chip
        case guideStep2Title, guideStep2Body, guideStep2Chip
        case guideStep3Title, guideStep3Body, guideStep3Chip
        case guideStep4Title, guideStep4Body, guideStep4Chip
        case guideStep5Title, guideStep5Body

        // Intent
        case intentStartTitle, intentStartDesc, intentStartParamTitle, intentStartParamDesc
        case intentStartDone, intentStartAlready
        case intentStopTitle, intentStopDesc, intentStopDone, intentStopNothing
        case intentTodayTitle, intentTodayDesc, intentTodayPrefix
        case intentGuideTitle, intentGuideDesc, intentGuideDone

        // 通用
        case okay, notSet, placeholder, defaultHeadphoneName

        // MARK: 英文

        var english: String {
            switch self {
            case .tabHome: "Home"
            case .tabHistory: "History"
            case .tabInsights: "Insights"
            case .tabSettings: "Settings"

            case .todayTotal: "Today"
            case .sessionElapsed: "This session"
            case .todayRemaining: "Remaining"
            case .todayGoal: "Daily goal"
            case .goalDone: "Goal reached"
            case .goalRemaining: "left"
            case .goalUnset: "No daily limit"
            case .goalReached: "reached"
            case .justConnected: "Just connected"
            case .restCountdown: "Next break in"
            case .restNow: "Continuous for"
            case .connectedFor: "Connected"
            case .lastSession: "Last"
            case .wearHeadphonesToStart: "Put on your headphones"
            case .todayRecords: "Today"
            case .recordCountSuffix: "sessions"
            case .emptyToday: "No sessions yet. Put on your headphones and one will appear here."
            case .disconnect: "End"
            case .manualStart: "Start"
            case .notConnected: "No headphones"
            case .waitingForHeadphone: "Waiting for headphones"
            case .connectedChannel: "Connected"
            case .connectedChannelShortcut: "Connected"
            case .connectedChannelSource: "Connected"
            case .breakHintTitle: "Break"
            case .gotIt: "Got it"
            case .breakHintBody: "min connected. Take them off for a bit?"

            case .badgeInProgress: "LIVE"
            case .badgeEstimated: "EST"
            case .badgeHadCall: "CALL"
            case .channelMusic: "Music"
            case .channelCall: "Call"
            case .channelLowEnergy: "BT LE"
            case .channelWired: "Wired"
            case .channelOther: "Other"
            case .sourceLive: "Live"
            case .sourceRouteChange: "Auto"
            case .sourceShortcut: "Shortcut"
            case .sourceInferred: "Estimated"
            case .sourceManual: "Manual"

            case .thisWeek: "This week"
            case .thisMonth: "This month"
            case .allTime: "All time"
            case .dailyAverage: "Daily avg"
            case .weekOverWeek: "vs last week"
            case .historyEmptyTitle: "No sessions yet"
            case .historyEmptyBody: "Sessions appear here once your headphones connect."
            case .noRecordsYet: "No records"

            case .detailDuration: "Duration"
            case .detailStart: "Start"
            case .detailEnd: "End"
            case .detailSourceSection: "Source"
            case .detailHowRecorded: "How it was recorded"
            case .detailChannel: "Channel"
            case .detailEstimatedNote: "Estimated — the app was not running at the time"
            case .detailHadCallNote: "A call happened during this session"
            case .detailNoteSection: "Note"
            case .detailNotePlaceholder: "e.g. podcast on the commute"
            case .detailDelete: "Delete this record"
            case .detailDeleteConfirmTitle: "Delete?"
            case .detailDeleteConfirmBody: "This cannot be undone."
            case .cancel: "Cancel"
            case .save: "Save"
            case .delete: "Delete"

            case .insightsCumulative: "Total"
            case .insightsLongest: "Longest"
            case .insightsStreak: "Streak"
            case .streakUnit: "d"
            case .insightsHeatmap: "Last 30 days"
            case .heatmapLess: "Less"
            case .heatmapMore: "More"
            case .insightsByDevice: "By device"
            case .insightsByDeviceWindow: "last 30 days"
            case .noDeviceData: "No device data yet"
            case .insightsHourDistribution: "Time of day"
            case .hourAxisSuffix: "h"
            case .insightsTodayLoad: "Today's load"
            case .loadComfortable: "Comfortable"
            case .loadNormal: "Normal"
            case .loadNearLimit: "Near limit"
            case .loadOver: "Over budget"
            case .loadAdviceComfortable: "Plenty of headroom today. Still, give your ears a break every hour."
            case .loadAdviceNormal: "A normal day. Keep it up."
            case .loadAdviceNear: "Approaching your budget. Consider speakers or a break."
            case .loadAdviceOver: "Over today's budget. Try to go easy for the rest of the day."

            case .settingsTitle: "Settings"
            case .accuracySection: "Accuracy"
            case .bluetoothAutomation: "Bluetooth automation"
            case .automationActive: "Active"
            case .automationNotConfigured: "Not set up"
            case .automationPending: "Unconfirmed"
            case .automationHintActive: "Last session came from automation"
            case .automationHintNone: "Only records while the app is open"
            case .automationHintPending: "Last record was estimated or manual"
            case .accuracyFooter: "iOS does not let apps listen to Bluetooth in the background. Only the Shortcuts Bluetooth automation can wake EarTimer the moment you connect — that is what makes background tracking work."
            case .automationSection: "Automation"
            case .manualSetupGuide: "Setup steps"
            case .manualSetupGuideSub: "Plain text version of the guide"
            case .recordingSection: "Recording"
            case .autoRecord: "Auto-record sessions"
            case .includeWired: "Include wired headphones"
            case .inferWhileSuspended: "Estimate while suspended"
            case .liveActivityToggle: "Live Activity timer"
            case .inferFooter: "When the app is suspended, a session is closed using the last heartbeat and marked as \"EST\"."
            case .remindersSection: "Reminders"
            case .continuousWear: "Continuous wear"
            case .wearOff: "Off"
            case .minutes30: "30 min"
            case .minutes45: "45 min"
            case .minutes60: "60 min"
            case .minutes90: "90 min"
            case .dailyBudget: "Daily budget"
            case .budgetUnlimited: "No limit"
            case .hour1: "1 hour"
            case .hour2: "2 hours"
            case .hour3: "3 hours"
            case .hour5: "5 hours"
            case .hour8: "8 hours"
            case .goalNotify: "Notify when goal reached"
            case .dataSection: "Data"
            case .exportCSV: "Export CSV"
            case .shareFile: "Share"
            case .eraseAll: "Erase all records"
            case .eraseConfirmTitle: "Erase all records?"
            case .eraseConfirmBody: "This deletes every session and device profile. It cannot be undone."
            case .aboutSection: "About"
            case .version: "Version"
            case .sessionEngine: "Session engine"
            case .engineRunning: "Running"
            case .engineIdle: "Idle"
            case .privacyFooter: "EarTimer never accesses your audio and never uploads anything. All records stay on this device."
            case .languageSection: "Language"
            case .languageLabel: "Language"
            case .languageFooter: "Switching changes the interface only. Your records are unaffected."
            case .done: "Done"
            case .setupAlertTitle: "Record with Shortcuts"
            case .setupAlertBody: "Open Shortcuts → Automation → New → Bluetooth → choose your headphones → When Connected → add the action \"EarTimer · Start session\". Do the same for disconnect with \"End session\"."

            case .guideTitle: "Make EarTimer accurate"
            case .guideSkip: "Skip"
            case .guideNext: "Next"
            case .guideOpenShortcuts: "Open Shortcuts"
            case .guideDone: "I'm set up — open EarTimer"
            case .guideStep1Title: "Why one extra step"
            case .guideStep1Body: "iOS does not let apps listen to Bluetooth in the background. Only a Shortcuts automation can wake EarTimer the moment you put your headphones on — that is how it records while the app is closed."
            case .guideStep1Chip: "Set it up once, then it's automatic"
            case .guideStep2Title: "Step 1 · Create the automation"
            case .guideStep2Body: "Open Shortcuts → Automation → + → Bluetooth → pick your headphones → When Connected → turn OFF \"Ask Before Running\"."
            case .guideStep2Chip: "\"Ask Before Running\" must be off"
            case .guideStep3Title: "Step 2 · Add the action"
            case .guideStep3Body: "Add Action → search \"EarTimer\" → choose \"Start session\" → Done."
            case .guideStep3Chip: "If you can find it, the intent is ready"
            case .guideStep4Title: "Step 3 · Do it again"
            case .guideStep4Body: "Repeat the flow, but set the trigger to \"When Disconnected\" and the action to \"End session\"."
            case .guideStep4Chip: "Two automations, one in one out"
            case .guideStep5Title: "Done"
            case .guideStep5Body: "From now on, sessions start when you put them on and end when you take them off. The app does not need to be open or running in the background."

            case .intentStartTitle: "Start headphone session"
            case .intentStartDesc: "Call when headphones connect. Writes a session immediately; the app does not need to be open."
            case .intentStartParamTitle: "Device name"
            case .intentStartParamDesc: "Optional. Use it to tell multiple pairs apart. Defaults to \"Headphones\"."
            case .intentStartDone: "Session started"
            case .intentStartAlready: "Already recording"
            case .intentStopTitle: "End headphone session"
            case .intentStopDesc: "Call when headphones disconnect. Closes the session immediately; the app does not need to be open."
            case .intentStopDone: "Session ended"
            case .intentStopNothing: "No session in progress"
            case .intentTodayTitle: "Today's headphone time"
            case .intentTodayDesc: "Returns the total connected time for today."
            case .intentTodayPrefix: "Headphone time today:"
            case .intentGuideTitle: "Show automation setup"
            case .intentGuideDesc: "Opens EarTimer and shows how to set up the Bluetooth automation."
            case .intentGuideDone: "Opened the setup guide"

            case .okay: "OK"
            case .notSet: "Not set"
            case .placeholder: "—"
            case .defaultHeadphoneName: "Headphones"
            }
        }

        // MARK: 中文

        var chinese: String {
            switch self {
            case .tabHome: "首页"
            case .tabHistory: "历史"
            case .tabInsights: "洞察"
            case .tabSettings: "设置"

            case .todayTotal: "今日累计"
            case .sessionElapsed: "本次已听"
            case .todayRemaining: "今日剩余"
            case .todayGoal: "今日目标"
            case .goalDone: "今日目标"
            case .goalRemaining: "还剩"
            case .goalUnset: "未设置每日预算"
            case .goalReached: "已达成"
            case .justConnected: "刚刚连上"
            case .restCountdown: "距下次休息"
            case .restNow: "已连续连接"
            case .connectedFor: "已连续"
            case .lastSession: "上次"
            case .wearHeadphonesToStart: "戴上耳机自动开始"
            case .todayRecords: "今日记录"
            case .recordCountSuffix: "次"
            case .emptyToday: "还没有记录。戴上耳机，这里会自动出现一条。"
            case .disconnect: "结束"
            case .manualStart: "开始"
            case .notConnected: "未连接耳机"
            case .waitingForHeadphone: "等待耳机连上手机"
            case .connectedChannel: "已连接"
            case .connectedChannelShortcut: "已连接"
            case .connectedChannelSource: "已连接"
            case .breakHintTitle: "休息"
            case .gotIt: "知道了"
            case .breakHintBody: "分钟，摘下透透气？"

            case .badgeInProgress: "进行中"
            case .badgeEstimated: "推算"
            case .badgeHadCall: "含通话"
            case .channelMusic: "音乐"
            case .channelCall: "通话"
            case .channelLowEnergy: "低功耗"
            case .channelWired: "有线"
            case .channelOther: "其他"
            case .sourceLive: "实时"
            case .sourceRouteChange: "自动"
            case .sourceShortcut: "快捷指令"
            case .sourceInferred: "推算"
            case .sourceManual: "手动"

            case .thisWeek: "本周"
            case .thisMonth: "本月"
            case .allTime: "全部"
            case .dailyAverage: "日均"
            case .weekOverWeek: "较上周"
            case .historyEmptyTitle: "还没有记录"
            case .historyEmptyBody: "耳机连上手机后会在这里留下一条记录。"
            case .noRecordsYet: "暂无记录"

            case .detailDuration: "时长"
            case .detailStart: "开始"
            case .detailEnd: "结束"
            case .detailSourceSection: "来源"
            case .detailHowRecorded: "记录方式"
            case .detailChannel: "通道"
            case .detailEstimatedNote: "这条时长是推算的（App 当时不在运行）"
            case .detailHadCallNote: "会话途中发生过通话"
            case .detailNoteSection: "备注"
            case .detailNotePlaceholder: "例如：通勤路上听播客"
            case .detailDelete: "删除这条记录"
            case .detailDeleteConfirmTitle: "删除？"
            case .detailDeleteConfirmBody: "删除后无法恢复。"
            case .cancel: "取消"
            case .save: "保存"
            case .delete: "删除"

            case .insightsCumulative: "累计"
            case .insightsLongest: "最长一次"
            case .insightsStreak: "连续天数"
            case .streakUnit: "天"
            case .insightsHeatmap: "近 30 天听音热力"
            case .heatmapLess: "少"
            case .heatmapMore: "多"
            case .insightsByDevice: "按设备"
            case .insightsByDeviceWindow: "近 30 天"
            case .noDeviceData: "还没有设备数据"
            case .insightsHourDistribution: "时段分布"
            case .hourAxisSuffix: "时"
            case .insightsTodayLoad: "今日负荷"
            case .loadComfortable: "舒适"
            case .loadNormal: "正常"
            case .loadNearLimit: "接近上限"
            case .loadOver: "超出预算"
            case .loadAdviceComfortable: "今天还有很大余量，注意每 60 分钟让耳朵休息一下。"
            case .loadAdviceNormal: "处于日常强度，保持就好。"
            case .loadAdviceNear: "快到今日预算了，接下来考虑外放或摘下耳机。"
            case .loadAdviceOver: "已超出今日预算，建议今天剩下的时间少戴耳机。"

            case .settingsTitle: "设置"
            case .accuracySection: "准确度"
            case .bluetoothAutomation: "蓝牙自动化"
            case .automationActive: "已生效"
            case .automationNotConfigured: "未配置"
            case .automationPending: "待确认"
            case .automationHintActive: "最近一次由蓝牙自动化记录"
            case .automationHintNone: "当前只在 App 打开时才能记到"
            case .automationHintPending: "最近一条是推算或手动记录"
            case .accuracyFooter: "iOS 不允许 App 在后台监听蓝牙。只有让「快捷指令 · 蓝牙自动化」在连接瞬间叫醒 EarTimer，才能做到 App 关着也自动计时。"
            case .automationSection: "自动化"
            case .manualSetupGuide: "手动配置说明"
            case .manualSetupGuideSub: "不想看引导时，这里是纯文字步骤"
            case .recordingSection: "记录"
            case .autoRecord: "自动记录连接时长"
            case .includeWired: "包含有线耳机"
            case .inferWhileSuspended: "后台推算补全"
            case .liveActivityToggle: "灵动岛实时计时"
            case .inferFooter: "「后台推算补全」会在 App 被系统挂起时，用最后一次心跳向前补一段时长，并标记为「推算」。"
            case .remindersSection: "提醒"
            case .continuousWear: "连续佩戴提醒"
            case .wearOff: "关闭"
            case .minutes30: "30 分钟"
            case .minutes45: "45 分钟"
            case .minutes60: "60 分钟"
            case .minutes90: "90 分钟"
            case .dailyBudget: "每日听音预算"
            case .budgetUnlimited: "不设限"
            case .hour1: "1 小时"
            case .hour2: "2 小时"
            case .hour3: "3 小时"
            case .hour5: "5 小时"
            case .hour8: "8 小时"
            case .goalNotify: "目标达成提醒"
            case .dataSection: "数据"
            case .exportCSV: "导出 CSV"
            case .shareFile: "分享"
            case .eraseAll: "清空所有记录"
            case .eraseConfirmTitle: "清空所有记录？"
            case .eraseConfirmBody: "这会删除全部连接历史与设备档案，无法恢复。"
            case .aboutSection: "关于"
            case .version: "版本"
            case .sessionEngine: "会话引擎"
            case .engineRunning: "运行中"
            case .engineIdle: "待机"
            case .privacyFooter: "EarTimer 不访问你的音频内容，也不联网上传任何数据。所有记录只存在这台手机上。"
            case .languageSection: "语言"
            case .languageLabel: "界面语言"
            case .languageFooter: "切换只影响界面显示，不会影响已有记录。"
            case .done: "完成"
            case .setupAlertTitle: "用快捷指令记录"
            case .setupAlertBody: "打开「快捷指令」App → 自动化 → 新建个人自动化 → 蓝牙 → 选择你的耳机 → 连接时 → 添加操作「EarTimer · 开始记录」。断开时同理加一条「结束记录」。"

            case .guideTitle: "让 EarTimer 更准"
            case .guideSkip: "跳过"
            case .guideNext: "下一步"
            case .guideOpenShortcuts: "打开快捷指令"
            case .guideDone: "我已配置好，进入 EarTimer"
            case .guideStep1Title: "为什么要多一步"
            case .guideStep1Body: "iOS 不允许 App 在后台偷听蓝牙。所以只有让「快捷指令」在你戴上耳机的瞬间叫醒 EarTimer，才能做到 App 关着也自动计时。"
            case .guideStep1Chip: "只需配置一次，以后全自动"
            case .guideStep2Title: "第一步 · 建自动化"
            case .guideStep2Body: "打开「快捷指令」→ 底部「自动化」→ 右上「+」→ 选「蓝牙」→ 设备选你的耳机 → 触发条件选「已连接」→ 关闭「运行前询问」。"
            case .guideStep2Chip: "「运行前询问」必须关掉"
            case .guideStep3Title: "第二步 · 加动作"
            case .guideStep3Body: "添加操作 → 搜索「EarTimer」→ 选「开始记录耳机时长」→ 完成。"
            case .guideStep3Chip: "能搜到说明扩展已就绪"
            case .guideStep4Title: "第三步 · 再来一遍"
            case .guideStep4Body: "重复上面流程，触发条件改成「已断开」，动作选「结束记录耳机时长」。"
            case .guideStep4Chip: "两条自动化，一进一出"
            case .guideStep5Title: "完成"
            case .guideStep5Body: "之后耳机一戴上就开始记，摘下就停。App 不用打开，也不用留在后台。"

            case .intentStartTitle: "开始记录耳机时长"
            case .intentStartDesc: "耳机连上时调用。会立刻写入一条连接记录，不需要打开 App。"
            case .intentStartParamTitle: "设备名"
            case .intentStartParamDesc: "可选。多副耳机时用来区分；留空则记为「耳机」。"
            case .intentStartDone: "已开始记录耳机时长"
            case .intentStartAlready: "已在记录中"
            case .intentStopTitle: "结束记录耳机时长"
            case .intentStopDesc: "耳机断开时调用。会立刻收尾这条记录，不需要打开 App。"
            case .intentStopDone: "已结束本次记录"
            case .intentStopNothing: "当前没有进行中的记录"
            case .intentTodayTitle: "查询今天耳机时长"
            case .intentTodayDesc: "返回今天的累计连接时长。"
            case .intentTodayPrefix: "今天耳机累计连接"
            case .intentGuideTitle: "查看自动化配置步骤"
            case .intentGuideDesc: "打开 EarTimer 并显示蓝牙自动化的配置方法。"
            case .intentGuideDone: "已打开配置向导"

            case .okay: "好"
            case .notSet: "未设置"
            case .placeholder: "—"
            case .defaultHeadphoneName: "耳机"
            }
        }
    }
}
