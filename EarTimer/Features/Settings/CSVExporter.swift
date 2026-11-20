import Foundation

/// 把记录导出成 CSV。字段顺序固定，方便用户用 Numbers / Excel 二次分析。
/// UTF-8 BOM 是为了让 Windows 版 Excel 正确识别中文与中文设备名。
enum CSVExporter {
    static func write(
        records: [SessionRecord],
        language: AppLanguage,
        fileName: String? = nil
    ) -> URL? {
        let header: String
        switch language {
        case .english:
            header = "Device,Channel,Start,End,Seconds,Duration,Source,Estimated,HadCall,Note\n"
        case .chinese:
            header = "设备,通道,开始时间,结束时间,时长秒,时长,来源,推算,含通话,备注\n"
        }

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current

        let yes = language == .english ? "Yes" : "是"
        let no = language == .english ? "No" : "否"

        let body = records.map { row -> String in
            let end = row.endedAt.map { formatter.string(from: $0) } ?? ""
            let fields = [
                escape(row.deviceName),
                row.channel.title(language),
                formatter.string(from: row.startedAt),
                end,
                String(Int(row.duration())),
                DurationText.human(row.duration(), language),
                row.source.title(language),
                row.isEstimated ? yes : no,
                row.hadCall ? yes : no,
                escape(row.note ?? "")
            ]
            return fields.joined(separator: ",")
        }.joined(separator: "\n")

        let stamp = Date.now.formatted(.iso8601.year().month().day())
        let name = fileName ?? "EarTimer-\(stamp).csv"
        let url = FileManager.default.temporaryDirectory.appending(path: name)
        let content = "\u{FEFF}" + header + body
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
