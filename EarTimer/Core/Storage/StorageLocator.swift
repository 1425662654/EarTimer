import Foundation
import SwiftData
import os

/// 存储位置的选择逻辑。
///
/// # 为什么需要这层
///
/// `ModelConfiguration(groupContainer: .identifier(...))` 在 **entitlements 里没有对应
/// App Group** 时，不会抛错，而是直接 `fatalError`：
///
/// ```
/// SwiftData/DataUtilities.swift:1087: Fatal error:
/// Unable to find App Group Container in Entitlements: group.com.yg.eartimer
/// ```
///
/// 这种崩溃 `do/catch` 接不住，因为它是 `fatalError` 不是 `throw`。
///
/// 所以必须先**自己探测** App Group 的容器目录是否真的拿得到，再决定用哪个配置。
/// 典型场景：
/// - 未签名的 CI 构建 / 模拟器 → 没有 entitlements → 退回本机沙盒
/// - 用户用免费证书签名但没开 App Group → 同样退回
/// - 正常签名 → 用 App Group，Widget 才能共享数据
enum StorageLocator {

    private static let log = Logger(subsystem: "com.yg.eartimer", category: "Storage")

    /// App Group 的容器根目录；不可用时返回 nil
    static func appGroupContainerURL() -> URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedDefaults.appGroup
        )
    }

    /// App Group 是否真的可用（entitlements 生效）
    static var isAppGroupAvailable: Bool {
        appGroupContainerURL() != nil
    }

    /// 构造容器，永不 fatalError。
    /// - Returns: 容器；如果连本机沙盒都建不起来，返回内存库
    static func makeContainer() -> ModelContainer {
        let schema = Schema([SessionRecord.self, DeviceProfile.self])

        // 路径一：App Group（理想情况，Widget 可共享）
        if isAppGroupAvailable {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(SharedDefaults.appGroup),
                cloudKitDatabase: .none
            )
            do {
                let container = try ModelContainer(for: schema, configurations: config)
                log.info("使用 App Group 容器: \(SharedDefaults.appGroup, privacy: .public)")
                return container
            } catch {
                log.error("App Group 容器创建失败，退回本机沙盒: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            log.notice("App Group 不可用（entitlements 缺失），使用本机沙盒")
        }

        // 路径二：本机沙盒（无 App Group 时的降级）
        let local = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: schema, configurations: local)
            log.info("使用本机沙盒容器")
            return container
        } catch {
            log.error("本机容器失败，退回内存库: \(error.localizedDescription, privacy: .public)")
        }

        // 路径三：内存（最后兜底，至少 UI 能用）
        let memory = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        // 内存库再失败就没救了，但用 fatalError 换不来更好的结果，
        // 这里让它抛给上层尽量被发现；实际几乎不可能发生。
        do {
            return try ModelContainer(for: schema, configurations: memory)
        } catch {
            fatalError("无法创建任何 ModelContainer: \(error)")
        }
    }
}
