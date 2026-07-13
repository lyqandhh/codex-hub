# Codex HUD

一枚轻量、原生的 macOS 悬浮组件，在屏幕上持续显示 Codex 周额度、可用重置次数与下次重置日期。无需打开 Codex 设置，也无需反复点击菜单栏。

<p align="center">
  <img src="docs/images/codex-hud.png" width="354" alt="Codex HUD 悬浮效果">
</p>

## 功能特点

- **一眼看清额度**：圆环显示周剩余额度，中央数字为剩余百分比。
- **紧凑常驻**：仅 `118 × 46 pt`，无 Dock 图标，不占菜单栏。
- **自动刷新**：默认每 60 秒更新；右侧状态点表示数据新鲜度。
- **原生体验**：SwiftUI + AppKit 实现，支持毛玻璃、拖动、透明度与鼠标穿透。
- **本地只读**：通过本机 Codex app-server 获取额度，不需要 API Key，不上传数据。
- **开机自启**：可在右键菜单中开启或关闭。

## 界面说明

| 元素 | 含义 |
| --- | --- |
| 圆环与数字 | 本周剩余额度百分比；绿色为充足，黄色为低于 50%，橙红色为低于 20% |
| `×3` | 当前可用的额度重置次数；Codex 未返回该字段时隐藏 |
| `7/20` | 下次额度重置日期；不足 24 小时时显示剩余小时数 |
| 右侧圆点 | 绿色：最新数据；黄色：暂时使用上次成功数据；灰色：正在读取或暂不可用 |

## 快速安装

### 1. 下载

前往 [Releases](https://github.com/lyqandhh/codex-hub/releases/latest)，下载 `Codex-HUD-v1.0.0-macOS.zip`。

### 2. 安装

1. 解压下载的 ZIP。
2. 将 `Codex HUD.app` 拖入“应用程序”文件夹。
3. 确保官方 ChatGPT 桌面应用已安装，并已登录 Codex 账号。
4. 首次启动 `Codex HUD.app`。

> 系统要求：macOS 14 Sonoma 或更高版本；`/Applications/ChatGPT.app` 已安装并登录。仍兼容旧版 `/Applications/Codex.app` 和 PATH 中的 `codex` CLI。

### 首次启动被 macOS 拦截

当前开源版本使用临时签名，尚未经过 Apple Developer ID 公证。若 macOS 提示无法验证开发者：

1. 在 Finder 中找到 `Codex HUD.app`。
2. 按住 Control 点击应用，选择“打开”。
3. 在弹窗中再次选择“打开”。

如果仍被阻止，可在终端执行：

```bash
xattr -dr com.apple.quarantine "/Applications/Codex HUD.app"
```

该命令只移除这个应用的下载隔离标记。建议仅从本仓库的 Release 页面下载。

## 使用方法

- **移动位置**：拖动悬浮组件。
- **打开菜单**：右键点击组件。
- **立即刷新**：右键 →“立即刷新”。
- **调整透明度**：右键 →“透明度”。
- **鼠标穿透**：双击组件开启或关闭；开启后点击会落到下方窗口。
- **恢复交互**：鼠标穿透时按 `Command + Shift + H`。
- **登录时启动**：右键 →“登录时启动”。
- **恢复默认位置 / 退出**：使用右键菜单。

偏好设置与窗口位置会保存在本机，下次启动继续生效。

## 常见问题

### 显示“不可用”或灰色状态点

请依次确认：

1. 官方 ChatGPT 桌面应用已安装在 `/Applications/ChatGPT.app`（或使用旧版 `/Applications/Codex.app`）。
2. ChatGPT/Codex 已登录账号，且能在其设置中看到额度。
3. 退出并重新启动 Codex HUD。

### 悬浮组件挡住了点击

双击开启鼠标穿透。需要调整位置或打开菜单时，按 `Command + Shift + H` 恢复交互。

### 找不到悬浮组件

按 `Command + Shift + H` 恢复交互，然后右键选择“恢复默认位置”。如仍未出现，退出后重新打开应用。

### 如何卸载

先在右键菜单中关闭“登录时启动”并退出，然后删除“应用程序”中的 `Codex HUD.app`。

## 隐私与安全

Codex HUD 仅启动官方 ChatGPT/Codex 应用内置的本机命令。当前版本优先使用：

```text
/Applications/ChatGPT.app/Contents/Resources/codex app-server --stdio
```

若不存在，再依次尝试旧版 `/Applications/Codex.app/Contents/Resources/codex` 和 PATH 中的 `codex`。

它只发送 `initialize` 和只读的 `account/rateLimits/read` 请求。应用不会：

- 调用额度重置的 consume 方法；
- 读取、保存或上传认证令牌；
- 要求 API Key；
- 启动网络监听端口；
- 收集遥测或使用情况数据。

你可以在 [`CodexAppServerClient.swift`](Sources/CodexHUD/Data/CodexAppServerClient.swift) 中审查完整调用实现。

## 从源码构建

需要 Xcode Command Line Tools 与 Swift 6：

```bash
git clone git@github.com:lyqandhh/codex-hub.git
cd codex-hub
swift test
./scripts/install-app.sh
```

安装脚本会生成 Release 构建，将应用安装到 `~/Applications/Codex HUD.app`，然后启动它。

仅构建应用包：

```bash
./scripts/build-app.sh
```

生成结果位于 `dist/Codex HUD.app`。

## 参与贡献

欢迎提交 Issue 和 Pull Request。提交前请运行：

```bash
swift test
swift build -c release
```

## 许可证

[MIT License](LICENSE)
