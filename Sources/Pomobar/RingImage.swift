import AppKit

/// The menu bar glyph: a small ring that empties clockwise as the session runs.
enum RingImage {
    static func make(progress: Double, phase: Phase, dimmed: Bool) -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            let lineWidth: CGFloat = 2.25
            let ring = rect.insetBy(dx: 1.5 + lineWidth / 2, dy: 1.5 + lineWidth / 2)
            let center = NSPoint(x: ring.midX, y: ring.midY)
            let radius = ring.width / 2

            // Resolved at draw time, so it follows the menu bar's light/dark appearance.
            NSColor.labelColor.withAlphaComponent(0.22).setStroke()
            let track = NSBezierPath(ovalIn: ring)
            track.lineWidth = lineWidth
            track.stroke()

            let fraction = min(max(progress, 0), 1)
            guard fraction > 0.001 else { return true }
            // Elapsed time sweeps clockwise from 12 o'clock like a clock hand; the arc is what's left.
            let arc = NSBezierPath()
            arc.appendArc(withCenter: center, radius: radius,
                          startAngle: 90, endAngle: 90 + 360 * fraction, clockwise: false)
            arc.lineWidth = lineWidth
            arc.lineCapStyle = .round
            Theme.color(for: phase).withAlphaComponent(dimmed ? 0.45 : 1).setStroke()
            arc.stroke()
            return true
        }
        image.isTemplate = false
        return image
    }
}
