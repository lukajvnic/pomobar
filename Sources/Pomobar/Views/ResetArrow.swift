import SwiftUI

/// Counterclockwise "restart" arrow, drawn by hand because the SF Symbol's head is small
/// and its gap tight, which reads as lopsided next to the play and forward glyphs.
struct ResetArrow: Shape {
    func path(in rect: CGRect) -> Path {
        // Design space is 100×100 with y up: ring radius 34, stroke 12.5,
        // tail at 168° (about 10 o'clock), head base at 92° (just past 12 o'clock).
        let center = CGPoint(x: 50, y: 50)
        let radius: CGFloat = 34
        let tail = 168 * CGFloat.pi / 180
        let base = 92 * CGFloat.pi / 180
        let headLength: CGFloat = 22
        let headWidth: CGFloat = 34

        let arc = CGMutablePath()
        arc.addArc(center: center, radius: radius, startAngle: tail, endAngle: base + 2 * .pi, clockwise: false)

        let p = CGPoint(x: center.x + radius * cos(base), y: center.y + radius * sin(base))
        let along = CGVector(dx: -sin(base), dy: cos(base))
        let across = CGVector(dx: cos(base), dy: sin(base))
        let head = CGMutablePath()
        head.addLines(between: [
            CGPoint(x: p.x + across.dx * headWidth / 2, y: p.y + across.dy * headWidth / 2),
            CGPoint(x: p.x + along.dx * headLength, y: p.y + along.dy * headLength),
            CGPoint(x: p.x - across.dx * headWidth / 2, y: p.y - across.dy * headWidth / 2),
        ])
        head.closeSubpath()

        let glyph = arc.copy(strokingWithWidth: 12.5, lineCap: .round, lineJoin: .round, miterLimit: 10)
            .union(head)
            // A thin round stroke softens the head's corners like SF Symbols.
            .union(head.copy(strokingWithWidth: 3, lineCap: .round, lineJoin: .round, miterLimit: 10))

        // Center the glyph's bounds in rect and flip into SwiftUI's y-down space.
        let bounds = glyph.boundingBoxOfPath
        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        let transform = CGAffineTransform(translationX: rect.midX, y: rect.midY)
            .scaledBy(x: scale, y: -scale)
            .translatedBy(x: -bounds.midX, y: -bounds.midY)
        return Path(glyph).applying(transform)
    }
}

extension ResetArrow {
    /// As a template image, so it gets the same vibrancy on glass as the SF Symbols beside it.
    @MainActor static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 19, height: 19), flipped: true) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.addPath(ResetArrow().path(in: rect).cgPath)
            context.setFillColor(NSColor.black.cgColor)
            context.fillPath()
            return true
        }
        image.isTemplate = true
        return image
    }()
}
