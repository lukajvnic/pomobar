// Renders the app icon into an .iconset folder: a single tomato-red arc on a warm off-white squircle.
// Usage: swift scripts/make-icon.swift <output.iconset>
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset")
try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    let s = CGFloat(pixels) / 1024
    cg.scaleBy(x: s, y: s)

    // Apple macOS icon grid: 824pt body centered in 1024, ~185pt continuous corners.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
    NSColor(srgbRed: 0.965, green: 0.957, blue: 0.941, alpha: 1).setFill()
    shape.fill()

    // Three quarters of the ring left: the gap reads as fifteen minutes gone.
    let center = CGPoint(x: 512, y: 512)
    let arc = NSBezierPath()
    arc.appendArc(withCenter: center, radius: 228, startAngle: 90, endAngle: 360, clockwise: false)
    arc.lineWidth = 96
    arc.lineCapStyle = .round
    NSColor(srgbRed: 0.85, green: 0.30, blue: 0.27, alpha: 1).setStroke()
    arc.stroke()

    NSGraphicsContext.current = nil
    return rep.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
        try render(pixels: size * scale).write(to: output.appendingPathComponent(name))
    }
}
print("Wrote \(output.path)")
