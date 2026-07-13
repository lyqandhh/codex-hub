# Codex HUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个原生 macOS 始终置顶胶囊 HUD，实时显示 Codex 周剩余额度、可用重置次数与重置日期。

**Architecture:** 使用 Swift Package 构建 SwiftUI/AppKit 应用，打包脚本生成无 Dock 图标的 `.app`。数据层通过独立 JSON-RPC 客户端调用本机 `codex app-server`，解析层只向界面暴露规范化后的周额度快照；窗口、设置与数据刷新各自隔离。

**Tech Stack:** Swift 6、SwiftUI、AppKit、Foundation、Swift Testing、Swift Package Manager、macOS 14+

## Global Constraints

- 应用名为 `Codex HUD`，项目根目录为 `/Users/mantou/Projects/CodexHUD`。
- HUD 默认约 390 × 52 pt，深色半透明胶囊，显示 `1周 99% · 重置 ×3 · 7月20日`。
- 仅调用 `account/rateLimits/read`；绝不调用 `account/rateLimitResetCredit/consume`。
- 不使用 OpenAI API Key，不上传数据，不记录令牌或完整原始响应。
- 默认每 60 秒刷新，失败时保留最后一次成功数据。
- 应用不显示 Dock 图标，支持始终置顶、拖动、鼠标穿透恢复、右键菜单与登录时启动。

---

## File Map

- `Package.swift`：SwiftPM 可执行目标和测试目标。
- `Sources/CodexHUD/Domain/QuotaSnapshot.swift`：规范化额度模型。
- `Sources/CodexHUD/Domain/QuotaFormatting.swift`：百分比、日期和界面文本格式化。
- `Sources/CodexHUD/Data/RateLimitResponseParser.swift`：Codex JSON 响应解析与窗口选择。
- `Sources/CodexHUD/Data/CodexAppServerClient.swift`：stdio JSON-RPC 进程交互。
- `Sources/CodexHUD/Data/CodexQuotaProvider.swift`：只读额度提供器。
- `Sources/CodexHUD/State/QuotaStore.swift`：刷新、缓存与新鲜度状态。
- `Sources/CodexHUD/State/PreferencesStore.swift`：透明度、穿透和窗口位置。
- `Sources/CodexHUD/UI/QuotaCapsuleView.swift`：选定视觉方向的胶囊界面。
- `Sources/CodexHUD/UI/FloatingPanelController.swift`：无边框置顶窗口与交互。
- `Sources/CodexHUD/App/CodexHUDApp.swift`：应用生命周期和菜单。
- `Tests/CodexHUDTests/*Tests.swift`：模型、解析、格式化和状态测试。
- `scripts/build-app.sh`：构建并组装 `dist/Codex HUD.app`。
- `scripts/install-app.sh`：安装到用户的 Applications 目录并启动。
- `README.md`：安装、使用、快捷键与隐私说明。

### Task 1: Swift Package 与额度领域模型

**Files:**
- Create: `Package.swift`
- Create: `Sources/CodexHUD/Domain/QuotaSnapshot.swift`
- Create: `Sources/CodexHUD/Domain/QuotaFormatting.swift`
- Create: `Tests/CodexHUDTests/QuotaFormattingTests.swift`

**Interfaces:**
- Produces: `QuotaSnapshot(remainingFraction: Double, resetsAt: Date, resetCredits: Int?)`
- Produces: `QuotaFormatting.percent(_:)`, `QuotaFormatting.resetDate(_:now:calendar:)`, `QuotaFormatting.credits(_:)`

- [ ] 写失败测试，覆盖百分比夹取、`重置 ×0`、缺失值 `重置 --`、24 小时内相对时间和跨年日期。
- [ ] 运行 `swift test --filter QuotaFormattingTests`，确认因类型缺失而失败。
- [ ] 实现最小模型与格式化逻辑。
- [ ] 再次运行相同测试，确认通过。
- [ ] 提交 `feat: add quota domain model and formatting`。

### Task 2: Codex 额度响应解析

**Files:**
- Create: `Sources/CodexHUD/Data/RateLimitResponseParser.swift`
- Create: `Tests/CodexHUDTests/RateLimitResponseParserTests.swift`

**Interfaces:**
- Consumes: `QuotaSnapshot`
- Produces: `RateLimitResponseParser.parse(data: Data, now: Date) throws -> QuotaSnapshot`

- [ ] 写失败测试，使用样例 JSON 覆盖 `usedPercent` 到剩余比例转换、周窗口选择、`availableCount` 为 0、字段缺失和非法比例。
- [ ] 运行 `swift test --filter RateLimitResponseParserTests`，确认失败原因是解析器缺失。
- [ ] 实现只解析 `account/rateLimits/read` 响应所需字段的 `Decodable` 私有结构。
- [ ] 运行解析测试和全量 `swift test`，确认通过。
- [ ] 提交 `feat: parse Codex weekly quota and reset credits`。

### Task 3: 只读 JSON-RPC 客户端

**Files:**
- Create: `Sources/CodexHUD/Data/CodexAppServerClient.swift`
- Create: `Sources/CodexHUD/Data/CodexQuotaProvider.swift`
- Create: `Tests/CodexHUDTests/CodexAppServerClientTests.swift`

