import Foundation
import Observation

@MainActor @Observable
final class Preferences {
    @ObservationIgnored private let defaults = UserDefaults.standard

    var mode: Mode {
        didSet { defaults.set(mode.rawValue, forKey: "mode") }
    }
    var soundOn: Bool {
        didSet { defaults.set(soundOn, forKey: "soundOn") }
    }
    var phoneOn: Bool {
        didSet { defaults.set(phoneOn, forKey: "phoneOn") }
    }
    var topic: String {
        didSet { defaults.set(topic, forKey: "topic") }
    }

    init() {
        defaults.register(defaults: ["soundOn": true, "phoneOn": false])
        mode = Mode(rawValue: defaults.string(forKey: "mode") ?? "") ?? .short
        soundOn = defaults.bool(forKey: "soundOn")
        phoneOn = defaults.bool(forKey: "phoneOn")
        if let saved = defaults.string(forKey: "topic"), !saved.isEmpty {
            topic = saved
        } else {
            // ntfy.sh topics are public, so the name doubles as the password.
            let chars = Array("abcdefghijkmnpqrstuvwxyz23456789")
            topic = "pomobar-" + String((0..<16).map { _ in chars.randomElement()! })
            defaults.set(topic, forKey: "topic")
        }
    }
}
