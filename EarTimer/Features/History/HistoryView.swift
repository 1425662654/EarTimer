import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(StatsStore.self) private var stats
    @Environment(LanguageStore.self) private var lang
    @Query(sort: \SessionRecord.startedAt, order: .reverse) private var allRecords: [SessionRecord]

    @State private var scope: Scope = .week
    @State private var editing: SessionRecord?

    private var language: AppLanguage { lang.language }
    private func t(_ key: L10n.Key) -> String { L10n.t(key, language) }

    enum Scope: String, CaseIterable, Identifiable {
        case week, month, all
        var id: String { rawValue }

        func title(_ language: AppLanguage) -> String {
            switch self {
            case .week: L10n.t(.thisWeek, language)
            case .month: L10n.t(.thisMonth, language)
            case .all: L10n.t(.allTime, language)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    summary
                    barChart
                    groupedList
                }
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Theme.Palette.bg)
            .scrollIndicators(.hidden)
            .navigationTitle(t(.tabHistory))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker(t(.tabHistory), selection: $scope) {
                            ForEach(Scope.allCases) { item in
                                Text(item.title(language)).tag(item)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(scope.title(language))
                            Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold))
                        }
                        .font(Theme.Font.micro)
                        .foregroundStyle(Theme.Palette.muted)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.Palette.surface2))
                    }
                }
            }
            .sheet(item: $editing) { record in
                SessionDetailSheet(record: record)
            }
        }
        .task { stats.refresh() }
    }

    // MARK: - 汇总

    private var summary: some View {
        let intervals = scopedIntervals
        let total = intervals.reduce(0.0) { sum, interval in
            sum + scopedRecords.reduce(0.0) { $0 + $1.overlap(with: interval) }
        }
        let days = max(1, intervals.count)
        let avg = total / Double(days)
        return HStack(spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(scope.title(language))
                    .font(Theme.Font.micro)
                    .foregroundStyle(Theme.Palette.dim)
                Text(DurationText.human(total, language))
                    .font(Theme.Font.monoMedium)
                    .foregroundStyle(Theme.Palette.text)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(t(.dailyAverage))
                    .font(Theme.Font.micro)
                    .foregroundStyle(Theme.Palette.dim)
                Text(DurationText.human(avg, language))
                    .font(Theme.Font.monoMedium)
                    .foregroundStyle(Theme.Palette.text)
            }
        }
        .padding(.vertical, Theme.Spacing.s)
    }

    /// 当前范围覆盖的日期区间；用于精确统计跨零点会话
    private var scopedIntervals: [DateInterval] {
        switch scope {
        case .week:
            let week = DayBounds.interval(ofWeekContaining: .now)
            return (0..<7).compactMap { offset in
                Calendar.app.date(byAdding: .day, value: offset, to: week.start)
                    .map { DayBounds.interval(ofDayContaining: $0) }
            }
        case .month:
            return DayBounds.recentDays(30).map { DayBounds.interval(ofDayContaining: $0) }
        case .all:
            let days = Set(allRecords.map { Calendar.app.startOfDay(for: $0.startedAt) })
            return days.sorted().map { DayBounds.interval(ofDayContaining: $0) }
        }
    }

    private var scopedRecords: [SessionRecord] {
        let bounds = scopedIntervals
        guard let first = bounds.first, let last = bounds.last else { return [] }
        let window = DateInterval(start: first.start, end: last.end)
        return allRecords.filter { $0.startedAt < window.end && ($0.endedAt ?? .now) > window.start }
    }

    // MARK: - 柱状图

    private var barChart: some View {
        let data = stats.dailyTotals
        let maxValue = max(data.map(\.seconds).max() ?? 0, 1)
        return VStack(spacing: Theme.Spacing.m) {
            HStack(alignment: .bottom, spacing: Theme.Spacing.s) {
                ForEach(data) { item in
                    let ratio = item.seconds / maxValue
                    VStack(spacing: 6) {
                        Text(item.seconds > 0 ? DurationText.tight(item.seconds) : " ")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.Palette.dim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Theme.Palette.mint.opacity(0.35 + 0.65 * ratio))
                            .frame(height: max(6, 84 * ratio))
                        Text(DurationText.weekdayNarrow(item.day, language))
                            .font(Theme.Font.micro)
                            .foregroundStyle(Calendar.app.isDateInToday(item.day)
                                             ? Theme.Palette.mint
                                             : Theme.Palette.dim)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "\(DurationText.dayHeader(item.day, language)) \(DurationText.human(item.seconds, language))"
                    )
                }
            }
            .frame(height: 130, alignment: .bottom)
        }
    }

    // MARK: - 分组列表

    private var groupedList: some View {
        let groups = Dictionary(grouping: visibleRecords) {
            Calendar.app.startOfDay(for: $0.startedAt)
        }
        let days = groups.keys.sorted(by: >)
        return VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            ForEach(days, id: \.self) { day in
                let rows = groups[day] ?? []
                let dayInterval = DayBounds.interval(ofDayContaining: day)
                let total = rows.reduce(0.0) { $0 + $1.overlap(with: dayInterval) }
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(DurationText.dayHeader(day, language))
                            .font(Theme.Font.micro)
                            .foregroundStyle(Theme.Palette.dim)
                        Spacer()
                        Text(DurationText.human(total, language))
                            .font(Theme.Font.micro)
                            .foregroundStyle(Theme.Palette.dim)
                    }
                    .padding(.bottom, Theme.Spacing.xs)

                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            Button {
                                editing = row
                            } label: {
                                SessionRow(record: row, language: language)
                            }
                            .buttonStyle(.plain)
                            if index < rows.count - 1 {
                                HairLine().padding(.leading, 44)
                            }
                        }
                    }
                }
            }

            if days.isEmpty {
                ContentUnavailableView(
                    t(.historyEmptyTitle),
                    systemImage: "airpodspro",
                    description: Text(t(.historyEmptyBody))
                )
                .foregroundStyle(Theme.Palette.dim)
            }
        }
    }

    private var visibleRecords: [SessionRecord] {
        Array(scopedRecords.prefix(200))
    }
}
