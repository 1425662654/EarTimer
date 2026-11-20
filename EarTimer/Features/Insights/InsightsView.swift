import SwiftUI

struct InsightsView: View {
    @Environment(StatsStore.self) private var stats
    @Environment(SettingsStore.self) private var settings
    @Environment(LanguageStore.self) private var lang

    private var language: AppLanguage { lang.language }
    private func t(_ key: L10n.Key) -> String { L10n.t(key, language) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    headlineStats
                    heatmapCard
                    deviceCard
                    hourCard
                    loadCard
                }
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Theme.Palette.bg)
            .scrollIndicators(.hidden)
            .navigationTitle(t(.tabInsights))
            .navigationBarTitleDisplayMode(.large)
        }
        .task { stats.refresh() }
    }

    private var headlineStats: some View {
        HStack(spacing: Theme.Spacing.m) {
            tile(t(.insightsCumulative), DurationText.human(stats.snapshot.allTimeTotal, language))
            tile(t(.insightsLongest), DurationText.human(stats.snapshot.longestSession, language))
            tile(t(.insightsStreak), "\(stats.snapshot.currentStreakDays)\(t(.streakUnit))")
        }
    }

    private func tile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.Font.micro)
                .foregroundStyle(Theme.Palette.dim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(Theme.Font.monoMedium)
                .foregroundStyle(Theme.Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.l)
        .background(Theme.Palette.surface2, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .strokeBorder(Theme.Palette.line, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - 热力

    private var heatmapCard: some View {
        let maxValue = max(stats.heatmap.map(\.seconds).max() ?? 0, 1)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
        return CardSurface {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text(t(.insightsHeatmap))
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Palette.text)

                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(stats.heatmap) { item in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(heatColor(item.seconds, max: maxValue))
                            .aspectRatio(1, contentMode: .fit)
                            .accessibilityLabel(
                                "\(DurationText.dayHeader(item.day, language)) \(DurationText.human(item.seconds, language))"
                            )
                    }
                }

                HStack(spacing: 4) {
                    Text(t(.heatmapLess)).font(Theme.Font.micro).foregroundStyle(Theme.Palette.dim)
                    ForEach(0..<5, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Palette.mint.opacity(0.12 + 0.22 * Double(i)))
                            .frame(width: 12, height: 12)
                    }
                    Text(t(.heatmapMore)).font(Theme.Font.micro).foregroundStyle(Theme.Palette.dim)
                    Spacer()
                }
            }
        }
    }

    private func heatColor(_ seconds: TimeInterval, max maxValue: TimeInterval) -> Color {
        guard seconds > 0 else { return Theme.Palette.surface }
        let ratio = min(1, seconds / maxValue)
        return Theme.Palette.mint.opacity(0.18 + 0.82 * ratio)
    }

    // MARK: - 按设备

    private var deviceCard: some View {
        let total = max(stats.deviceTotals.reduce(0.0) { $0 + $1.seconds }, 1)
        return CardSurface {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack(spacing: 6) {
                    Text(t(.insightsByDevice))
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Palette.text)
                    Text(t(.insightsByDeviceWindow))
                        .font(Theme.Font.micro)
                        .foregroundStyle(Theme.Palette.dim)
                }

                if stats.deviceTotals.isEmpty {
                    Text(t(.noDeviceData))
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Palette.dim)
                } else {
                    ForEach(Array(stats.deviceTotals.enumerated()), id: \.element.id) { index, device in
                        VStack(spacing: 6) {
                            HStack {
                                Text(device.name)
                                    .font(Theme.Font.body)
                                    .foregroundStyle(Theme.Palette.text)
                                    .lineLimit(1)
                                Spacer()
                                Text(DurationText.human(device.seconds, language))
                                    .font(Theme.Font.monoSmall)
                                    .foregroundStyle(Theme.Palette.muted)
                            }
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Theme.Palette.surface)
                                    Capsule()
                                        .fill(Theme.accent(index))
                                        .frame(width: proxy.size.width * (device.seconds / total))
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 时段分布

    private var hourCard: some View {
        let maxValue = max(stats.hourBuckets.map(\.seconds).max() ?? 0, 1)
        return CardSurface {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text(t(.insightsHourDistribution))
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Palette.text)

                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(stats.hourBuckets) { bucket in
                        let ratio = bucket.seconds / maxValue
                        Capsule()
                            .fill(bucket.seconds > 0
                                  ? Theme.Palette.mint.opacity(0.35 + 0.65 * ratio)
                                  : Theme.Palette.surface)
                            .frame(maxWidth: .infinity)
                            .frame(height: max(3, 56 * ratio))
                            .accessibilityLabel("\(bucket.hour)\(t(.hourAxisSuffix))")
                    }
                }
                .frame(height: 60, alignment: .bottom)

                HStack {
                    ForEach([0, 6, 12, 18, 23], id: \.self) { h in
                        Text("\(h)")
                            .font(Theme.Font.micro)
                            .foregroundStyle(Theme.Palette.dim)
                        if h != 23 { Spacer() }
                    }
                }
            }
        }
    }

    // MARK: - 听力负荷

    private var loadCard: some View {
        let budget = settings.dailyBudget
        let ratio = budget > 0 ? min(1.4, stats.snapshot.todayTotal / budget) : 0
        return CardSurface {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack {
                    Text(t(.insightsTodayLoad))
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Palette.text)
                    Spacer()
                    MetaChip(text: loadLabel(ratio), tint: loadColor(ratio))
                }
                Text(loadAdvice(ratio))
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(segmentColor(i, ratio: ratio))
                            .frame(maxWidth: .infinity)
                            .frame(height: 6)
                    }
                }
                .accessibilityHidden(true)
            }
        }
    }

    private func segmentColor(_ index: Int, ratio: Double) -> Color {
        let palette = [Theme.Palette.mint, Theme.Palette.amber, Theme.Palette.danger]
        let lit = ratio * 3
        return palette[index].opacity(Double(index) < lit ? 0.95 : 0.16)
    }

    private func loadLabel(_ ratio: Double) -> String {
        switch ratio {
        case ..<0.5: t(.loadComfortable)
        case ..<0.85: t(.loadNormal)
        case ..<1.0: t(.loadNearLimit)
        default: t(.loadOver)
        }
    }

    private func loadColor(_ ratio: Double) -> Color {
        switch ratio {
        case ..<0.85: Theme.Palette.mint
        case ..<1.0: Theme.Palette.amber
        default: Theme.Palette.danger
        }
    }

    private func loadAdvice(_ ratio: Double) -> String {
        switch ratio {
        case ..<0.5: t(.loadAdviceComfortable)
        case ..<0.85: t(.loadAdviceNormal)
        case ..<1.0: t(.loadAdviceNear)
        default: t(.loadAdviceOver)
        }
    }
}
