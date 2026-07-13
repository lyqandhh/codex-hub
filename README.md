# Codex HUD

Codex HUD 是一个原生 macOS 悬浮组件，常驻显示 Codex 的周剩余额度、可用重置次数和重置日期，无需打开设置或点击菜单栏。

## 显示内容

胶囊默认显示：

```text
1周 99% · 重置 ×3 · 7月20日
```

底部细线表示周剩余额度；额度低于 50% 时变黄，低于 20% 时变为橙红色。右侧状态点为绿色时数据实时，黄色时表示正在显示上一次成功数据，灰色表示暂时无法读取。

## 构建与安装

系统要求：macOS 14 或更高版本，并已安装 Codex 桌面应用或 Codex CLI。

```bash
./scripts/install-app.sh
```

应用会安装到 `~/Applications/Codex HUD.app` 并自动启动。它不显示 Dock 图标。

## 使用

- 拖动胶囊可调整位置。
- 双击胶囊可开启或关闭鼠标穿透。
- 穿透开启后，按 `Command + Shift + H` 恢复交互。
- 右键胶囊可立即刷新、调整透明度、设置登录时启动、恢复默认位置或退出。
- 默认每 60 秒自动刷新。

## 隐私与安全

Codex HUD 只调用本机 Codex app-server 的只读 `account/rateLimits/read` 方法。它不会调用重置额度的 consume 方法，不需要 API Key，不读取或记录认证令牌，不上传数据，也不开放监听端口。

## 开发验证

```bash
swift test
swift build -c release
./scripts/build-app.sh
```
