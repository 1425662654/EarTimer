# EarTimer · 从源码到跑到手机上

> 当前状态：**源码已完成并测过逻辑层，但尚未编译**（开发环境是 Windows，没有 Xcode）。
> 本文就是在 Mac 上把它变成 .app / .ipa 的完整路径。

---

## 0. 先跑环境自检

```bash
cd EarTimer
chmod +x preflight.sh build.sh
./preflight.sh
```

它会检查：macOS、Xcode、iOS SDK ≥ 18、XcodeGen、签名证书。缺什么它会直接告诉你装什么。

---

## 1. 生成工程

```bash
./build.sh gen
```

这一步用 XcodeGen 把 `project.yml` 变成 `EarTimer.xcodeproj`。
不用手动拖文件，`project.yml` 已经把 39 个 Swift 文件、Info.plist、entitlements、两个 target 全配好了。

---

## 2. 配签名（只有首次需要）

```bash
open EarTimer.xcodeproj
```

在 Xcode 里：

1. 左侧选 **EarTimer** target → **Signing & Capabilities**
2. Team 选你的 Apple ID（免费个人 Team 就够真机调试）
3. 确认 **App Groups** 里有 `group.com.yg.eartimer`
4. 同样操作 **EarTimerWidgets** target

> 免费账号的限制：App 7 天过期、不能上架、不能推送。调试够用。
> 想改 Bundle ID：同时改 `project.yml` 的 `PRODUCT_BUNDLE_IDENTIFIER` 和
> `Shared/SharedDefaults.swift` 里的 `appGroup`，然后重新 `./build.sh gen`。

---

## 3. 跑起来

连上 iPhone（模拟器测不了蓝牙），`⌘R`。

**首次启动会弹 5 步引导**——这一步别跳过，它是「App 关着也能计时」的前提。

---

## 4. 导出 .ipa

```bash
./build.sh archive
```

产出在 `build/export/EarTimer.ipa`。

安装到手机：

```bash
# 方式 A：Xcode Devices 窗口拖进去
open -a "Devices"

# 方式 B：命令行
xcrun devicectl device install app --device <UDID> build/export/EarTimer.app
```

> `archive` 走的是 `development` 导出方式，需要对应设备的 provisioning profile。
> 上架要用 `app-store`，还需要 App Store Connect 里先建好 App 记录。

---

## 5. 编译报错了怎么办

大概率会遇到这几类，按顺序排查：

| 报错 | 原因 | 处理 |
|---|---|---|
| `No such module 'SwiftData'` | deployment target < 17 | 确认 iOS 18.0 |
| `@Observable` 相关 | 同名宏冲突 | 检查是否手写了 `import Observation` 之外的重复定义 |
| `App Group ... not found` | 签名未开 App Group | 两个 target 都要开 |
| Widget 找不到 `SharedDefaults` | `Shared` 目录没加到 Widget target | 检查 `project.yml` 的 `sources` 是否含 `Shared` |
| `Cannot find 'AudioChannel'` | 同上 | 同上 |
| Live Activity 不显示 | Info.plist 缺 key | 确认 `NSSupportsLiveActivities: true` |

编译通过后，**把报错或警告贴给我，我按条修。**

---

## 目录说明

```
EarTimer/
├── project.yml          XcodeGen 工程描述（唯一事实来源）
├── build.sh             构建脚本
├── preflight.sh         环境自检
├── Shared/              主 App + Widget 共用的纯逻辑（无 SwiftData 依赖）
├── EarTimer/            主 App
├── EarTimerWidgets/     小组件 + 灵动岛
└── docs/                产品分析、技术方案、后台计时方案
```

**为什么 `Shared/` 不能放 SwiftData 模型**：Widget target 也会编译这个目录，
而 SwiftData 的 `@Model` 需要完整框架支持。所以模型留在主 App 的 `Core/Models/`，
Widget 只通过 `SharedDefaults` 里的小 JSON 快照读状态。
