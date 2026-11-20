import WidgetKit
import SwiftUI

/// 桌面 / 锁屏小组件。数据全部来自 App Group 的小快照，
/// 不读 SwiftData，避免主 App 没跑时打不开数据库。
struct EarTimerWidget: Widget {
    let kind: String = "EarTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EarTimelineProvider()) { entry in
            EarWidgetView(entry: entry)
                .containerBackground(Theme.Palette.bg, for: .widget)
        }
        .configurationDisplayName("EarTimer")
        .description("Connected time and today's total.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct EarWidgetEntry: TimelineEntry {
    var date: Date
    var state: HeadphoneState
    /// 小组件进程里单独解析，跟随 App 内语言设置
    var language: AppLanguage
}

struct EarTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> EarWidgetEntry {
        EarWidgetEntry(date: .now, state: .disconnected, language: LanguageResolver.current())
    }

    func getSnapshot(in context: Context, completion: @escaping (EarWidgetEntry) -> Void) {
        completion(
            EarWidgetEntry(date: .now, state: SharedDefaults.readState(), language: LanguageResolver.current())
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EarWidgetEntry>) -> Void) {
        let state = SharedDefaults.readState()
        let language = LanguageResolver.current()
        let now = Date.now
        // 连接中：每 15 分钟刷新一次（小组件不支持秒级），数字靠 Text(timerInterval:) 自走
        let next = state.isConnected ? now.addingTimeInterval(15 * 60) : now.addingTimeInterval(60 * 60)
        let entries = [EarWidgetEntry(date: now, state: state, language: language)]
        completion(Timeline(entries: entries, policy: .after(next)))
    }
}

struct EarWidgetView: View {
    var entry: EarWidgetEntry
    @Environment(\.widgetFamily) private var family

    private var language: AppLanguage { entry.language }
    private func t(_ key: L10n.Key) -> String { L10n.t(key, language) }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .systemMedium:
            medium
        default:
            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: entry.state.isConnected ? "airpodspro" : "airpods")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(entry.state.isConnected ? Theme.Palette.mint : Theme.Palette.dim)
                Text(entry.state.isConnected ? entry.state.deviceName : t(.notConnected))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Palette.muted)
                    .lineLimit(1)
            }

            if let start = entry.state.sessionStartedAt, entry.state.isConnected {
                Text(timerInterval: start...Date.now.addingTimeInterval(86_400), countsDown: false)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.Palette.text)
                Text(t(.sessionElapsed))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Palette.dim)
            } else {
                Text(DurationText.tight(entry.state.todayTotal()))
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.Palette.text)
                Text(t(.todayTotal))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Palette.dim)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Theme.Palette.surface2, lineWidth: 6)
                Image(systemName: entry.state.isConnected ? "airpodspro" : "airpods")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(entry.state.isConnected ? Theme.Palette.mint : Theme.Palette.dim)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.state.isConnected ? entry.state.deviceName : t(.notConnected))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
                Text("\(t(.todayTotal)) \(DurationText.human(entry.state.todayTotal(), language))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Palette.muted)
                    .lineLimit(1)
                if let start = entry.state.sessionStartedAt, entry.state.isConnected {
                    Text(timerInterval: start...Date.now.addingTimeInterval(86_400), countsDown: false)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.Palette.mint)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var circular: some View {
        Gauge(
            value: entry.state.isConnected ? 0.7 : 0,
            label: { Image(systemName: "airpodspro") },
            currentValueLabel: {
                Text(DurationText.tight(entry.state.todayTotal()))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
        )
        .gaugeStyle(.accessoryCircular)
        .tint(Theme.Palette.mint)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.state.isConnected ? t(.sessionElapsed) : t(.todayTotal))
                .font(.system(size: 11))
                .foregroundStyle(Theme.Palette.muted)
            if let start = entry.state.sessionStartedAt, entry.state.isConnected {
                Text(timerInterval: start...Date.now.addingTimeInterval(86_400), countsDown: false)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            } else {
                Text(DurationText.human(entry.state.todayTotal(), language))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
