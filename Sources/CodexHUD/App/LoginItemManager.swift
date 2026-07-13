import AppKit
import ServiceManagement

@MainActor
final class LoginItemManager {
    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSSound.beep()
        }
    }
}