**Interfaces:**
- Produces: `protocol QuotaProvider { func fetchQuota() async throws -> QuotaSnapshot }`
- Produces: `CodexAppServerClient.requestRateLimits() async throws -> Data`

- [ ] 写失败测试，向客户端注入测试进程传输，验证只发送初始化与 `account/rateLimits/read`，并拒绝任何包含 `consume` 的方法。
- [ ] 运行客户端测试，确认失败。
- [ ] 实现带超时、逐行 JSON 响应匹配和干净终止的 stdio 客户端；Codex 路径优先 `/Applications/Codex.app/Contents/Resources/codex`，其次使用 `PATH`。
- [ ] 运行客户端测试和全量测试，确认通过。
- [ ] 用真实本机 Codex 只读请求打印脱敏后的周百分比、日期和次数，禁止输出原始 JSON。
- [ ] 提交 `feat: read quota from Codex app server`。

### Task 4: 刷新、缓存与错误状态

**Files:**
- Create: `Sources/CodexHUD/State/QuotaStore.swift`
- Create: `Tests/CodexHUDTests/QuotaStoreTests.swift`

**Interfaces:**
- Consumes: `QuotaProvider`
- Produces: `@MainActor final class QuotaStore: ObservableObject`
- Produces: `QuotaStore.State = loading | live(QuotaSnapshot) | stale(QuotaSnapshot, Date) | unavailable`

- [ ] 写失败测试，覆盖首次成功、失败保留缓存、首次失败不可用和重复刷新不并发。
- [ ] 运行 `swift test --filter QuotaStoreTests`，确认失败。
- [ ] 实现 60 秒刷新循环、手动刷新和最后成功快照缓存。
- [ ] 运行状态测试和全量测试，确认通过。
- [ ] 提交 `feat: add resilient quota refresh state`。

### Task 5: 胶囊界面与浮动窗口

**Files:**
- Create: `Sources/CodexHUD/State/PreferencesStore.swift`
- Create: `Sources/CodexHUD/UI/QuotaCapsuleView.swift`
- Create: `Sources/CodexHUD/UI/FloatingPanelController.swift`
- Create: `Sources/CodexHUD/App/CodexHUDApp.swift`
- Create: `Tests/CodexHUDTests/PreferencesStoreTests.swift`

**Interfaces:**
- Consumes: `QuotaStore` and `QuotaFormatting`
- Produces: `FloatingPanelController.show()`、`toggleMousePassthrough()`、`resetPosition()`

- [ ] 写失败测试，覆盖透明度边界、窗口位置持久化和穿透开关。
- [ ] 运行偏好测试，确认失败。
- [ ] 实现选定的 390 × 52 pt 深色毛玻璃胶囊、分隔点、状态点和底部额度线。
- [ ] 实现 `NSPanel` 始终置顶、全屏空间可见、拖动、双击穿透、Command-Shift-H 恢复以及右键菜单。
- [ ] 实现无 Dock 图标应用生命周期、启动刷新与设置保存。
- [ ] 运行全量测试和 `swift build`，确认通过。
- [ ] 提交 `feat: build floating Codex quota HUD`。

### Task 6: `.app` 打包、安装与文档

**Files:**
- Create: `scripts/build-app.sh`
- Create: `scripts/install-app.sh`
- Create: `README.md`
- Create: `.gitignore`

**Interfaces:**
- Produces: `dist/Codex HUD.app`

- [ ] 编写打包脚本，生成包含 `LSUIElement=true`、`LSMinimumSystemVersion=14.0` 和 bundle id `local.mantou.CodexHUD` 的 Info.plist。
- [ ] 运行 `scripts/build-app.sh`，确认 `.app` 可执行文件与 Info.plist 均存在。
- [ ] 编写安装脚本，将应用复制到 `~/Applications/Codex HUD.app` 并启动。
- [ ] 编写 README，说明显示内容、拖动、穿透恢复、刷新、登录启动和隐私边界。
- [ ] 提交 `build: package Codex HUD macOS app`。

### Task 7: 视觉校准与最终验证

**Files:**
- Create: `design-qa.md`
- Modify: UI files only when screenshot comparison发现偏差

**Interfaces:**
- Consumes: selected reference `/Users/mantou/.codex/generated_images/019f594b-489e-7c63-8e1a-fb9ba95e914e/exec-097c49b1-c6ae-4134-a700-c50d28154be6.png`

- [ ] 启动安装后的应用，截图真实 HUD。
- [ ] 对照选定视觉稿检查尺寸、间距、层级、背景材质、颜色和长文本，记录到 `design-qa.md`。
- [ ] 修复所有 P0/P1/P2 视觉问题并重新截图，直到 `final result: passed`。
- [ ] 运行 `swift test`、`swift build -c release`、`scripts/build-app.sh` 和真实额度只读检查。
- [ ] 验证进程存在、应用无 Dock 图标配置、窗口置顶、拖动、右键菜单与穿透恢复。
- [ ] 提交 `test: verify Codex HUD app and visual fidelity`。
