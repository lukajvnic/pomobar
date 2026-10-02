import Foundation

/// Schedules a push on ntfy.sh for one minute before a break ends.
/// The server holds the message, so it still arrives if the Mac goes to sleep.
@MainActor
final class PhoneRelay {
    private static let server = URL(string: "https://ntfy.sh")!
    private static let sequenceID = "pomobar-break"
    private static let warning: TimeInterval = 60

    private var pending: (topic: String, fireDate: Date)?
    private var queue: Task<Void, Never>?

    func scheduleBreakWarning(topic: String, breakEnds endDate: Date) {
        let lead = endDate.timeIntervalSinceNow - Self.warning
        guard lead > 0 else {
            cancel()
            return
        }

        var request = URLRequest(url: Self.server.appending(path: topic).appending(path: Self.sequenceID))
        request.httpMethod = "POST"
        // ntfy's minimum delay is 10 s; anything shorter goes out right away.
        if lead >= 10 {
            request.setValue("\(Int(lead))s", forHTTPHeaderField: "In")
        }
        request.setValue("Break ends in 1 minute", forHTTPHeaderField: "Title")
        request.setValue("high", forHTTPHeaderField: "Priority")
        request.httpBody = Data("Focus starts at \(endDate.formatted(date: .omitted, time: .shortened)).".utf8)

        if let pending, pending.topic != topic {
            enqueue(Self.deleteRequest(topic: pending.topic))
        }
        pending = (topic, Date().addingTimeInterval(lead))
        enqueue(request)
    }

    /// Withdraws the scheduled message if it hasn't gone out yet.
    func cancel() {
        guard let pending else { return }
        self.pending = nil
        if pending.fireDate > Date() {
            enqueue(Self.deleteRequest(topic: pending.topic))
        }
    }

    /// Blocking cancel for app termination.
    func cancelSynchronously() {
        guard let pending, pending.fireDate > Date() else { return }
        self.pending = nil
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: Self.deleteRequest(topic: pending.topic)) { _, _, _ in
            done.signal()
        }.resume()
        _ = done.wait(timeout: .now() + 1.5)
    }

    func sendTest(topic: String) async -> Bool {
        var request = URLRequest(url: Self.server.appending(path: topic))
        request.httpMethod = "POST"
        request.setValue("Pomobar", forHTTPHeaderField: "Title")
        request.httpBody = Data("You'll get a heads-up here a minute before each break ends.".utf8)
        let response = try? await URLSession.shared.data(for: request).1
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    /// Requests run in order so a quick start → pause can't land as delete → schedule.
    private func enqueue(_ request: URLRequest) {
        let previous = queue
        queue = Task {
            await previous?.value
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    private static func deleteRequest(topic: String) -> URLRequest {
        var request = URLRequest(url: server.appending(path: topic).appending(path: sequenceID))
        request.httpMethod = "DELETE"
        return request
    }
}
