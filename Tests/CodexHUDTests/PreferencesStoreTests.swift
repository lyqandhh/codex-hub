import CoreGraphics
import Foundation
import Testing
@testable import CodexHUD

@MainActor
struct PreferencesStoreTests {
    @Test func opacityIsClamped() {
        let defaults = makeDefaults()
        let store = PreferencesStore(defaults: defaults)
        store.opacity = 2
        #expect(store.opacity == 1)
        store.opacity = 0.1
        #expect(store.opacity == 0.35)
    }

    @Test func mousePassthroughPersists() {
        let defaults = makeDefaults()
        let store = PreferencesStore(defaults: defaults)
        store.mousePassthrough = true
        #expect(PreferencesStore(defaults: defaults).mousePassthrough)
    }

    @Test func windowOriginRoundTrips() {
        let defaults = makeDefaults()
        let store = PreferencesStore(defaults: defaults)
        store.windowOrigin = CGPoint(x: 123.5, y: 456.25)
        #expect(PreferencesStore(defaults: defaults).windowOrigin == CGPoint(x: 123.5, y: 456.25))
    }

    private func makeDefaults() -> UserDefaults {
        let suite = "CodexHUDTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
