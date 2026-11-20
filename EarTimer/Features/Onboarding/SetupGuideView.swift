import SwiftUI
import SwiftData

/// 首次启动的引导。核心目的只有一个：**让用户把蓝牙自动化配上**。
///
/// 因为不配的话，App 关掉之后就不可能有准确数据 —— 这是 iOS 的硬限制，
/// 与其藏起来，不如第一步就说清楚。
struct SetupGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageStore.self) private var lang
    @State private var step = 0

    private var language: AppLanguage { lang.language }
    private func t(_ key: L10n.Key) -> String { L10n.t(key, language) }

    private var steps: [GuideStep] {
        [
            GuideStep(
                icon: "bolt.horizontal.circle",
                title: t(.guideStep1Title),
                body: t(.guideStep1Body),
                highlight: t(.guideStep1Chip)
            ),
            GuideStep(
                icon: "square.stack.3d.up",
                title: t(.guideStep2Title),
                body: t(.guideStep2Body),
                highlight: t(.guideStep2Chip)
            ),
            GuideStep(
                icon: "play.circle",
                title: t(.guideStep3Title),
                body: t(.guideStep3Body),
                highlight: t(.guideStep3Chip)
            ),
            GuideStep(
                icon: "stop.circle",
                title: t(.guideStep4Title),
                body: t(.guideStep4Body),
                highlight: t(.guideStep4Chip)
            ),
            GuideStep(
                icon: "checkmark.seal",
                title: t(.guideStep5Title),
                body: t(.guideStep5Body),
                highlight: nil
            ),
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $step) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, item in
                        page(item).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                footer
            }
            .background(Theme.Palette.bg)
            .navigationTitle(t(.guideTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(t(.guideSkip)) { finish() }
                        .foregroundStyle(Theme.Palette.dim)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func page(_ item: GuideStep) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(Theme.Palette.mint.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: item.icon)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Theme.Palette.mint)
            }

            VStack(spacing: Theme.Spacing.m) {
                Text(item.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.Palette.text)
                    .multilineTextAlignment(.center)

                Text(item.body)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Palette.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.xxl)

            if let highlight = item.highlight {
                MetaChip(text: highlight, tint: Theme.Palette.amber)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.m) {
            if step < steps.count - 1 {
                Button {
                    withAnimation(.snappy) { step += 1 }
                } label: {
                    Text(t(.guideNext))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Palette.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.Palette.mint, in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    openShortcuts()
                } label: {
                    Text(t(.guideOpenShortcuts))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Palette.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.Palette.mint, in: Capsule())
                }
                .buttonStyle(.plain)

                Button(t(.guideDone)) { finish() }
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Palette.muted)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.l)
    }

    private func openShortcuts() {
        // shortcuts:// 直接进快捷指令 App；iOS 没有 URL 直达「新建蓝牙自动化」，
        // 所以只负责跳过去，步骤在引导里已经写清楚了。
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }

    private func finish() {
        SharedDefaults.suite.set(true, forKey: SharedDefaults.Keys.guideCompleted)
        dismiss()
    }
}

private struct GuideStep {
    var icon: String
    var title: String
    var body: String
    var highlight: String?
}
