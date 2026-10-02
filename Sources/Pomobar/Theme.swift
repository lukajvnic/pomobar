import AppKit
import SwiftUI

enum Theme {
    /// Muted tomato red for focus sessions.
    static let work = dynamic(light: (0.85, 0.30, 0.27), dark: (0.94, 0.39, 0.35))
    /// Calm blue for breaks.
    static let rest = dynamic(light: (0.24, 0.50, 0.85), dark: (0.36, 0.60, 0.93))

    static let panelWidth: CGFloat = 300
    static let panelCorner: CGFloat = 18

    static func color(for phase: Phase) -> NSColor {
        phase == .work ? work : rest
    }

    private static func dynamic(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> NSColor {
        NSColor(name: nil) { appearance in
            let c = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: 1)
        }
    }
}

extension Phase {
    var color: Color { Color(nsColor: Theme.color(for: self)) }
}
