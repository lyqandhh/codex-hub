import AppKit
import Foundation
import Testing
@testable import CodexHUD

@MainActor
struct FloatingPanelTransparencyTests {
    @Test func hostingSurfaceMasksVisualEffectToRoundedCorners() {
        let suite = "FloatingPanelTransparencyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let controller = FloatingPanelController(
            store: QuotaStore(),
            preferences: PreferencesStore(defaults: defaults),
            loginItemManager: LoginItemManager()
        )

        let contentView = controller.window?.contentView
        #expect(contentView?.wantsLayer == true)
        #expect(contentView?.layer?.masksToBounds == true)
        #expect(contentView?.layer?.cornerRadius == 18)
        #expect(contentView?.layer?.backgroundColor?.alpha == 0)
    }
}
