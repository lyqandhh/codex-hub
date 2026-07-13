import AppKit
import Combine
import ServiceManagement

@MainActor
final class LoginItemManager: ObservableObject {
    @Published private(set) var isEnabled = SMAppService.mainApp.status == .enabled

    func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            isEnabled = SMAppService.mainApp.status == .enabled
        } catch {
            NSSound.beep()
        }
    }
}
