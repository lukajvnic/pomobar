import AppKit
import SwiftUI

/// Borderless Liquid Glass panel, the same material as Control Center and the battery menu.
final class GlassPanel: NSPanel {
    var onClose: (() -> Void)?
    /// Bottom of the menu bar; resizing keeps the panel's top edge here.
    var topEdge: CGFloat?

    init<Content: View>(rootView: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Theme.panelWidth, height: 300),
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

        let hosting = NSHostingView(rootView: rootView)
        hosting.sizingOptions = []
        let glass = NSGlassEffectView()
        glass.style = .regular
        glass.cornerRadius = Theme.panelCorner
        glass.contentView = hosting
        contentView = GlassContainer(glass: glass)
    }

    override var canBecomeKey: Bool { true }

    /// Esc
    override func cancelOperation(_ sender: Any?) {
        onClose?()
    }

    /// Keeps the top edge pinned while the content changes height; animated while on screen.
    func fit(height: CGFloat) {
        guard height > 0, abs(frame.height - height) > 0.5 else { return }
        var rect = frame
        rect.origin.y = (topEdge ?? rect.maxY) - height
        rect.size.height = height
        guard isVisible else {
            setFrame(rect, display: true)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animator().setFrame(rect, display: true)
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.invalidateShadow() }
        }
    }
}

/// Rounded, clipped window content that keeps the glass and its SwiftUI content exactly
/// window-sized. Autoresizing drifts here, so frames are pinned by hand.
private final class GlassContainer: NSView {
    private let glass: NSGlassEffectView

    init(glass: NSGlassEffectView) {
        self.glass = glass
        super.init(frame: .zero)
        // Clipping makes the window shadow follow the rounded corners, not the rectangle.
        wantsLayer = true
        layer?.cornerRadius = Theme.panelCorner
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
        addSubview(glass)
    }

    required init?(coder: NSCoder) { fatalError() }

    // The window sometimes applies a resize to its content view twice, leaving a strip
    // of empty window above the glass. Always take the window's real size.
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(window?.frame.size ?? newSize)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        glass.frame = bounds
        glass.contentView?.frame = glass.bounds
    }
}
