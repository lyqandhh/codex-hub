import AppKit
import Carbon

@MainActor
final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData else { return noErr }
            let owner = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
            Task { @MainActor in owner.action() }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        let id = EventHotKeyID(signature: OSType(0x43484448), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_H), UInt32(cmdKey | shiftKey), id, GetApplicationEventTarget(), 0, &hotKeyRef)

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard Self.isRecoveryShortcut(event) else { return }
            Task { @MainActor in self?.action() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard Self.isRecoveryShortcut(event) else { return event }
            self?.action()
            return nil
        }
    }

    private static func isRecoveryShortcut(_ event: NSEvent) -> Bool {
        event.keyCode == UInt16(kVK_ANSI_H)
            && event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains([.command, .shift])
    }
}
