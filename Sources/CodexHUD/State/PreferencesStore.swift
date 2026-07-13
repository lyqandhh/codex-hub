import Combine
import CoreGraphics
import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
    private enum Key {
        static let opacity = "hud.opacity"
        static let mousePassthrough = "hud.mousePassthrough"
        static let windowX = "hud.windowX"
        static let windowY = "hud.windowY"
        static let hasWindowOrigin = "hud.hasWindowOrigin"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var opacity: Double {
        get {
            guard defaults.object(forKey: Key.opacity) != nil else { return 0.92 }
            return min(max(defaults.double(forKey: Key.opacity), 0.35), 1)
        }
        set {
            objectWillChange.send()
            defaults.set(min(max(newValue, 0.35), 1), forKey: Key.opacity)
        }
    }

    var mousePassthrough: Bool {
        get { defaults.bool(forKey: Key.mousePassthrough) }
        set {
            objectWillChange.send()
            defaults.set(newValue, forKey: Key.mousePassthrough)
        }
    }

    var windowOrigin: CGPoint? {
        get {
            guard defaults.bool(forKey: Key.hasWindowOrigin) else { return nil }
            return CGPoint(x: defaults.double(forKey: Key.windowX), y: defaults.double(forKey: Key.windowY))
        }
        set {
            objectWillChange.send()
            guard let newValue else {
                defaults.set(false, forKey: Key.hasWindowOrigin)
                return
            }
            defaults.set(newValue.x, forKey: Key.windowX)
            defaults.set(newValue.y, forKey: Key.windowY)
            defaults.set(true, forKey: Key.hasWindowOrigin)
        }
    }
}
