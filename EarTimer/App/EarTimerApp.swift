import SwiftUI
import SwiftData

@main
@MainActor
struct EarTimerApp: App {
    @State private var observer = AudioRouteObserver()
    @State private var stats = StatsStore()
    @State private var ble = BLEPresenceWatcher()

    /// 存储位置由 StorageLocator 决定：
    /// App Group 可用就用它（Widget 能共享），否则退回本机沙盒。
    /// 直接写 `groupContainer:` 会在 entitlements 缺失时 fatalError，那个接不住。
    private let container: ModelContainer = StorageLocator.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(observer)
                .environment(stats)
                .environment(ble)
                .environment(LanguageStore.shared)
                .environment(SessionEngine.shared)
                .environment(SettingsStore.shared)
                .task {
                    stats.attach(context: container.mainContext)
                    SessionEngine.shared.configure(context: container.mainContext, observer: observer)
                    SessionEngine.shared.start()
                    stats.refresh()
                    await ReminderScheduler.shared.requestAuthorization()
                    startOptionalBLEChannel()
                }
        }
        .modelContainer(container)
    }

    /// BLE 通道是可选增强，只对非苹果 BLE 耳机有效；失败静默降级。
    private func startOptionalBLEChannel() {
        ble.onEvent = { connected, name in
            SessionEngine.shared.handleBLEEvent(connected: connected, name: name)
        }
        ble.start()
    }
}
