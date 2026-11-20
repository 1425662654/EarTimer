import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(StatsStore.self) private var stats
    @Environment(SettingsStore.self) private var settings
    @Environment(LanguageStore.self) private var lang
    @Query(sort: \SessionRecord.startedAt, order: .reverse) private var allRecords: [SessionRecord]
    @State private var showWearHint = false
    @State private var showSettings = false

    private var language: AppLanguage { lang.language }
    private func t(_ key: L10n.Key) -> String { L10n.t(key, language) }

    private var todayRows: [SessionRecord] {
        let interval = DayBounds.interval(ofDayContaining: .now)
        return allRecords.filter { $0.overlap(with: interval) > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    DeviceCard(state: engine.state, language: language) {
                        engine.toggleManually()
                        stats.refresh(state: engine.state)
                    }

                    ringSection
                    metricsRow
                    goalRow

                    if showWearHint {
                        wearHint
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    todayList
                }
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Theme.Palette.bg)
            .scrollIndicators(.hidden)
            // 产品名固定英文，不参与本地化
            .navigationTitle("EarTimer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Palette.dim)
                    }
                    .accessibilityLabel(t(.settingsTitle))
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .task {
            stats.refresh(state: engine.state)
            evaluateWearHint()
        }
        .onChange(of: engine.state.isConnected) { _, _ in
            withAnimation(.snappy) {
                stats.refresh(state: engine.state)
                evaluateWearHint()
            }
        }
    }

    @ViewBuilder
    private var ringSection: some View {
        if let start = engine.state.sessionStartedAt {
            SessionRing(
                startedAt: start,
                todayBefore: engine.state.todayAccumulated,
                goal: settings.dailyBudget,
                isEstimated: engine.state.source.isEstimated,
                restThreshold: settings.continuousWearThreshold,
                language: language
            )
            .padding(.top, Theme.Spacing.s)
        } else {
            IdleRing(
                todayTotal: stats.snapshot.todayTotal,
                goal: settings.dailyBudget,
                lastSession: lastClosedDuration,
                language: language
            )
            .padding(.top, Theme.Spacing.s)
        }
    }

    /// 最近一条已结束记录的时长，用于空环下方那行小字
    private var lastClosedDuration: TimeInterval? {
        allRecords.first(where: { !$0.isOpen }).map { $0.duration() }
    }

    private var metricsRow: some View {
        HStack(spacing: 0) {
            metric(label: t(.todayTotal), value: DurationText.human(stats.snapshot.todayTotal, language))
            Rectangle().fill(Theme.Palette.line).frame(width: 1, height: 32)
            metric(
                label: t(.sessionElapsed),
                value: engine.state.isConnected
                    ? DurationText.clock(engine.state.elapsed(), showHoursAlways: false)
                    : L10n.t(.placeholder, language)
            )
            Rectangle().fill(Theme.Palette.line).frame(width: 1, height: 32)
            metric(
                label: t(.todayRemaining),
                value: settings.dailyBudget > 0
                    ? DurationText.short(max(0, settings.dailyBudget - stats.snapshot.todayTotal), language)
                    : t(.goalUnset)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func metric(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Theme.Font.micro)
                .foregroundStyle(Theme.Palette.dim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(Theme.Font.monoMedium)
                .foregroundStyle(Theme.Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    private var goalRow: some View {
        VStack(spacing: Theme.Spacing.s) {
            HStack {
                Text(goalCaption)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Palette.muted)
                Spacer()
                Text("\(Int(goalRatio * 100))%")
                    .font(Theme.Font.monoSmall)
                    .foregroundStyle(Theme.Palette.mint)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Palette.surface2)
                    Capsule()
                        .fill(Theme.Palette.mint)
                        .frame(width: proxy.size.width * goalRatio)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
    }

    private var goalRatio: Double {
        guard settings.dailyBudget > 0 else { return 0 }
        return min(1, stats.snapshot.todayTotal / settings.dailyBudget)
    }

    private var goalCaption: String {
        guard settings.dailyBudget > 0 else { return t(.goalUnset) }
        let remaining = settings.dailyBudget - stats.snapshot.todayTotal
        let budget = DurationText.short(settings.dailyBudget, language)
        if remaining <= 0 {
            return "\(t(.todayGoal)) \(budget) · \(t(.goalReached))"
        }
        return "\(t(.todayGoal)) \(budget) · \(t(.goalRemaining)) \(DurationText.short(remaining, language))"
    }

    private var wearHint: some View {
        HStack(spacing: Theme.Spacing.m) {
            Circle()
                .fill(Theme.Palette.amber)
                .frame(width: 7, height: 7)
            Text(wearHintText)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Palette.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.Spacing.s)
            Button(t(.gotIt)) {
                withAnimation { showWearHint = false }
            }
            .font(Theme.Font.micro)
            .foregroundStyle(Theme.Palette.amber)
        }
        .padding(Theme.Spacing.l)
        .background(
            Theme.Palette.amber.opacity(0.09),
            in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        )
    }

    private var wearHintText: String {
        guard let start = engine.state.sessionStartedAt else {
            return L10n.t(.breakHintTitle, language)
        }
        let minutes = Int(Date.now.timeIntervalSince(start) / 60)
        return language == .chinese
            ? "已连续佩戴 \(minutes) 分钟，摘下透透气？"
            : "\(minutes) min straight. Take them off for a bit?"
    }

    private func evaluateWearHint() {
        guard let start = engine.state.sessionStartedAt, settings.continuousWearThreshold > 0 else {
            showWearHint = false
            return
        }
        showWearHint = Date.now.timeIntervalSince(start) >= settings.continuousWearThreshold
    }

    private var todayList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text(t(.todayRecords))
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Palette.text)
                Spacer()
                Text("\(todayRows.count) \(t(.recordCountSuffix))")
                    .font(Theme.Font.micro)
                    .foregroundStyle(Theme.Palette.dim)
            }

            let rows = Array(todayRows.prefix(4))
            if rows.isEmpty {
                Text(t(.emptyToday))
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Palette.dim)
                    .padding(.vertical, Theme.Spacing.l)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        SessionRow(record: row, language: language)
                        if index < rows.count - 1 {
                            HairLine().padding(.leading, 44)
                        }
                    }
                }
            }
        }
    }
}
