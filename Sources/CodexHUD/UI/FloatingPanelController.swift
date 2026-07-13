import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingPanelController: NSWindowController, NSWindowDelegate {
    static let size = NSSize(width: 390, height: 52)

    private let store: QuotaStore
    private let preferences: PreferencesStore
    private let loginItemManager: LoginItemManager
    private var cancellables: Set<AnyCancellable> = []

    init(store: QuotaStore, preferences: PreferencesStore, loginItemManager: LoginItemManager) {
        self.store = store
        self.preferences = preferences
        self.loginItemManager = loginItemManager

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init(window: panel)
        configure(panel)
        installContent()
        restorePosition()
        applyMousePassthrough()
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        window?.orderFrontRegardless()
    }

    func toggleMousePassthrough() {
        preferences.mousePassthrough.toggle()
        applyMousePassthrough()
    }

    func disableMousePassthrough() {
        guard preferences.mousePassthrough else { return }
        preferences.mousePassthrough = false
        applyMousePassthrough()
    }

    func resetPosition() {
        preferences.windowOrigin = nil
        positionAtTopRight()
    }

    func windowDidMove(_ notification: Notification) {
        preferences.windowOrigin = window?.frame.origin
    }

    private func configure(_ panel: NSPanel) {
        panel.delegate = self
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.animationBehavior = .utilityWindow
    }

    private func installContent() {
        let view = QuotaCapsuleView(
            store: store,
            preferences: preferences,
            loginItemManager: loginItemManager,
            onRefresh: { [weak store] in Task { await store?.refresh() } },
            onTogglePassthrough: { [weak self] in self?.toggleMousePassthrough() },
            onResetPosition: { [weak self] in self?.resetPosition() }
        )
        window?.contentView = NSHostingView(rootView: view)
    }

    private func restorePosition() {
        if let origin = preferences.windowOrigin, isVisibleOnAnyScreen(origin: origin) {
            window?.setFrameOrigin(origin)
        } else {
            positionAtTopRight()
        }
    }

    private func positionAtTopRight() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame
        window?.setFrameOrigin(NSPoint(x: frame.maxX - Self.size.width - 18, y: frame.maxY - Self.size.height - 18))
    }

    private func isVisibleOnAnyScreen(origin: CGPoint) -> Bool {
        let proposed = NSRect(origin: origin, size: Self.size)
        return NSScreen.screens.contains { $0.visibleFrame.intersects(proposed) }
    }

    private func applyMousePassthrough() {
        window?.ignoresMouseEvents = preferences.mousePassthrough
    }
}
