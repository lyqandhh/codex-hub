import AppKit

public enum CodexHUDLauncher {
    @MainActor
    public static func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = QuotaStore()
    private let preferences = PreferencesStore()
    private let loginItemManager = LoginItemManager()
    private var panelController: FloatingPanelController?
    private var globalHotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panel = FloatingPanelController(store: store, preferences: preferences, loginItemManager: loginItemManager)
        panelController = panel
        globalHotKey = GlobalHotKey { [weak panel] in panel?.disableMousePassthrough() }
        panel.show()
        store.startAutoRefresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stopAutoRefresh()
    }
}
