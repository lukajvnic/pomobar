import SwiftUI

/// Timer page and settings page side by side; the gear slides between them.
/// Both pages stay laid out so the panel keeps one height and never resizes mid-slide.
struct PanelView: View {
    let model: AppModel
    var onSize: (CGSize) -> Void

    var body: some View {
        let settings = model.showingSettings
        ZStack(alignment: .top) {
            TimerPage(model: model)
                .offset(x: settings ? -Theme.panelWidth : 0)
                .allowsHitTesting(!settings)
                .accessibilityHidden(settings)
            SettingsView(model: model)
                .offset(x: settings ? 0 : Theme.panelWidth)
                .allowsHitTesting(settings)
                .accessibilityHidden(!settings)
        }
        .frame(width: Theme.panelWidth)
        .clipped()
        .animation(.smooth(duration: 0.32), value: settings)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { onSize($0) }
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
                }
                .padding(.bottom, 18)

            DonutView(
                progress: engine.progress,
                color: engine.phase.color,
                time: engine.secondsLeft.clock,
                caption: caption
            )
            .padding(.bottom, 18)

            HStack(spacing: 24) {
                RoundButton(symbol: "arrow.counterclockwise") { model.reset() }
                    .help("Restart this session")
                RoundButton(
                    symbol: engine.isRunning ? "pause.fill" : "play.fill",
                    diameter: 54,
                    tint: engine.phase.color
                ) { model.toggle() }
                    .help(engine.isRunning ? "Pause" : "Start")
                RoundButton(symbol: "forward.end.fill") { model.skip() }
                    .help("Skip to \(engine.phase.next.title.lowercased())")
            }
        }
        .padding(16)
        .padding(.bottom, 4)
        .frame(width: Theme.panelWidth)
    }
}
