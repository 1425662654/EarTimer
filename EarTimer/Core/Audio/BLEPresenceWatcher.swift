import Foundation
import CoreBluetooth
import Observation
import os

/// 可选的第二检测通道：**用 CoreBluetooth 观察「非苹果」的可连接 BLE 耳机**。
///
/// # 它能做什么
/// 对耳机自己的 App（Sony / JBL / Bose / Nothing 等）控制的那些耳机，
/// 设备会保持 BLE 外设连接；本 App 连上同一个外设后可以收到 disconnect 回调。
/// 配合 `CBCentralManagerOptionRestoreIdentifierKey` + `bluetooth-central` 后台模式，
/// 系统甚至能在 App 被回收后把它拉到后台跑一小段，用来补一条时间戳。
///
/// # 它对 AirPods 为什么没用
/// AirPods 建立经典蓝牙（A2DP）连接后会**停止 BLE 广播**，且不会作为普通外设
/// 暴露给第三方 App 的 CoreBluetooth 会话。所以这个通道对 AirPods 静默失效，
/// 主通道永远是「快捷指令自动化」。
///
/// # 它什么时候会被关掉
/// - 用户没连过任何 BLE 耳机（默认空）
/// - 系统拒绝（无权限 / 蓝牙关闭）
/// 任何失败都只记日志，绝不影响主功能。
@MainActor
@Observable
final class BLEPresenceWatcher: NSObject {

    /// 用户已经配对、想被监听的 BLE 外设 UUID（字符串）
    private(set) var watching: Set<UUID> = []
    private(set) var lastEventAt: Date?
    private(set) var isDegraded = false

    /// 回调：(是否连上, 设备名)
    var onEvent: (@MainActor (Bool, String) -> Void)?

    @ObservationIgnored private var central: CBCentralManager?
    @ObservationIgnored private var known: [UUID: String] = [:]
    @ObservationIgnored private let log = Logger(subsystem: "com.yg.eartimer", category: "BLE")
    @ObservationIgnored private let restoreID = "com.yg.eartimer.ble.restore"

    private var started = false

    func start() {
        guard !started else { return }
        started = true
        // 带 RestoreIdentifierKey：App 被系统回收后，若外设断连仍可能被拉起
        central = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionRestoreIdentifierKey: restoreID]
        )
    }

    func stop() {
        central?.stopScan()
        central = nil
        started = false
    }

    /// 记录用户希望被监听的设备（由「我的设备」页在用户主动添加时调用）
    func watch(_ id: UUID, name: String) {
        watching.insert(id)
        known[id] = name
        if let peripheral = central?.retrievePeripherals(withIdentifiers: [id]).first {
            central?.connect(peripheral)
        }
    }

    private func handleConnected(_ peripheral: CBPeripheral) {
        let name = peripheral.name ?? known[peripheral.identifier] ?? "蓝牙耳机"
        known[peripheral.identifier] = name
        lastEventAt = .now
        log.info("BLE connected: \(name, privacy: .public)")
        if watching.contains(peripheral.identifier) {
            onEvent?(true, name)
        }
    }

    private func handleDisconnected(_ peripheral: CBPeripheral) {
        let name = known[peripheral.identifier] ?? peripheral.name ?? "蓝牙耳机"
        lastEventAt = .now
        log.info("BLE disconnected: \(name, privacy: .public)")
        if watching.contains(peripheral.identifier) {
            onEvent?(false, name)
            // 断连后重连监听，等下一次
            if let peripheral = central?.retrievePeripherals(withIdentifiers: [peripheral.identifier]).first {
                central?.connect(peripheral)
            }
        }
    }
}

extension BLEPresenceWatcher: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        let isOn = state == .poweredOn
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard isOn else {
                // 蓝牙关闭 / 未授权：静默降级，不打扰用户
                self.isDegraded = true
                self.log.notice("BLE unavailable: \(state.rawValue)")
                return
            }
            self.isDegraded = false
            // 只重连已知设备，不做全量扫描（扫描更耗电，且对 AirPods 无意义）
            let ids = Array(self.watching)
            guard !ids.isEmpty else { return }
            for peripheral in central.retrievePeripherals(withIdentifiers: ids) {
                central.connect(peripheral)
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        let id = peripheral.identifier
        let name = peripheral.name
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.known[id] = name ?? self.known[id] ?? "蓝牙耳机"
            self.handleConnected(peripheral)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.handleDisconnected(peripheral)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        willRestoreState dict: [String: Any]
    ) {
        // 系统把 App 从后台拉起：恢复待处理的连接
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        let ids = peripherals.map(\.identifier)
        Task { @MainActor [weak self] in
            guard let self else { return }
            for id in ids { self.watching.insert(id) }
            self.log.notice("BLE state restored, \(ids.count) peripheral(s)")
        }
    }
}
