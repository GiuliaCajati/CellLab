import AppKit
import ImageIO
import UniformTypeIdentifiers

// Native, deterministic typesetting around unmodified Simulator pixels.
// Run the executable from Marketing/AppStore/en-US.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let captureURL = root.appendingPathComponent("Captures/iPhone-17-Pro-DNA-four-bases.png")
let source = CGImageSourceCreateWithURL(captureURL as CFURL, nil)!
let capture = CGImageSourceCreateImageAtIndex(source, 0, nil)!
let ink = color(0x184C46), cream = color(0xFCF5EC), teal = color(0x118782)
let gold = color(0xF7E49C), pink = color(0xCF7595), blue = color(0xC8E7EF)

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255)/255,
            green: CGFloat((hex >> 8) & 255)/255,
            blue: CGFloat(hex & 255)/255, alpha: 1)
}
func rounded(_ size: CGFloat, _ weight: NSFont.Weight = .bold) -> NSFont {
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    return NSFont(descriptor: font.fontDescriptor.withDesign(.rounded)!, size: size)!
}
func serif(_ size: CGFloat) -> NSFont { NSFont(name: "Georgia-Bold", size: size)! }
func text(_ string: String, x: CGFloat, y: CGFloat, font: NSFont, color: NSColor, tracking: CGFloat = 0) {
    (string as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: [.font: font, .foregroundColor: color, .kern: tracking])
}
func fill(_ rect: CGRect, _ color: NSColor, radius: CGFloat = 0) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
func circle(_ rect: CGRect, _ color: NSColor) {
    color.setFill(); NSBezierPath(ovalIn: rect).fill()
}
func screenshot(_ rect: CGRect, radius: CGFloat) {
    // Only status/navigation/progress above the card and empty bottom safe area are trimmed.
    // The full instruction, both strands, key, next action and tool tray remain visible.
    let crop = capture.cropping(to: CGRect(x: 0, y: 450, width: 1206, height: 2050))!
    NSGraphicsContext.saveGraphicsState()
    let clip = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    clip.appendRect(CGRect(x: rect.minX, y: rect.maxY - radius, width: rect.width, height: radius))
    clip.addClip()
    NSImage(cgImage: crop, size: NSSize(width: crop.width, height: crop.height))
        .draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()
}
@discardableResult func render(_ name: String, width: Int, height: Int, draw: () -> Void) -> CGImage {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4, space: space,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
    context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    let result = context.makeImage()!
    let url = root.appendingPathComponent("Concepts/" + name + ".png")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, result, [kCGImagePropertyDPIWidth: 72, kCGImagePropertyDPIHeight: 72] as CFDictionary)
    precondition(CGImageDestinationFinalize(destination))
    print(url.lastPathComponent, result.width, result.height, "opaque RGB", result.alphaInfo.rawValue)
    return result
}
let a = render("01-A-Warm-Editorial-iPhone", width: 1206, height: 2622) {
    fill(CGRect(x: 0, y: 0, width: 1206, height: 2622), cream)
    text("CellLab", x: 78, y: 65, font: serif(43), color: ink)
    text("BIOLOGY, HANDS ON", x: 707, y: 84, font: rounded(22, .semibold), color: teal, tracking: 2.1)
    text("Build DNA,", x: 72, y: 180, font: serif(139), color: ink, tracking: -5)
    text("base by base.", x: 72, y: 335, font: serif(139), color: ink, tracking: -5)
    fill(CGRect(x: 80, y: 536, width: 90, height: 9), teal, radius: 4)
    text("Match the bases. Make the strand.", x: 199, y: 520, font: rounded(33, .medium), color: ink)
    let frame = CGRect(x: 64, y: 622, width: 1078, height: 2050 * 1078 / 1206)
    screenshot(frame, radius: 48)
    text("LEARN IT BY DOING IT", x: 78, y: 2511, font: rounded(25, .semibold), color: teal, tracking: 3)
    text("01", x: 1072, y: 2504, font: serif(38), color: ink)
}
let b = render("01-B-Colorful-Poster-iPhone", width: 1206, height: 2622) {
    fill(CGRect(x: 0, y: 0, width: 1206, height: 2622), ink)
    circle(CGRect(x: 1020, y: -115, width: 330, height: 330), teal)
    circle(CGRect(x: -90, y: 345, width: 200, height: 200), pink)
    circle(CGRect(x: 1100, y: 430, width: 165, height: 165), blue)
    text("CellLab", x: 64, y: 54, font: serif(46), color: cream)
    text("PLAY YOUR WAY INTO BIOLOGY", x: 405, y: 75, font: rounded(23, .semibold), color: cream, tracking: 1.1)
    text("Build DNA,", x: 62, y: 167, font: rounded(147, .heavy), color: cream, tracking: -5)
    text("base by base.", x: 62, y: 325, font: rounded(147, .heavy), color: gold, tracking: -5)
    screenshot(CGRect(x: 0, y: 553, width: 1206, height: 2050), radius: 64)
    fill(CGRect(x: 0, y: 2603, width: 1206, height: 19), color(0xFBF4EA))
}
render("A-B-Side-by-Side", width: 1326, height: 1550) {
    fill(CGRect(x: 0, y: 0, width: 1326, height: 1550), color(0xE7E7E2))
    text("A  WARM SCIENCE EDITORIAL", x: 38, y: 28, font: rounded(22), color: ink)
    text("B  COLORFUL GAME POSTER", x: 690, y: 28, font: rounded(22), color: ink)
    for (image, x) in [(a, CGFloat(36)), (b, CGFloat(690))] {
        NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            .draw(in: CGRect(x: x, y: 86, width: 600, height: 600 * 2622 / 1206), from: .zero,
                  operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    }
    text("Same real gameplay · iPhone 17 Pro · 1206 × 2622", x: 329, y: 1440, font: rounded(25, .medium), color: ink)
}
