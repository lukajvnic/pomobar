import Foundation
import Observation

enum Mode: String, CaseIterable, Identifiable {
    case short, long

    var id: String { rawValue }
    var label: String { self == .short ? "25 / 5" : "60 / 10" }

    func minutes(for phase: Phase) -> Int {
        switch (self, phase) {
        case (.short, .work): 25
        case (.short, .rest): 5
        case (.long, .work): 60
        case (.long, .rest): 10
        }
    }
}

enum Phase {
    case work, rest

    var next: Phase { self == .work ? .rest : .work }
    var title: String { self == .work ? "Focus" : "Break" }
}

/// Pure countdown state. Time is derived from an end date so it survives sleep and timer drift.
@MainActor @Observable
final class TimerEngine {
    private(set) var mode: Mode
    private(set) var phase: Phase = .work
    private(set) var remaining: TimeInterval
    private(set) var isRunning = false

    @ObservationIgnored private(set) var endDate: Date?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored var onFinish: ((Phase) -> Void)?

    /// `POMOBAR_SCALE=0.02` turns 25 minutes into 30 seconds for testing.
    private static let scale = ProcessInfo.processInfo.environment["POMOBAR_SCALE"].flatMap(Double.init) ?? 1

    init(mode: Mode) {
        self.mode = mode
        self.remaining = Self.duration(of: .work, in: mode)
    }

    static func duration(of phase: Phase, in mode: Mode) -> TimeInterval {
        Double(mode.minutes(for: phase) * 60) * scale
    }

    var duration: TimeInterval { Self.duration(of: phase, in: mode) }
    var progress: Double { duration > 0 ? remaining / duration : 0 }
    var secondsLeft: Int { Int(remaining.rounded(.up)) }
    var isFresh: Bool { remaining >= duration - 0.001 }

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    func pause() {
        guard isRunning else { return }
        tick()
        stop()
    }

    /// Back to the start of the current session.
    func reset() {
        stop()
        remaining = duration
    }

    /// Jump to the next session without alarms.
    func skip() {
        advance()
    }

    func setMode(_ mode: Mode) {
        self.mode = mode
        reset()
    }

    func tick() {
        guard isRunning, let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        if remaining == 0 {
            let finished = phase
            advance()
            onFinish?(finished)
        }
    }

    private func advance() {
        stop()
        phase = phase.next
        remaining = duration
    }

    private func stop() {
        ticker?.invalidate()
        ticker = nil
        endDate = nil
        isRunning = false
    }
}

extension Int {
    /// 1500 → "25:00"
    var clock: String { String(format: "%d:%02d", self / 60, self % 60) }
}
