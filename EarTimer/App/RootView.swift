import SwiftUI

struct RootView: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(StatsStore.self) private var stats
    @Environment(AudioRouteObserver.self) private var observer
    @Environment(LanguageStore.self) private var lang
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab = .home
    @State private var showSetupGuide = false

    private var language: AppLanguage { lang.language }
    private func t(_ key: L10n.Key) -> String { L10n.t(key, language) }

    var body: some View {
        TabView(selection: $tab) {
            Tab(t(.tabHome), systemImage: "timer", value: AppTab.home) {
                HomeView()
            }
            Tab(t(.tabHistory), systemImage: "list.bullet.rectangle", value: AppTab.history) {
                HistoryView()
            }
            Tab(t(.tabInsights), systemImage: "chart.bar.xaxis", value: AppTab.insights) {
                InsightsView()
            }
            Tab(t(.tabSettings), systemImage: "slider.horizontal.3", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tint(Theme.Palette.mint)
        .preferredColorScheme(.dark)
        .background(Theme.Palette.bg)
        .fullScreenCover(isPresented: $showSetupGuide) {
            SetupGuideView()
        }
        .task {
            // 首次启动必看引导：不配自动化就没有准确数据，这件事不能藏
            let done = SharedDefaults.suite.bool(forKey: SharedDefaults.Keys.guideCompleted)
            let requested = SharedDefaults.suite.bool(forKey: SharedDefaults.Keys.showSetupGuide)
            if !done || requested {
                SharedDefaults.suite.set(false, forKey: SharedDefaults.Keys.showSetupGuide)
                showSetupGuide = true
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                engine.syncOnForeground(observer: observer)
                stats.refresh()
            case .background:
                // 进后台时把已知状态落盘，供 Widget 显示
                SharedDefaults.writeState(engine.state)
            default:
                break
            }
        }
    }
}

enum AppTab: Hashable {
    case home, history, insights, settings
}
