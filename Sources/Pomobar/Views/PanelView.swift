import SwiftUI

/// Timer page and settings page side by side; the gear slides between them.
/// The panel takes the height of whichever page is showing.
struct PanelView: View {
    let model: AppModel
    var onHeight: (CGFloat) -> Void

    @State private var timerHeight: CGFloat = 0
    @State private var settingsHeight: CGFloat = 0

    var body: some View {
        let settings = model.showingSettings
        let height = settings ? settingsHeight : timerHeight
        ZStack(alignment: .top) {
            TimerPage(model: model)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { timerHeight = $0 }
                .offset(x: settings ? -Theme.panelWidth : 0)
                .allowsHitTesting(!settings)
                .accessibilityHidden(settings)
            SettingsView(model: model)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { settingsHeight = $0 }
                .offset(x: settings ? 0 : Theme.panelWidth)
                .allowsHitTesting(settings)
                .accessibilityHidden(!settings)
        }
        .frame(width: Theme.panelWidth, height: height, alignment: .top)
        .clipped()
        .animation(.smooth(duration: 0.3), value: settings)
        // The window animates its own height, so keep content pinned to the top meanwhile.
        .frame(maxHeight: .infinity, alignment: .top)
        .onChange(of: height, initial: true) { onHeight(height) }
    }
}

private struct TimerPage: View {
    let model: AppModel

    private var engine: TimerEngine { model.engine }

    private var caption: String {
        if engine.isRunning || engine.isFresh { return engine.phase.title }
        return "Paused"
    }

    var body: some View {
        VStack(spacing: 0) {
            ModePicker(selection: model.prefs.mode, tint: engine.phase.color) { model.setMode($0) }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    PlainButton(symbol: "gearshape") { model.showingSettings = true }
                        .help("Settings")
                        .padding(.trailing, -6)
                }
                .padding(.bottom, 12)

            DonutView(
                progress: engine.progress,
                color: engine.phase.color,
                time: engine.secondsLeft.clock,
                caption: caption
            )
            .padding(.bottom, 8)

            HStack(spacing: 22) {
                RoundButton(size: 18) { model.reset() } glyph: {
                    Image(nsImage: ResetArrow.image)
                }
                .help("Restart this session")
                RoundButton(symbol: engine.isRunning ? "pause.fill" : "play.fill", size: 24) { model.toggle() }
                    .help(engine.isRunning ? "Pause" : "Start")
                RoundButton(symbol: "forward.fill", size: 18) { model.skip() }
                    .help("Skip to \(engine.phase.next.title.lowercased())")
            }
        }
        .padding(14)
        .frame(width: Theme.panelWidth)
    }
}
