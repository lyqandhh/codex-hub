# Codex HUD Micro Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 Codex HUD 缩小为 118 × 30 pt 微型圆环胶囊，同时保留周额度、重置次数、重置日期和状态点。

**Architecture:** 保持现有 QuotaProvider、QuotaStore、偏好和窗口交互不变，只扩展紧凑格式化函数，并替换 QuotaCapsuleView 的视觉层次与 FloatingPanelController 的固定尺寸。通过现有 Swift Testing 测试格式行为，再用真实 `.app` 截图完成视觉 QA。

**Tech Stack:** Swift 6、SwiftUI、AppKit、Swift Testing、Swift Package Manager、macOS 14+

## Global Constraints

- 窗口固定为 118 × 30 pt，所有状态不得改变窗口尺寸。
- 常驻内容只能包含圆环内额度整数、`×N`、紧凑日期和状态点。
- 保留始终置顶、拖动、右键菜单、鼠标穿透、刷新、缓存和登录时启动。
- 不修改 Codex 只读数据协议，不调用任何 consume 方法。

---

### Task 1: 紧凑额度格式

**Files:**
- Modify: `Tests/CodexHUDTests/QuotaFormattingTests.swift`
- Modify: `Sources/CodexHUD/Domain/QuotaFormatting.swift`

**Interfaces:**
- Produces: `QuotaFormatting.ringValue(_:) -> String`
- Produces: `QuotaFormatting.compactResetDate(_:now:calendar:) -> String`

- [ ] 添加失败测试：`0.984 -> "98"`、同年日期 `2026-07-20 -> "7/20"`、跨年日期 `2027-01-02 -> "27/1/2"`。
- [ ] 运行 `swift test --filter QuotaFormattingTests`，确认新增 API 缺失导致失败。
- [ ] 实现百分比整数和紧凑日期格式化。
- [ ] 再次运行格式测试与全量 `swift test`，确认通过。
- [ ] 提交 `feat: add compact quota formatting`。

### Task 2: 微型圆环胶囊

**Files:**
- Modify: `Sources/CodexHUD/UI/QuotaCapsuleView.swift`
- Modify: `Sources/CodexHUD/UI/FloatingPanelController.swift`

**Interfaces:**
- Consumes: `QuotaFormatting.ringValue` and `compactResetDate`
- Preserves: `FloatingPanelController` 现有交互方法

- [ ] 将窗口尺寸改为 118 × 30 pt，默认右上角边距保持 18 pt。
- [ ] 用 26 pt `Circle.trim` 进度环替换底部进度条，中心显示额度整数。
- [ ] 把 `×N` 和日期组成两行 24 pt 高的紧凑 VStack，右侧保留 6 pt 状态点。
- [ ] 将加载与不可用状态压入同一尺寸，确保没有截断。
- [ ] 运行 `swift test` 和 `swift build`，确认通过。
- [ ] 提交 `feat: redesign HUD as micro quota chip`。

### Task 3: 安装与视觉 QA

**Files:**
- Modify: `design-qa.md`
- Create: `qa/micro-hud.png`
- Create: `qa/micro-comparison.png`

**Interfaces:**
- Source visual: `/Users/mantou/.codex/generated_images/019f594b-489e-7c63-8e1a-fb9ba95e914e/exec-fc554883-ce19-460e-adeb-b5cb4713e232.png`

- [ ] 运行 `scripts/install-app.sh` 替换已安装应用并启动。
- [ ] 捕获真实 118 × 30 pt HUD，验证实时额度、次数、日期与状态点。
- [ ] 把视觉稿和真实截图放进同一张比较图，修复所有 P0/P1/P2 偏差。
- [ ] 更新 `design-qa.md`，最终结果必须为 `passed`。
- [ ] 运行 `swift test`、Release 构建、签名检查和进程检查。
- [ ] 提交 `test: verify micro HUD redesign`。
