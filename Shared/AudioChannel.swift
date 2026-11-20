import AVFoundation

/// 同一只耳机可能以不同「通道」出现在系统里：听歌走 A2DP，通话走 HFP。
/// 设备不变、通道会变，所以通道是会话的属性，不是设备的标识。
enum AudioChannel: String, Codable, CaseIterable, Sendable {
    case music
    case call
    case lowEnergy
    case wired
    case other

    init(portType: AVAudioSession.Port) {
        switch portType {
        case .bluetoothA2DP: self = .music
        case .bluetoothHFP: self = .call
        case .bluetoothLE: self = .lowEnergy
        case .headphones: self = .wired
        case .usbAudio: self = .other
        default: self = .other
        }
    }

    /// 显示名跟随 App 内语言
    func title(_ language: AppLanguage) -> String {
        let key: L10n.Key
        switch self {
        case .music: key = .channelMusic
        case .call: key = .channelCall
        case .lowEnergy: key = .channelLowEnergy
        case .wired: key = .channelWired
        case .other: key = .channelOther
        }
        return L10n.t(key, language)
    }

    /// 是否算作「耳机类输出」，用于判定连接中
    var isHeadphone: Bool {
        switch self {
        case .music, .call, .lowEnergy, .wired: true
        case .other: false
        }
    }

    var isWireless: Bool {
        switch self {
        case .music, .call, .lowEnergy: true
        case .wired, .other: false
        }
    }
}
