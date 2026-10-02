import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController(model: model)
        model.alerts.onOpen = { [weak self] in self?.statusItem?.showPanel() }
        model.alerts.setUp()
        model.enableLaunchAtLoginOnFirstRun()

        if ProcessInfo.processInfo.environment["POMOBAR_OPEN"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.statusItem?.showPanel() }
        }

        // The countdown is date-based; catch up immediately after sleep.
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.engine.tick() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.relay.cancelSynchronously()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
