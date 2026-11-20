import WidgetKit
import SwiftUI
import ActivityKit

/// 灵动岛 / 锁屏实时活动。
/// 计时用 `Text(timerInterval:)` 自走，App 被挂起也不停表。
struct EarLiveActivity: Widget {
    private var language: AppLanguage { LanguageResolver.current() }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EarActivityAttributes.self) { context in
            lockScreen(context: context)
                .activityBackgroundTint(Theme.Palette.bg)
                .activitySystemActionForegroundColor(Theme.Palette.mint)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "airpodspro")
                            .foregroundStyle(Theme.Palette.mint)
                        Text(context.attributes.deviceName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.Palette.text)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(L10n.t(.todayTotal, language)) \(DurationText.human(context.state.todayProjected, language))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.Palette.muted)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(timerInterval: context.attributes.startedAt...Date.now.addingTimeInterval(86_400), countsDown: false)
                        .font(.system(size: 26, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.Palette.text)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(language == .chinese ? "已连续佩戴，记得每小时休息一下" : "Remember to take a break every hour")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Palette.dim)
                }
            } compactLeading: {
                Image(systemName: "airpodspro")
                    .foregroundStyle(Theme.Palette.mint)
            } compactTrailing: {
                Text(timerInterval: context.attributes.startedAt...Date.now.addingTimeInterval(86_400), countsDown: false)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Palette.mint)
                    .frame(maxWidth: 54)
            } minimal: {
                Image(systemName: "airpodspro")
                    .foregroundStyle(Theme.Palette.mint)
            }
            .keylineTint(Theme.Palette.mint)
        }
    }

    private func lockScreen(context: ActivityViewContext<EarActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "airpodspro")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Theme.Palette.mint)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.deviceName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
                Text("\(L10n.t(.todayTotal, language)) \(DurationText.human(context.state.todayProjected, language))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Palette.muted)
                    .lineLimit(1)
            }

            Spacer()

            Text(timerInterval: context.attributes.startedAt...Date.now.addingTimeInterval(86_400), countsDown: false)
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.Palette.text)
        }
        .padding(14)
    }
}
