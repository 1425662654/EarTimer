import SwiftUI

/// 设备状态卡：名称、通道、呼吸点、断开按钮
struct DeviceCard: View {
    var state: HeadphoneState
    var language: AppLanguage
    var onTapAction: () -> Void

    @State private var pulse = false

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                .fill(Theme.Palette.mint.opacity(0.14))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.Palette.mint)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(state.isConnected ? state.deviceName : L10n.t(.notConnected, language))
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if state.isConnected {
                        Circle()
                            .fill(Theme.Palette.mint)
                            .frame(width: 6, height: 6)
                            .opacity(pulse ? 0.35 : 1)
                            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
                    }
                    Text(statusText)
                        .font(Theme.Font.caption)
                        .foregroundStyle(state.isConnected ? Theme.Palette.muted : Theme.Palette.dim)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Theme.Spacing.s)

            Button(action: onTapAction) {
                Text(state.isConnected
                     ? L10n.t(.disconnect, language)
                     : L10n.t(.manualStart, language))
                    .font(Theme.Font.micro)
                    .foregroundStyle(Theme.Palette.dim)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, 6)
                    .overlay(
                        Capsule().strokeBorder(Theme.Palette.line, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.l)
        .background(Theme.Palette.surface2, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.Palette.line, lineWidth: 1)
        )
        .onAppear { pulse = true }
    }

    private var iconName: String {
        switch state.channel {
        case .call: "phone.connection"
        case .wired: "cable.connector"
        case .lowEnergy: "dot.radiowaves.left.and.right"
        default: "airpodspro"
        }
    }

    private var statusText: String {
        guard state.isConnected else { return L10n.t(.waitingForHeadphone, language) }
        let channel = state.channel.title(language)
        switch state.source {
        case .shortcut:
            return "\(L10n.t(.connectedChannel, language)) · \(channel) · \(L10n.t(.sourceShortcut, language))"
        case .inferred, .manual:
            return "\(L10n.t(.connectedChannel, language)) · \(channel) · \(state.source.title(language))"
        default:
            return "\(L10n.t(.connectedChannel, language)) · \(channel)"
        }
    }
}
