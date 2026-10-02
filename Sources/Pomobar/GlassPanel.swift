import AppKit
import SwiftUI

/// Borderless Liquid Glass panel, the same material as Control Center and the battery menu.
final class GlassPanel: NSPanel {
    var onClose: (() -> Void)?
    private let container = NSView()
    private let glass = NSGlassEffectView()
    private let hosting: NSView

    init<Content: View>(rootView: Content) {
        let hosting = NSHostingView(rootView: rootView)
        hosting.sizingOptions = []
        self.hosting = hosting
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Theme.panelWidth, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none

        glass.style = .regular
        glass.cornerRadius = Theme.panelCorner
        glass.contentView = hosting
        // Clip to the rounded shape so the window shadow follows the corners, not the rectangle.
        container.wantsLayer = true
        container.layer?.cornerRadius = Theme.panelCorner
        container.layer?.cornerCurve = .continuous
        container.layer?.masksToBounds = true
        container.addSubview(glass)
        contentView = container
    }

    override var canBecomeKey: Bool { true }

    // The panel follows SwiftUI's reported height (see `fit`). Autoresizing drifts here,
    // so pin the glass and its content to the window on every frame change.
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        super.setFrame(frameRect, display: flag)
        container.frame = NSRect(origin: .zero, size: frameRect.size)
        glass.frame = container.bounds
        hosting.frame = glass.bounds
        invalidateShadow()
    }

    /// Esc
    override func cancelOperation(_ sender: Any?) {
        onClose?()
    }

    /// Keeps the top edge pinned while SwiftUI content changes height.
    func fit(height: CGFloat) {
        guard height > 0, abs(frame.height - height) > 0.5 else { return }
        var rect = frame
        rect.origin.y = rect.maxY - height
        rect.size.height = height
        setFrame(rect, display: true)
    }
}
