import Foundation
import Observation
import ServiceManagement

/// Ties the timer to its side effects: alarm, notifications, iPhone push.
@MainActor @Observable
final class AppModel {
    let prefs = Preferences()
    let engine: TimerEngine
    var showingSettings = false

    @ObservationIgnored let alerts = Alerts()
    @ObservationIgnored let relay = PhoneRelay()

    init() {
        engine = TimerEngine(mode: prefs.mode)
        engine.onFinish = { [weak self] phase in self?.sessionFinished(phase) }
    }

    func toggle() {
        engine.toggle()
        syncPhone()
    }

    func reset() {
        engine.reset()
        syncPhone()
    }

    func skip() {
        engine.skip()
        syncPhone()
    }

    func setMode(_ mode: Mode) {
        guard mode != prefs.mode else { return }
        prefs.mode = mode
        engine.setMode(mode)
        syncPhone()
    }

    func setPhoneAlerts(_ on: Bool) {
        prefs.phoneOn = on
        syncPhone()
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        }
    }

    /// Start at login by default, once, for the installed copy only (not dev builds).
    func enableLaunchAtLoginOnFirstRun() {
        let key = "loginItemConfigured"
        guard !UserDefaults.standard.bool(forKey: key),
              Bundle.main.bundlePath.hasPrefix("/Applications/") else { return }
        launchAtLogin = true
        UserDefaults.standard.set(true, forKey: key)
    }

    private func sessionFinished(_ phase: Phase) {
        if prefs.soundOn { alerts.playAlarm() }
        alerts.sessionFinished(phase, mode: prefs.mode)
        syncPhone()
    }

    private func syncPhone() {
        if prefs.phoneOn, engine.phase == .rest, let endDate = engine.endDate {
            relay.scheduleBreakWarning(topic: prefs.topic, breakEnds: endDate)
        } else {
            relay.cancel()
        }
    }
}
