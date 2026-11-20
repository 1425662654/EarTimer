import SwiftUI

/// 首页主计时环。用 `TimelineView` 每秒推进，不建 Timer，页面切走自动停。
struct SessionRing: View {
    var startedAt: Date
    /// 本次开始之前，今天已经累计的时长
    var todayBefore: TimeInterval
    var goal: TimeInterval
    var isEstimated: Bool
    /// 连续连接多久提醒一次（秒），0 = 不提醒
    var restThreshold: TimeInterval
    var language: AppLanguage

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(startedAt))
            let progress = progress(todayBefore: todayBefore, elapsed: elapsed)

            ZStack {
                Circle()
                    .stroke(Theme.Palette.surface2, lineWidth: 12)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.Palette.mint, Theme.Palette.mintDim, Theme.Palette.mint],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: Theme.Spacing.s) {
                    HStack(spacing: 5) {
                        Text(L10n.t(.sessionElapsed, language))
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Palette.muted)
                        if isEstimated {
                            MetaChip(text: L10n.t(.badgeEstimated, language), tint: Theme.Palette.amber)
                        }
                    }

                    Text(DurationText.clock(elapsed))
                        .font(Theme.Font.display)
                        .foregroundStyle(Theme.Palette.text)
                        .contentTransition(.numericText(countsDown: false))
                        .accessibilityLabel(
                            "\(L10n.t(.sessionElapsed, language)) \(DurationText.human(elapsed, language))"
                        )

                    Text(subtitle(elapsed: elapsed))
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Palette.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.l)
                }
            }
            .frame(width: 252, height: 252)
            .accessibilityElement(children: .contain)
        }
    }

    private func progress(todayBefore: TimeInterval, elapsed: TimeInterval) -> Double {
        guard goal > 0 else { return 0 }
        return min(1, max(0, (todayBefore + elapsed) / goal))
    }

    private func subtitle(elapsed: TimeInterval) -> String {
        if elapsed < 60 { return L10n.t(.justConnected, language) }

        if goal > 0, todayBefore + elapsed >= goal {
            return "\(L10n.t(.todayGoal, language)) \(DurationText.short(goal, language))"
        }

        if restThreshold > 0 {
            if elapsed >= restThreshold {
                let mins = Int(elapsed / 60)
                return language == .chinese
                    ? "已连续 \(mins) 分钟 · 建议摘下休息"
                    : "\(mins) min straight — take a break"
            }
            let left = restThreshold - elapsed.truncatingRemainder(dividingBy: restThreshold)
            let mins = max(1, Int(left / 60))
            return language == .chinese
                ? "已连续连接 · 距下次休息 \(mins) 分钟"
                : "Connected · next break in \(mins) min"
        }

        return L10n.t(.connectedFor, language)
    }
}

/// 未连接时的空环：显示今日累计与目标进度
struct IdleRing: View {
    var todayTotal: TimeInterval
    var goal: TimeInterval
    var lastSession: TimeInterval?
    var language: AppLanguage

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, todayTotal / goal)
    }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.Palette.surface2, lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.Palette.mintDim, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: Theme.Spacing.s) {
                Text(L10n.t(.todayTotal, language))
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Palette.muted)
                Text(DurationText.clock(todayTotal))
                    .font(Theme.Font.display)
                    .foregroundStyle(Theme.Palette.text)
                if let lastSession, lastSession > 0 {
                    Text("\(L10n.t(.lastSession, language)) \(DurationText.compactClock(lastSession))")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Palette.dim)
                } else {
                    Text(L10n.t(.wearHeadphonesToStart, language))
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Palette.dim)
                }
            }
        }
        .frame(width: 252, height: 252)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(L10n.t(.todayTotal, language)) \(DurationText.human(todayTotal, language))"
        )
    }
}
