import AppKit
import UserNotifications

/// End-of-session banner and alarm chime.
@MainActor
final class Alerts: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    var onOpen: (() -> Void)?

    func setUp() {
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sessionFinished(_ phase: Phase, mode: Mode) {
        let content = UNMutableNotificationContent()
        if phase == .work {
            content.title = "Focus session done"
            content.body = "Time for a \(mode.minutes(for: .rest)) minute break."
        } else {
            content.title = "Break's over"
            content.body = "Press play when you're ready to focus."
        }
        center.add(UNNotificationRequest(identifier: "session-end", content: content, trigger: nil))
    }

    func playAlarm() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.75) {
                (NSSound(named: "Glass")?.copy() as? NSSound)?.play()
            }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run { onOpen?() }
    }
}
