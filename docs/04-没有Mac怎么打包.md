# 没有 Mac，怎么拿到 .ipa

> 你的机器是 Windows。这份文档给出三条真实可走的路，按「省事程度」排序。

---

## 先说结论

`.ipa` 不是「换个格式压缩一下」，它里面是 **ARM64 的 Mach-O 二进制**，必须用 Apple 的工具链（`swiftc` + iOS SDK + 签名）编译出来。

**Windows 上的 Swift 编译器不含 iOS SDK**（我实际装过验证：只有 `Android.platform` 和 `Windows.platform`，没有 `iOS.platform`）。所以无论装什么补丁，都编不出 iOS 二进制。

但「没有 Mac」≠「做不到」。有三条路：

| 路线 | 成本 | 能否出 .ipa | 适合 |
|---|---|---|---|
| **A · GitHub Actions** | 免费 | ✅ 未签名 .ipa | **推荐** |
| B · 云 Mac 租用 | ~$30/月起 | ✅ 可签名上传 | 要上架时 |
| C · 买台二手 Mac mini | ~$400 一次性 | ✅ 全流程 | 长期做 iOS |

---

## 路线 A · GitHub Actions（免费，推荐）

GitHub 给公开仓库**无限量免费 macOS 运行器**，私有仓库每月 2000 分钟（macOS 按 10 倍计 = 200 分钟）。编译这个 App 大概 3-5 分钟，够跑 40 次。

工作流已经写好了：`.github/workflows/build-ios.yml`

### 步骤

**1. 建仓库**

```bash
cd EarTimer
git init
git add .
git commit -m "EarTimer 1.0.0"
```

在 GitHub 上建一个空仓库（**选 Public，这样 Actions 完全免费**），然后：

```bash
git remote add origin https://github.com/<你的用户名>/EarTimer.git
git branch -M main
git push -u origin main
```

> 注意：这个目录的 `origin` 现在指向内网 `192.168.1.153`，需要新加一个远程。

**2. 等它自己跑**

推上去后打开仓库的 **Actions** 页，`Build iOS` 会自动开始。

**3. 下载产物**

跑完后在 Actions run 页面底部 **Artifacts** 里下载 `EarTimer-build`，里面有：

- `EarTimer-unsigned.ipa` — 未签名安装包
- `EarTimer.app` — 未签名 app 包
- `build.log` — 完整编译日志

### 这一步真正的价值

**即使你暂时不装到手机上，这一步也把最关键的问题解决了：验证代码能不能编译。**

之前我只能用 `swiftc -parse` 验证语法（39 个文件全过），但语法对 ≠ 能编译。类型检查、SwiftData 宏展开、`@Observable` 宏、SwiftUI 的泛型推导，这些只有真编译器能验。GitHub Actions 一次跑完就全知道了。

**如果编译失败，把 Actions 里的 `build.log` 贴给我，我按错误改。**

### 未签名 .ipa 怎么装到手机

未签名包不能直接装。几个办法：

| 方式 | 说明 | 成本 |
|---|---|---|
| **Sideloadly** | Windows 上直接装，输入 Apple ID 自动签名 | 免费，7 天过期 |
| **AltStore** | 同类工具，需装 AltServer | 免费，7 天过期 |
| **TrollStore** | 仅限特定 iOS 版本（14.0–16.6.1 等），永久免签 | 免费 |
| 企业证书 | 网上买，随时可能被吊销 | 几十到几百 |

7 天过期是因为免费 Apple ID 的 provisioning profile 只有 7 天。Sideloadly 支持自动重签（手机连电脑时后台续）。

---

## 路线 B · 云 Mac

要上架 App Store 就必须有签名证书，而证书必须在真实 Mac 的钥匙串里生成。

| 服务 | 价格 | 说明 |
|---|---|---|
| **MacStadium** | $30+/月 | 老牌，按机器租 |
| **MacinCloud** | $25+/月 | 按小时也卖，$1/小时 |
| **AWS EC2 mac** | $0.65/小时 | 按需，最低 24 小时起 |
| **Scaleway / Hetzner** | €0.10/小时 | 欧洲，性价比高 |

租一小时后：装 Xcode → 登录 Apple ID → 打开工程 → `⌘R`。全过程 20 分钟够。

---

## 路线 C · 买台二手 Mac

Mac mini M1 二手约 ¥2500-3000（$400 上下）。好处是随时能改能调，不用等 CI。

---

## 完全不想碰 Apple 生态？

那这个 App 做不出来。但同样的功能可以换平台重写：

| 平台 | 可行性 | 说明 |
|---|---|---|
| **Android** | ✅ 很好做 | 有 `BluetoothAdapter.ACTION_ACL_CONNECTED` 广播，**能真正监听蓝牙连接**，不需要快捷指令这种绕路。这个 App 在 Android 上会简单得多 |
| **鸿蒙 / 小米** | ⚠️ | 权限模型不同，需查各家文档 |
| **PWA** | ❌ | 拿不到蓝牙状态 |

如果你其实更想「有个能用的工具」而不是「必须 iOS」，Android 版本会省掉 90% 的麻烦——我在这个工程里的 `SessionEngine`、`StatsStore`、`DurationText`、`L10n` 逻辑几乎可以原样移植。

---

## 当前状态

| 项 | 状态 |
|---|---|
| 39 个 Swift 文件语法 | ✅ 已用真实 `swiftc -parse` 验证通过 |
| 类型检查 / 编译 | ⏳ 待 GitHub Actions 验证 |
| 逻辑测试 | ✅ 249 项通过 |
| 界面 | ✅ 四屏预览 + 中英切换 |
| `.ipa` | ⏳ 跑一次 Actions 就有 |

**下一步就一件事：把代码推到 GitHub，看 Actions 的编译结果。**
