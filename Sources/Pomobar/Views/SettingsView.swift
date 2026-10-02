import SwiftUI

struct SettingsView: View {
    let model: AppModel

    @State private var testState: TestState = .idle
    @State private var copied = false
    @State private var launchAtLogin = false

    private enum TestState { case idle, sending, sent, failed }

    var body: some View {
        let prefs = model.prefs
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 2) {
                PlainButton(symbol: "chevron.left") { model.showingSettings = false }
                    .help("Back")
                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.leading, -6)
            .frame(height: 28)
            .padding(.bottom, 10)

            ToggleRow(symbol: "bell", title: "Alarm sound", isOn: Binding(
                get: { prefs.soundOn }, set: { prefs.soundOn = $0 }
            ))
            ToggleRow(symbol: "iphone", title: "iPhone alert", detail: "1 min before a break ends", isOn: Binding(
                get: { prefs.phoneOn }, set: { model.setPhoneAlerts($0) }
            ))
            ToggleRow(symbol: "power", title: "Open at login", isOn: Binding(
                get: { launchAtLogin },
                set: { model.launchAtLogin = $0; launchAtLogin = model.launchAtLogin }
            ))

            Divider().padding(.vertical, 12)

            Text("Subscribe to this topic in the ntfy iPhone app. Keep it private.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)

            HStack(spacing: 6) {
                Text(prefs.topic)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
                    .background(.primary.opacity(0.06), in: .rect(cornerRadius: 7))
                RoundButton(symbol: copied ? "checkmark" : "doc.on.doc", diameter: 26) { copyTopic() }
                    .help("Copy topic")
            }
            .padding(.bottom, 6)

            HStack(spacing: 6) {
                PlainButton(title: "Send test", symbol: "paperplane") { sendTest() }
                    .disabled(testState == .sending)
                Text(testLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, -6)

            Spacer(minLength: 12)

            PlainButton(title: "Quit Pomobar") { NSApp.terminate(nil) }
                .padding(.leading, -6)
        }
        .padding(16)
        .frame(width: Theme.panelWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear { launchAtLogin = model.launchAtLogin }
        .onChange(of: model.showingSettings) {
            launchAtLogin = model.launchAtLogin
            testState = .idle
        }
    }

    private var testLabel: String {
        switch testState {
        case .idle: ""
        case .sending: "Sending…"
        case .sent: "Sent. Check your phone."
        case .failed: "Couldn't reach ntfy.sh"
        }
    }

    private func copyTopic() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(model.prefs.topic, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            copied = false
        }
    }

    private func sendTest() {
        testState = .sending
        Task {
            testState = await model.relay.sendTest(topic: model.prefs.topic) ? .sent : .failed
        }
    }
}
