## Codex HUD v1.0.0

首个公开版本。Codex HUD 是一枚原生 macOS 悬浮组件，用紧凑的 `118 × 46 pt` 胶囊持续显示 Codex 周额度。

### 主要功能

- 圆环显示周剩余额度百分比。
- 显示可用额度重置次数与下次重置日期。
- 每 60 秒自动刷新，并通过状态点反馈数据新鲜度。
- 支持拖动、透明度、鼠标穿透、登录时启动与位置恢复。
- 本地只读访问 Codex app-server，不需要 API Key，不上传数据。

### 安装

1. 下载并解压 `Codex-HUD-v1.0.0-macOS.zip`。
2. 将 `Codex HUD.app` 拖入“应用程序”文件夹。
3. 确保官方 Codex 桌面应用已经安装并登录。
4. 首次启动若被 macOS 拦截，请 Control 点击应用并选择“打开”。

系统要求：macOS 14 Sonoma 或更高版本。

> 当前版本使用临时签名，尚未经过 Apple Developer ID 公证。完整安装说明与安全说明请查看 README。
