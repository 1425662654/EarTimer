import Foundation
import AVFoundation
import Observation
import os

/// 当前挂在系统上的音频输出设备。
struct AudioOutputDevice: Equatable, Sendable {
    var name: String
    var portType: AVAudioSession.Port
    var uid: String
    var channel: AudioChannel

    /// 规范化 key：蓝牙设备的 UID 会随重连变化，名称通常稳定，所以用「名称 + 通道族」。
    /// 有线设备的 UID 稳定，直接用 UID。
    var key: String {
        let family = channel.isWireless ? "bt" : "wired"
        let normalized = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return "\(family)://\(normalized)"
    }
}

/// 音频路由的唯一观察点。
///
/// 设计约束（很重要）：
/// - `.routeChangeNotification` 只在「有 App 在跑 / 刚被唤起」时到达，App 被杀后不会补发。
/// - 所以这里的值永远只是「当前真值」，不是「历史真值」。补历史必须靠心跳 + 快捷指令。
@MainActor
@Observable
final class AudioRouteObserver {
    private(set) var current: AudioOutputDevice?
    private(set) var lastChangeAt: Date = .now

    /// 每次真实路由变化都会回调一次，带旧值与新值
    var onChange: (@MainActor (AudioOutputDevice?, AudioOutputDevice?) -> Void)?

    private let session = AVAudioSession.sharedInstance()
    private var observers: [NSObjectProtocol] = []
    private let log = Logger(subsystem: "com.yg.eartimer", category: "Route")

    private(set) var isObserving = false

    func start() {
        guard !isObserving else { return }
        isObserving = true
        refresh(notify: false)

        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: session,
                queue: .main
            ) { [weak self] note in
                let reasonRaw = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt) ?? 0
                let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw) ?? .unknown
                Task { @MainActor in
                    self?.handle(reason: reason)
                }
            }
        )

        // 媒体服务被重置（拔插、蓝牙栈重启）时，路由信息同样会变
        observers.append(
            center.addObserver(
                forName: AVAudioSession.mediaServicesWereResetNotification,
                object: session,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refresh(notify: true) }
            }
        )
    }

    func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        isObserving = false
    }

    /// 让路由会话处于可观察状态。不播放音频时也必须 activate，
    /// 否则首次冷启动读到的 currentRoute 可能还是内置扬声器。
    func activateSession() {
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            log.error("session activate failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func deactivateSession() {
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func handle(reason: AVAudioSession.RouteChangeReason) {
        // .categoryChange / .override 是 App 自己切分类导致的抖动，不算耳机事件
        switch reason {
        case .categoryChange, .override, .unknown:
            return
        default:
            break
        }
        refresh(notify: true)
    }

    func refresh(notify: Bool) {
        let outputs = session.currentRoute.outputs
        var next = outputs
            .map { AudioOutputDevice(name: $0.portName, portType: $0.portType, uid: $0.uid, channel: AudioChannel(portType: $0.portType)) }
            .first(where: { $0.channel.isHeadphone })

        // 有线耳机默认不计，除非用户在设置里打开
        if let wired = next, wired.channel == .wired, !SettingsStore.shared.includeWired {
            next = nil
        }

        guard next != current else { return }
        let previous = current
        current = next
        lastChangeAt = .now
        log.debug("route: \(previous?.name ?? "内置", privacy: .public) → \(next?.name ?? "内置", privacy: .public)")
        if notify {
            onChange?(previous, next)
        }
    }

    /// 会话被系统打断（来电、Siri、其他 App 抢占）时，告诉上层别忘了标记通话
    func systemVolume() -> Double {
        Double(session.outputVolume)
    }
}
