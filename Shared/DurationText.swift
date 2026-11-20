import Foundation

/// 时长 / 时钟的统一格式化。
///
/// 全部手写而不用 `Duration.UnitsFormatStyle`，因为：
/// ① 数字要与文案混排对齐，需要固定结构；
/// ② 单位词要在中英文之间切换（"3 h 12 m" / "3 小时 12 分"），
///    `UnitsFormatStyle` 会跟随系统语言而不是 App 内选择的语言，两者可能不一致。
enum DurationText {

    /// 01:42:36 —— 纯数字，任何语言下都相同
    static func clock(_ interval: TimeInterval, showHoursAlways: Bool = true) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h == 0 && !showHoursAlways {
            return String(format: "%02d:%02d", m, s)
        }
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// 1:42:36 —— 列表行用的紧凑版，不补零
    static func compactClock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - 本地化单位

    private static func units(_ language: AppLanguage) -> (h: String, m: String, s: String, sep: String) {
        switch language {
        case .english: ("h", "m", "s", " ")
        case .chinese: ("小时", "分", "秒", "")
        }
    }

    /// 3 h 12 m / 3 小时 12 分 —— 汇总数字
    static func human(_ interval: TimeInterval, _ language: AppLanguage) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let u = units(language)
        let h = total / 3600
        let m = (total % 3600) / 60
        switch language {
        case .english:
            if h > 0 && m > 0 { return "\(h)\(u.sep)\(u.h) \(m)\(u.sep)\(u.m)" }
            if h > 0 { return "\(h)\(u.sep)\(u.h)" }
            if m > 0 { return "\(m)\(u.sep)\(u.m)" }
            return "\(total)\(u.sep)\(u.s)"
        case .chinese:
            if h > 0 && m > 0 { return "\(h) \(u.h) \(m) \(u.m)" }
            if h > 0 { return "\(h) \(u.h)" }
            if m > 0 { return "\(m) \(u.m)" }
            return "\(total) \(u.s)"
        }
    }

    /// 剩余量、短提示
    static func short(_ interval: TimeInterval, _ language: AppLanguage) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let u = units(language)
        if total < 60 {
            return language == .english ? "\(total)\(u.sep)\(u.s)" : "\(total) \(u.s)"
        }
        let h = total / 3600
        let m = (total % 3600) / 60
        switch language {
        case .english:
            if h > 0 && m > 0 { return "\(h)\(u.sep)\(u.h) \(m)\(u.sep)\(u.m)" }
            if h > 0 { return "\(h)\(u.sep)\(u.h)" }
            return "\(m)\(u.sep)\(u.m)"
        case .chinese:
            if h > 0 && m > 0 { return "\(h) \(u.h) \(m) \(u.m)" }
            if h > 0 { return "\(h) \(u.h)" }
            return "\(m) \(u.m)"
        }
    }

    /// 小组件 / 灵动岛，空间极小，两种语言都用 1h42m
    static func tight(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h\(m)m" : "\(m)m"
    }

    // MARK: - 日期

    /// 跟随 App 内语言，而不是系统语言
    private static func locale(_ language: AppLanguage) -> Locale {
        Locale(identifier: language == .chinese ? "zh_CN" : "en_US")
    }

    static func timeOfDay(_ date: Date, _ language: AppLanguage) -> String {
        date.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened, locale: locale(language))
        )
    }

    static func range(_ start: Date, _ end: Date, _ language: AppLanguage) -> String {
        "\(timeOfDay(start, language)) – \(timeOfDay(end, language))"
    }

    /// 「今天 11月20日」/「Today Nov 20」/「Yesterday Nov 19」/「Nov 18 Mon」
    static func dayHeader(
        _ date: Date,
        _ language: AppLanguage,
        calendar: Calendar = .app,
        now: Date = .now
    ) -> String {
        let loc = locale(language)
        let monthDay = date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted, locale: loc)
                .month(.abbreviated).day()
        )
        if calendar.isDate(date, inSameDayAs: now) {
            return language == .chinese ? "今天 \(monthDay)" : "Today \(monthDay)"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return language == .chinese ? "昨天 \(monthDay)" : "Yesterday \(monthDay)"
        }
        let weekday = date.formatted(
            Date.FormatStyle(date: .omitted, time: .omitted, locale: loc).weekday(.abbreviated)
        )
        return "\(monthDay) \(weekday)"
    }

    /// 图表 X 轴：周几的单字/缩写
    static func weekdayNarrow(_ date: Date, _ language: AppLanguage) -> String {
        date.formatted(
            Date.FormatStyle(date: .omitted, time: .omitted, locale: locale(language))
                .weekday(.narrow)
        )
    }
}
