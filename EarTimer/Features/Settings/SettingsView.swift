import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SessionEngine.self) private var engine
    @Environment(StatsStore.self) private var stats
    @Environment(LanguageStore.self) private var lang
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var exportURL: URL?
    @State private var showEraseConfirm = false
    @State private var shortcutHint = false
    @State private var showSetupGuide = false

    private var language: AppLanguage { lang.language }
    private func t(_ key: L10n.Key) -> String { L10n.t(key, language) }

    /// 自动化到底有没有生效，用「最近一次会话来源」推断，比让用户自己猜好
    private var automationStatus: (text: String, hint: String, ok: Bool, color: Color) {
        let latest = (try? context.fetch(
            FetchDescriptor<SessionRecord>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        ))?.first
        guard let latest else {
            return (t(.automationNotConfigured), t(.automationHintNone), false, Theme.Palette.amber)
        }
        switch latest.source {
        case .shortcut:
            return (t(.automationActive), t(.automationHintActive), true, Theme.Palette.mint)
        case .live, .routeChange:
            return (t(.automationNotConfigured), t(.automationHintNone), false, Theme.Palette.amber)
        case .inferred, .manual:
            return (t(.automationPending), t(.automationHintPending), false, Theme.Palette.amber)
        }
    }

    var body: some View {
        NavigationStack {
            settingsForm
                .navigationTitle(t(.settingsTitle))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(t(.done)) { dismiss() }
                    }
                }
                .fullScreenCover(isPresented: $showSetupGuide) {
                    SetupGuideView()
                }
        }
    }

    private var settingsForm: some View {
        @Bindable var settings = settings
        // @Environment(Type.self) 的对象不能直接取 $ 绑定，
        // 必须先用 @Bindable 拿到投影，否则报 "cannot find '$lang' in scope"
        @Bindable var lang = lang

        return Form {
            // 语言在最上：用户第一眼就能发现可以切
            Section {
                Picker(selection: $lang.language) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.nativeName).tag(item)
                    }
                } label: {
                    Label(t(.languageLabel), systemImage: "globe")
                }
                .pickerStyle(.segmented)
            } header: {
                Text(t(.languageSection))
            } footer: {
                Text(t(.languageFooter))
            }

            Section {
                Button {
                    showSetupGuide = true
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(t(.bluetoothAutomation))
                                    .foregroundStyle(Theme.Palette.text)
                                MetaChip(
                                    text: automationStatus.text,
                                    tint: automationStatus.color,
                                    filled: automationStatus.ok
                                )
                            }
                            Text(automationStatus.hint)
                                .font(Theme.Font.micro)
                                .foregroundStyle(Theme.Palette.dim)
                        }
                    } icon: {
                        Image(systemName: "bolt.horizontal.circle")
                            .foregroundStyle(Theme.Palette.mint)
                    }
                }
            } header: {
                Text(t(.accuracySection))
            } footer: {
                Text(t(.accuracyFooter))
            }

            Section {
                Toggle(t(.autoRecord), isOn: $settings.isTrackingEnabled)
                Toggle(t(.includeWired), isOn: $settings.includeWired)
                Toggle(t(.inferWhileSuspended), isOn: $settings.inferWhileSuspended)
                Toggle(t(.liveActivityToggle), isOn: $settings.liveActivitiesEnabled)
            } header: {
                Text(t(.recordingSection))
            } footer: {
                Text(t(.inferFooter))
            }

            Section(t(.remindersSection)) {
                Picker(t(.continuousWear), selection: $settings.continuousWearMinutes) {
                    Text(t(.wearOff)).tag(0)
                    Text(t(.minutes30)).tag(30)
                    Text(t(.minutes45)).tag(45)
                    Text(t(.minutes60)).tag(60)
                    Text(t(.minutes90)).tag(90)
                }
                Picker(t(.dailyBudget), selection: $settings.dailyBudgetMinutes) {
                    Text(t(.budgetUnlimited)).tag(0)
                    Text(t(.hour1)).tag(60)
                    Text(t(.hour2)).tag(120)
                    Text(t(.hour3)).tag(180)
                    Text(t(.hour5)).tag(300)
                    Text(t(.hour8)).tag(480)
                }
                Toggle(t(.goalNotify), isOn: $settings.notifyOnGoal)
            }

            Section {
                Button {
                    shortcutHint = true
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t(.manualSetupGuide))
                                .foregroundStyle(Theme.Palette.text)
                            Text(t(.manualSetupGuideSub))
                                .font(Theme.Font.micro)
                                .foregroundStyle(Theme.Palette.dim)
                        }
                    } icon: {
                        Image(systemName: "list.number")
                            .foregroundStyle(Theme.Palette.muted)
                    }
                }
            } header: {
                Text(t(.automationSection))
            }

            Section(t(.dataSection)) {
                Button(t(.exportCSV)) { exportCSV() }
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("\(t(.shareFile)) \(exportURL.lastPathComponent)", systemImage: "square.and.arrow.up")
                    }
                }
                Button(t(.eraseAll), role: .destructive) {
                    showEraseConfirm = true
                }
            }

            Section {
                LabeledContent(t(.version), value: "1.0.0")
                LabeledContent(
                    t(.sessionEngine),
                    value: engine.state.isConnected ? t(.engineRunning) : t(.engineIdle)
                )
            } header: {
                Text(t(.aboutSection))
            } footer: {
                Text(t(.privacyFooter))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Palette.bg)
        .alert(t(.setupAlertTitle), isPresented: $shortcutHint) {
            Button(t(.okay)) {}
        } message: {
            Text(t(.setupAlertBody))
        }
        .confirmationDialog(
            t(.eraseConfirmTitle),
            isPresented: $showEraseConfirm,
            titleVisibility: .visible
        ) {
            Button(t(.delete), role: .destructive) { eraseAll() }
        } message: {
            Text(t(.eraseConfirmBody))
        }
        .onChange(of: settings.isTrackingEnabled) { _, enabled in
            if enabled { engine.start() } else { engine.stop() }
            settings.persist()
        }
        .onChange(of: settings.persistSignature) { _, _ in
            settings.persist()
        }
        .onAppear { settings.persist() }
    }

    private func exportCSV() {
        guard let url = CSVExporter.write(records: fetchAll(), language: language) else { return }
        exportURL = url
    }

    private func fetchAll() -> [SessionRecord] {
        (try? context.fetch(
            FetchDescriptor<SessionRecord>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        )) ?? []
    }

    private func eraseAll() {
        for record in fetchAll() { context.delete(record) }
        for device in (try? context.fetch(FetchDescriptor<DeviceProfile>())) ?? [] {
            context.delete(device)
        }
        try? context.save()
        stats.refresh()
    }
}
