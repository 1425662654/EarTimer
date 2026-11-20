# 把这个 .ipa 装到 iPhone 上

## 先说结论

**现在这个 `EarTimer-unsigned.ipa` 不能直接装。**

iOS 的安装机制强制要求代码签名。未签名的包丢进手机，系统只有两种反应：

- 通过 AirDrop / 文件传输 → 根本没有「安装」入口
- 用工具硬装 → 报 `ApplicationVerificationFailed` 或「无法验证此 App」

这不是包做坏了，是 iOS 的硬规定。**解决办法是本地用你自己的 Apple ID 给它签一次名。**

---

## 需要什么

| 项 | 状态 |
|---|---|
| `EarTimer-unsigned.ipa` | ✅ 已生成，574 KB |
| Sideloadly | ✅ 已装在 `C:\Users\14256\AppData\Local\Sideloadly\` |
| Apple 移动设备驱动 | ❌ **缺，要装** |
| iPhone + 数据线 | ⚠️ 你手上要有 |
| Apple ID | ⚠️ 用你自己的，不用付费开发者账号 |

---

## 第 1 步 · 装 Apple 驱动

Sideloadly 靠 `Apple Mobile Device Service` 跟手机通信，Windows 默认没有。

**装 iTunes（推荐，最稳）**

下载：https://www.apple.com/itunes/download/win64

装完确认服务在跑：

```powershell
Get-Service "Apple Mobile Device Service"
```

> 注意：微软商店版的 iTunes 不带这个服务。要下**官网的桌面版**。

**或者只装驱动**

如果不想装整个 iTunes，可以用 iCloud for Windows 安装包（体积更小，同样带驱动）：
https://updates.cdn-apple.com/2020/windows/001-39935-20200911-1A70AA56-F448-11EA-8CC0-99D41950005E/iCloudSetup.exe

---

## 第 2 步 · iPhone 端准备

1. **iPhone 用数据线连电脑**（必须是数据线，无线不行）
2. 手机上弹出「要信任此电脑吗」→ 点 **信任**，输入锁屏密码
3. 设置 → 隐私与安全性 → **开发者模式** → 打开（iOS 16+ 需要）
   - 打开后会要求重启手机，重启后确认开启
4. 记住你的 **Apple ID 和密码**（签名要用）

---

## 第 3 步 · 用 Sideloadly 签名安装

打开 Sideloadly（开始菜单搜 `Sideloadly`）：

| 字段 | 填什么 |
|---|---|
| **Apple ID** | 你的 Apple ID 邮箱 |
| **IPA** | 把 `EarTimer-unsigned.ipa` 拖进窗口 |
| **Device** | 下拉选你的 iPhone（连上了才会出现） |

点 **Start**，然后：

1. 弹出密码框 → 输入 Apple ID 密码
2. 如果开了双重认证 → 会要求输入 6 位验证码
3. 等进度条走完（1–3 分钟）

成功后会提示 `Done`，App 出现在手机桌面上。

---

## 第 4 步 · 信任证书（首次必做）

装完直接点 App 会闪退或提示「不受信任的开发者」。去：

**设置 → 通用 → VPN 与设备管理 → 开发者 App → 点你的 Apple ID → 信任**

然后再打开 App。

---

## 会遇到的三个问题

### 1. 7 天后打不开

免费 Apple ID 的签名**只有 7 天有效期**。到期后 App 图标变灰或点击闪退。

**解决**：再连一次电脑，Sideloadly 重新点一次 Start。或者用 Sideloadly 的「自动续签」功能（手机连电脑时后台自动重签）。

想永久有效只有两条路：
- 加入 Apple Developer Program（$99/年）
- 特定 iOS 版本用 TrollStore（14.0–16.6.1 等，永久免签）

### 2. `Anisette` 相关报错

Sideloadly 启动时有个 `Initializing Anisette...` 步骤，失败会提示。

**解决**：关掉重开一次。它自己的提示也写了「If Sideloadly crashes now, just restart it」。

### 3. 报 `Failed to obtain a development certificate`

| 原因 | 解决 |
|---|---|
| Apple ID 密码错 | 重输 |
| 双重认证没给验证码 | 重新走一遍，及时输入 6 位码 |
| 这个 Apple ID 免费签名额度用完了 | 免费账号同时只能签 3 个 App，删掉旧的 |
| Apple ID 没登录过 iCloud | 先在手机上登录一次 iCloud |

---

## 装好之后该验什么

因为这是**第一次真机运行**，重点验这几件只有真机能验的事：

| 验证项 | 怎么测 | 预期 |
|---|---|---|
| **App 能启动** | 点图标 | 出现 5 步引导页 |
| **快捷指令自动化**（最关键） | 配好蓝牙自动化 → **把 App 完全划掉** → 戴耳机 10 分钟 → 摘下 → 重开 App | 历史里有那条记录 |
| **灵动岛** | 戴耳机 | 灵动岛显示计时 |
| **小组件** | 长按桌面 → 加小组件 → 搜 EarTimer | 能看到「本次时长」 |
| **中英切换** | 设置 → Language | 全界面切换，首页标题始终 EarTimer |
| **通知** | 戴 60 分钟 | 收到「该让耳朵歇会儿了」 |

**其中第 2 项是核心。** 如果它不生效，说明 AppIntent 在后台跑不通，那是这个 App 唯一的技术命门，需要立刻告诉我。

---

## 另一个选择：不签名直接装（仅特定系统）

如果你的 iPhone 系统版本是 **iOS 14.0 – 16.6.1**（部分版本），可以用 **TrollStore**：

1. 装 TrollStore（有专门的安装器）
2. 把 `EarTimer-unsigned.ipa` 分享给它
3. 直接安装，**永久有效，不过期**

但这个 App 的 deployment target 是 **iOS 18.0**，TrollStore 覆盖的系统版本装不了。除非我把 target 降到 17.0 —— 那要改不少 API 用法（`@Observable` 需要 17+，已经满足；但 `TabView` 的新 `Tab` 语法是 18+）。

---

## 一句话总结

| 方式 | 能装吗 | 有效期 |
|---|---|---|
| 直接装未签名 ipa | ❌ | — |
| Sideloadly + 免费 Apple ID | ✅ | 7 天，可续 |
| Sideloadly + 付费开发者 | ✅ | 1 年 |
| TrollStore | ⚠️ 系统版本不匹配 | 永久 |
| App Store | 需上架审核 | 永久 |

**下一步：装 iTunes 驱动 → 插手机 → Sideloadly 走一遍。**
