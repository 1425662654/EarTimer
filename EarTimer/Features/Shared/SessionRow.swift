import SwiftUI

/// 一条会话记录行。列表 / 首页 / 设备详情共用。
struct SessionRow: View {
    var record: SessionRecord
    var language: AppLanguage
    var showsDate: Bool = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            HStack(spacing: Theme.Spacing.m) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.color(for: record.channel).opacity(0.14))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.color(for: record.channel))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(record.deviceName)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Palette.text)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(timeText(now: context.date))
                            .lineLimit(1)
                        if record.isOpen {
                            Text(L10n.t(.badgeInProgress, language))
                                .foregroundStyle(Theme.Palette.mint)
                        }
                    }
                    .font(Theme.Font.micro)
                    .foregroundStyle(Theme.Palette.dim)
                }

                Spacer(minLength: Theme.Spacing.s)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(DurationText.compactClock(record.duration(now: context.date)))
                        .font(Theme.Font.monoSmall)
                        .foregroundStyle(Theme.Palette.text)

                    if record.isOpen {
                        MetaChip(text: L10n.t(.badgeInProgress, language), tint: Theme.Palette.mint)
                    } else if record.isEstimated {
                        MetaChip(text: L10n.t(.badgeEstimated, language), tint: Theme.Palette.amber)
                    } else if record.hadCall {
                        MetaChip(text: L10n.t(.badgeHadCall, language), tint: Theme.Palette.indigo)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.m)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText(duration: record.duration(now: context.date)))
        }
    }

    private func timeText(now: Date) -> String {
        let range = DurationText.range(record.startedAt, record.endedAt ?? now, language)
        guard showsDate else { return range }
        let day = record.startedAt.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted, locale: language == .chinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US"))
        )
        return "\(day) \(range)"
    }

    private var icon: String {
        if record.hadCall { return "phone.fill" }
        switch record.channel {
        case .music: return "music.note"
        case .call: return "phone.fill"
        case .lowEnergy: return "dot.radiowaves.left.and.right"
        case .wired: return "cable.connector"
        case .other: return "headphones"
        }
    }

    private func accessibilityText(duration: TimeInterval) -> String {
        var parts = [record.deviceName, DurationText.human(duration, language)]
        if record.isOpen { parts.append(L10n.t(.badgeInProgress, language)) }
        if record.isEstimated { parts.append(L10n.t(.badgeEstimated, language)) }
        return parts.joined(separator: ", ")
    }
}
