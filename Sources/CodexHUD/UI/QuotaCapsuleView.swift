import SwiftUI

struct QuotaCapsuleView: View {
    @ObservedObject var store: QuotaStore
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var loginItemManager: LoginItemManager
    let onRefresh: () -> Void
    let onTogglePassthrough: () -> Void
    let onResetPosition: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            Color(red: 0.025, green: 0.03, blue: 0.045).opacity(0.82)

            content
                .padding(.horizontal, 18)
                .padding(.bottom, 3)

            GeometryReader { proxy in
                Capsule()
                    .fill(progressFill)
                    .frame(width: proxy.size.width * progress, height: 3)
                    .shadow(color: progressColor.opacity(0.5), radius: 3)
                    .animation(.easeOut(duration: 0.35), value: progress)
            }
            .frame(height: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
        .opacity(preferences.opacity)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture(count: 2, perform: onTogglePassthrough)
        .contextMenu { contextMenu }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = store.state.snapshot {
            HStack(spacing: 15) {
                metric("1周", value: QuotaFormatting.percent(snapshot.remainingFraction))
                separator
                Text(QuotaFormatting.credits(snapshot.resetCredits))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.94))
                separator
                Text(QuotaFormatting.resetDate(snapshot.resetsAt))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                statusDot
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HStack(spacing: 12) {
                ProgressView().controlSize(.small).tint(.white.opacity(0.8))
                Text(store.state == .loading ? "正在读取 Codex 额度" : "额度暂不可用")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                Spacer()
                statusDot
            }
        }
    }

    private func metric(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
    }

    private var separator: some View {
        Circle().fill(Color.white.opacity(0.24)).frame(width: 3, height: 3)
    }

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 7, height: 7)
            .shadow(color: statusColor.opacity(0.5), radius: 3)
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("立即刷新", action: onRefresh)
        Button(preferences.mousePassthrough ? "关闭鼠标穿透" : "开启鼠标穿透", action: onTogglePassthrough)
        Menu("透明度") {
            ForEach([0.55, 0.7, 0.85, 1.0], id: \.self) { value in
                Button("\(Int(value * 100))%") { preferences.opacity = value }
            }
        }
        Button(loginItemManager.isEnabled ? "关闭登录时启动" : "登录时启动") {
            loginItemManager.toggle()
        }
        Button("恢复默认位置", action: onResetPosition)
        Divider()
        Button("退出 Codex HUD") { NSApplication.shared.terminate(nil) }
    }

    private var progress: Double { store.state.snapshot?.remainingFraction ?? 0 }
    private var progressColor: Color {
        switch progress {
        case ..<0.2: Color(red: 1, green: 0.34, blue: 0.2)
        case ..<0.5: Color(red: 1, green: 0.72, blue: 0.18)
        default: Color(red: 0.28, green: 0.9, blue: 0.5)
        }
    }
    private var progressFill: some ShapeStyle {
        LinearGradient(
            colors: progress < 0.2
                ? [Color(red: 1, green: 0.25, blue: 0.18), Color(red: 1, green: 0.48, blue: 0.16)]
                : [Color(red: 0.24, green: 0.96, blue: 0.48), Color(red: 0.92, green: 0.93, blue: 0.18), Color(red: 1, green: 0.48, blue: 0.08)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    private var statusColor: Color {
        switch store.state {
        case .live: Color(red: 0.27, green: 0.93, blue: 0.54)
        case .stale: Color(red: 1, green: 0.7, blue: 0.2)
        case .loading, .unavailable: Color.white.opacity(0.38)
        }
    }
    private var accessibilityText: String {
        guard let snapshot = store.state.snapshot else { return "Codex 额度暂不可用" }
        return "Codex 本周剩余 \(QuotaFormatting.percent(snapshot.remainingFraction))，\(QuotaFormatting.credits(snapshot.resetCredits))，\(QuotaFormatting.resetDate(snapshot.resetsAt))重置"
    }
}

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
    }
}
