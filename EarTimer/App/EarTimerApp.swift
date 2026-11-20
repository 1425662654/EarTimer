import SwiftUI
import SwiftData

@main
@MainActor
struct EarTimerApp: App {
    @State private var observer = AudioRouteObserver()
    @State private var stats = StatsStore()
    @State private var ble = BLEPresenceWatcher()

    private let container: ModelContainer = {
        let schema = Schema([SessionRecord.self, DeviceProfile.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(SharedDefaults.appGroup),
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // 落盘失败（极少见）就退回内存库，至少让 UI 可用
            return try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
        }
    }()

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
