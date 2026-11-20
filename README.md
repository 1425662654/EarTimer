# EarTimer

苹果蓝牙耳机（AirPods 类）连接时长统计工具。连上即开始计时，摘下即停；看本次、今日、累计，并回答「今天是不是戴太久了」。

Swift 6 · SwiftUI · SwiftData · iOS 18+ · 中英双语 · 深色主题

---

## 这个 App 解决的真正难题

iOS **不开放蓝牙连接状态**给第三方 App。能观察到的只有音频输出路由（`AVAudioSession.currentRoute`），而它的变更通知**只在 App 存活时送达**。

于是坊间两种做法都走不通：

- 播静音音频保活 → 滥用 `audio` 后台模式，App Store 必拒
- CoreBluetooth 状态恢复 → AirPods 连上后停止 BLE 广播，扫不到；且用户强杀后永不重启（[TN3115](https://developer.apple.com/documentation/technotes/tn3115-bluetooth-state-restoration-app-relaunch-rules)）

**本项目采用唯一可行方案：快捷指令「蓝牙」个人自动化 + AppIntent。** Apple 官方确认「蓝牙」属于可关闭「运行前询问」的触发器，intent 设 `openAppWhenRun = false` 后可在纯后台进程执行——**App 完全不用打开也能记录**。

代价是用户要手动配一次自动化，所以首次启动有 5 步全屏引导，设置页还有状态徽章（已生效 / 未配置 / 待确认）用最近一条记录的来源反推。

详见 [docs/03-后台自动计时方案.md](docs/03-后台自动计时方案.md)。

---

## 准确度分层

| 层 | 机制 | 误差 | 标记 | App 关着能记 |
|---|---|---|---|---|
| Tier 1 | 快捷指令蓝牙自动化 | < 1 秒 | `Shortcut` | ✅ |
| Tier 2 | App 存活时监听路由 | < 1 秒 | `Live` / `Auto` | ❌ |
| Tier 3 | CoreBluetooth（仅非苹果 BLE 耳机） | < 1 秒 | `BT LE` | ✅ |
| Tier 4 | 心跳推算 | 可达数分钟 | `EST` | — |

---

## 构建

**没有 Mac？** 看 [docs/04-没有Mac怎么打包.md](docs/04-没有Mac怎么打包.md)，用 GitHub Actions 免费出 `.ipa`。

**有 Mac？**

```bash
./preflight.sh    # 环境自检
./build.sh        # 生成工程并打开 Xcode
./build.sh archive  # 导出 .ipa
```

详见 [BUILD.md](BUILD.md)。

## 功能

- 连接即计时（四层检测 + 自动去重 + 脏数据校准）
- 本次 / 今日 / 本周 / 累计
- 历史按天分组，可改起止时间、加备注、删除
- 推算数据打标 + 详情页解释
- 灵动岛 / 锁屏实时计时（`Text(timerInterval:)` 自走，挂起不停表）
- 桌面小组件（小 / 中 / 锁屏圆形 / 锁屏矩形）
- 连续佩戴提醒、每日预算、目标达成通知
- 24 小时时段分布、30 天热力、按设备、连续天数
- CSV 导出（UTF-8 BOM，Excel 直接认中文）
- App Intents：开始 / 结束 / 查今日时长
- 界面语言中英切换，默认英文；首页标题恒为 `EarTimer`

## 目录

```
├── project.yml               XcodeGen 工程描述（唯一事实来源）
├── build.sh / preflight.sh   构建与环境自检
├── Shared/                   主 App + Widget 共用，纯逻辑无 SwiftData
├── EarTimer/                 主 App
├── EarTimerWidgets/          小组件 + 灵动岛
├── docs/                     产品分析 / 技术方案 / 后台方案 / 无 Mac 打包
└── .github/workflows/        CI：无 Mac 也能编译出 ipa
```

## 测试

```bash
cd ..
python test/test_logic.py          # 54 项核心逻辑
python test/test_state_machine.py  # 47 项会话状态机
python test/test_intent_store.py   # 26 项后台写库路径
python test/test_e2e.py            # 31 项端到端流程
```

## 有意的取舍

| 没做 | 原因 |
|---|---|
| 左右耳电量 | 苹果不开放；第三方只能嗅探私有 BLE 广播，随版本失效且审核风险高 |
| 「佩戴时长」（摘下即停） | 只能靠音频播放态近似，会误导；统一用「连接时长」这个诚实说法 |
| 后台常驻 | 播静音属滥用 `audio` 后台模式，会被拒且耗电 |
| iCloud 同步 | 先把本机做扎实，留 v1.1 |

## License

MIT
