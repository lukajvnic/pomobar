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
                Spacer()
                PlainButton(title: "Quit") { NSApp.terminate(nil) }
                    .padding(.trailing, -6)
            }
            .padding(.leading, -6)
            .frame(height: 26)
            .padding(.bottom, 8)

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

            Divider().padding(.vertical, 10)

            Text("Subscribe to this topic in the ntfy app.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)

            HStack(spacing: 2) {
                Text(prefs.topic)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                    .background(.primary.opacity(0.06), in: .rect(cornerRadius: 6))
                    .help("Anyone with this name can see your alerts, so keep it private.")
                RoundButton(symbol: copied ? "checkmark" : "doc.on.doc", size: 12) { copyTopic() }
                    .help("Copy topic")
                RoundButton(symbol: testSymbol, size: 12) { sendTest() }
                    .help(testHelp)
                    .disabled(testState == .sending)
            }
        }
        .padding(14)
        .frame(width: Theme.panelWidth)
        .onAppear { launchAtLogin = model.launchAtLogin }
        .onChange(of: model.showingSettings) {
            launchAtLogin = model.launchAtLogin
            testState = .idle
        }
    }

    private var testSymbol: String {
        switch testState {
        case .idle: "paperplane"
        case .sending: "ellipsis"
        case .sent: "checkmark"
        case .failed: "exclamationmark.triangle"
        }
    }

    private var testHelp: String {
        switch testState {
        case .idle, .sending: "Send a test notification"
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
