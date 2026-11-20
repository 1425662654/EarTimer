import Foundation

extension Calendar {
    /// 统一用「本地自然日」切分统计，避免 UTC 跨日错位。
    /// 放在 Shared 里，因为 Widget / Intents 的时长文案也要用它判断「今天 / 昨天」。
    static var app: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        cal.locale = Locale(identifier: "zh_CN")
        cal.firstWeekday = 2   // 周一为首日，符合国内习惯
        return cal
    }
}
