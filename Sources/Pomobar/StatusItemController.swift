import AppKit
import SwiftUI

/// Owns the menu bar item (ring + countdown) and the panel it opens.
@MainActor
final class StatusItemController: NSObject {
    private let model: AppModel
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var panel: GlassPanel!
    private var outsideClickMonitor: Any?
    private var isShown = false
    private var renderedKey = ""

    init(model: AppModel) {
        self.model = model
        super.init()

        if let button = item.button {
            button.target = self
            button.action = #selector(togglePanel)
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }

        panel = GlassPanel(rootView: PanelView(model: model) { [weak self] size in
            self?.panel.fit(height: size.height)
        })
        panel.onClose = { [weak self] in self?.hidePanel() }

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(spaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification, object: nil
        )

        observe()
    }

    // MARK: Menu bar rendering

    private func observe() {
        withObservationTracking {
            render()
        } onChange: { [weak self] in
            Task { @MainActor in self?.observe() }
        }
    }

    private func render() {
        let engine = model.engine
        let seconds = engine.secondsLeft
        let phase = engine.phase
        let running = engine.isRunning
        let progress = engine.progress

        // The engine ticks 4x a second; only redraw when something visible changes.
        let key = "\(seconds)|\(phase)|\(running)"
        guard key != renderedKey, let button = item.button else { return }
        renderedKey = key

        button.image = RingImage.make(progress: progress, phase: phase, dimmed: !running)
        button.title = " " + seconds.clock
        let state = running ? phase.title : (engine.isFresh ? "\(phase.title), ready" : "Paused")
        button.setAccessibilityLabel("Pomobar, \(state), \(seconds.clock) left")
    }

    // MARK: Panel

    @objc private func togglePanel() {
        isShown ? hidePanel() : showPanel()
    }

    func showPanel() {
        guard let button = item.button, let buttonWindow = button.window else { return }
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        guard let screen = buttonWindow.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame

        let height = panel.frame.height
        var x = anchor.minX
        x = min(x, visible.maxX - Theme.panelWidth - 8)
        x = max(x, visible.minX + 8)
        // With an auto-hiding menu bar the button can sit above the screen; never go past the bar/notch.
        let menuBarBottom = screen.frame.maxY - max(NSStatusBar.system.thickness, screen.safeAreaInsets.top)
        let y = min(anchor.minY, menuBarBottom) - 6 - height
        panel.setFrame(NSRect(x: x, y: y, width: Theme.panelWidth, height: height), display: true)

        isShown = true
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            panel.animator().alphaValue = 1
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.panel.invalidateShadow() }
        }
        button.highlight(true)

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.hidePanel() }
        }
    }

    func hidePanel() {
        guard isShown else { return }
        isShown = false
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
        item.button?.highlight(false)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.isShown else { return }
                self.panel.orderOut(nil)
                self.model.showingSettings = false
            }
        }
    }

    @objc private func spaceChanged() {
        hidePanel()
    }
}
