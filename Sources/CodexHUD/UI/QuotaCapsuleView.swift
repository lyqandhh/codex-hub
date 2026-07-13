import SwiftUI

struct QuotaCapsuleView: View {
    @ObservedObject var store: QuotaStore
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var loginItemManager: LoginItemManager
    let onRefresh: () -> Void
    let onTogglePassthrough: () -> Void
    let onResetPosition: () -> Void

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            Color(red: 0.025, green: 0.03, blue: 0.045).opacity(0.82)

            content
                .padding(.horizontal, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.28), radius: 8, y: 4)
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
            HStack(spacing: 10) {
                quotaRing(snapshot.remainingFraction)
                VStack(spacing: 0) {
                    if let credits = QuotaFormatting.compactCredits(snapshot.resetCredits) {
                        Text(credits)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    Text(QuotaFormatting.compactResetDate(snapshot.resetsAt))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.58))
                }
                .frame(minWidth: 28)
                statusDot
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            HStack(spacing: 7) {
                ProgressView().controlSize(.mini).tint(.white.opacity(0.8))
                Text(store.state == .loading ? "读取中" : "不可用")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                statusDot
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func quotaRing(_ remaining: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 2.4)
            Circle()
                .trim(from: 0, to: min(max(remaining, 0), 1))
                .stroke(progressColor, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.35), value: remaining)
            Text(QuotaFormatting.ringValue(remaining))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(width: HUDLayout.ringDiameter, height: HUDLayout.ringDiameter)
    }

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 7, height: 7)
            .shadow(color: statusColor.opacity(0.5), radius: 2)
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
    private var statusColor: Color {
        switch store.state {
        case .live: Color(red: 0.27, green: 0.93, blue: 0.54)
        case .stale: Color(red: 1, green: 0.7, blue: 0.2)
        case .loading, .unavailable: Color.white.opacity(0.38)
        }
    }
    private var accessibilityText: String {
        guard let snapshot = store.state.snapshot else { return "Codex 额度暂不可用" }
        return QuotaFormatting.accessibilitySummary(
            remainingFraction: snapshot.remainingFraction,
            resetCredits: snapshot.resetCredits,
            resetsAt: snapshot.resetsAt
        )
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
