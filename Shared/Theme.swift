import SwiftUI

/// 设计令牌。所有颜色 / 间距 / 圆角只从这里取，视图里不出现字面量。
/// 气质：安静的音频仪表盘 —— 深色底、细线、单一薄荷强调色。
enum Theme {

    // MARK: - Color

    enum Palette {
        static let bg = Color(hex: 0x07090A)
        static let surface = Color(hex: 0x12181A)
        static let surface2 = Color(hex: 0x1A2225)
        static let line = Color(hex: 0x232D30)
        static let text = Color(hex: 0xEEF4F3)
        static let muted = Color(hex: 0x8A9C99)
        static let dim = Color(hex: 0x5C6B69)

        static let mint = Color(hex: 0x4FE3C1)
        static let mintDim = Color(hex: 0x2A8E7C)
        static let indigo = Color(hex: 0x7C8CFF)
        static let amber = Color(hex: 0xFFB86B)
        static let danger = Color(hex: 0xFF6B6B)
    }

    /// 设备点缀色轮转，索引来自 DeviceProfile.accentIndex
    static let accents: [Color] = [
        Palette.mint, Palette.indigo, Palette.amber,
        Palette.mintDim, Palette.danger, Palette.muted
    ]

    static func accent(_ index: Int) -> Color {
        accents[((index % accents.count) + accents.count) % accents.count]
    }

    /// 通道徽章用的颜色
    static func color(for channel: AudioChannel) -> Color {
        switch channel {
        case .music: Palette.mint
        case .call: Palette.indigo
        case .lowEnergy: Palette.amber
        case .wired: Palette.muted
        case .other: Palette.dim
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        static let screen: CGFloat = 20
    }

    enum Radius {
        static let card: CGFloat = 22
        static let control: CGFloat = 14
        static let chip: CGFloat = 999
        static let small: CGFloat = 10
    }

    // MARK: - Type

    enum Font {
        static let display = SwiftUI.Font.system(size: 54, weight: .semibold, design: .rounded).monospacedDigit()
        static let monoLarge = SwiftUI.Font.system(size: 34, weight: .semibold, design: .monospaced)
        static let monoMedium = SwiftUI.Font.system(size: 20, weight: .semibold, design: .monospaced)
        static let monoSmall = SwiftUI.Font.system(size: 14, weight: .medium, design: .monospaced)
        static let title = SwiftUI.Font.system(size: 28, weight: .bold)
        static let headline = SwiftUI.Font.system(size: 17, weight: .semibold)
        static let body = SwiftUI.Font.system(size: 15, weight: .regular)
        static let caption = SwiftUI.Font.system(size: 13, weight: .regular)
        static let micro = SwiftUI.Font.system(size: 11, weight: .medium)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - Reusable surfaces

/// 卡片容器：统一圆角 / 描边 / 内边距
struct CardSurface<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.xl
    var fill: Color = Theme.Palette.surface2
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.Palette.line, lineWidth: 1)
            )
    }
}

/// 小徽章：通道 / 推算 / 数据源
struct MetaChip: View {
    var text: String
    var tint: Color
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(Theme.Font.micro)
            .foregroundStyle(filled ? Theme.Palette.bg : tint)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(filled ? tint : tint.opacity(0.14))
            )
    }
}

/// 1px 分隔线（用矩形画，避免 Divider 在不同容器里的缩进差异）
struct HairLine: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Palette.line)
            .frame(height: 1)
    }
}
