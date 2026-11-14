// CellStructuresMotion.swift — functional, pausable vector demonstrations.
import SwiftUI

struct CSClock {
    private var accumulated: TimeInterval = 0
    private var anchor = Date()
    private(set) var running = false

    func time(at date: Date) -> TimeInterval {
        accumulated + (running ? max(0, date.timeIntervalSince(anchor)) : 0)
    }
    mutating func setRunning(_ value: Bool) {
        let now = Date()
        accumulated = time(at: now)
        anchor = now
        running = value
    }
}

enum CSActiveDrawing {
    static func dot(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                    _ radius: CGFloat, _ color: Color, outline: Bool = true) {
        let p = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        c.fill(p, with: .color(color))
        if outline { c.stroke(p, with: .color(CSPalette.ink), lineWidth: 1) }
    }
    static func line(_ c: inout GraphicsContext, _ points: [CGPoint], color: Color = CSPalette.teal,
                     width: CGFloat = 2, dash: [CGFloat] = []) {
        guard let first = points.first else { return }
        var p = Path(); p.move(to: first)
        for point in points.dropFirst() { p.addLine(to: point) }
        c.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
    }
    static func text(_ value: String, _ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                     size: CGFloat = 9, color: Color = CSPalette.ink) {
        c.draw(Text(value).font(.system(size: size, weight: .semibold, design: .rounded)).foregroundStyle(color),
               at: CGPoint(x: x, y: y))
    }
    static func arrow(_ c: inout GraphicsContext, from a: CGPoint, to b: CGPoint, color: Color = CSPalette.teal) {
        line(&c, [a, b], color: color, width: 1.6)
        let angle = atan2(b.y - a.y, b.x - a.x)
        for sign in [CGFloat(-1), CGFloat(1)] {
            let theta = angle + sign * .pi / 6
            line(&c, [b, CGPoint(x: b.x - 5 * cos(theta), y: b.y - 5 * sin(theta))], color: color, width: 1.6)
        }
    }

    /// Local coordinates are 0...100; drawing may extend slightly beyond the organelle.
    static func draw(_ part: CSPart, kind: CSCellKind, time: Double,
                     context: inout GraphicsContext, rect: CGRect, captioned: Bool = false) {
        var c = context
        c.translateBy(x: rect.minX, y: rect.minY)
        c.scaleBy(x: rect.width / 100, y: rect.height / 100)
        let p = CGFloat(time.truncatingRemainder(dividingBy: 6) / 6)
        let wave = CGFloat(sin(time * 2))
        let gold = Color(csHex: 0xF7E49C), blue = Color(csHex: 0xC8E7EF)
        let peach = Color(csHex: 0xF3C9B5), purple = Color(csHex: 0xDECCE9)
        let custom: Set<CSPart> = [.cilia, .flagellum, .microfilaments, .lysosomes]
        if !custom.contains(part) {
            CSVector.draw(part, in: &c, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        }

        switch part {
        case .membrane:
            dot(&c, 24, -7 + 116 * p, 4, blue)
            dot(&c, 50, -7 + 116 * ((p + 0.4).truncatingRemainder(dividingBy: 1)), 3.5, gold)
            if captioned { text("O₂", &c, 12, 8); text("ion", &c, 67, 8) }
        case .cytoplasm:
            for i in 0..<7 {
                let angle = CGFloat(i) * 0.83 + CGFloat(time) * 0.28
                dot(&c, 54 + 29 * cos(angle), 54 + 27 * sin(angle), 2.5, blue)
            }
        case .nucleus:
            let x = 45 + 85 * p
            let points = (0..<7).map { i in CGPoint(x: x + CGFloat(i) * 3, y: 48 + (i.isMultiple(of: 2) ? 3 : -3)) }
            line(&c, points, color: Color(csHex: 0xB57BA8), width: 2.6)
            if captioned { text("mRNA → pore", &c, 110, 72, size: 7.5) }
        case .nucleolus:
            let x = 45 + 78 * p
            let large = Path(ellipseIn: CGRect(x: x, y: 39, width: 17, height: 11))
            let small = Path(ellipseIn: CGRect(x: x + 3, y: 58, width: 12, height: 7))
            c.fill(large, with: .color(gold)); c.stroke(large, with: .color(CSPalette.ink), lineWidth: 1)
            c.fill(small, with: .color(gold)); c.stroke(small, with: .color(CSPalette.ink), lineWidth: 1)
            if captioned { text("subunits", &c, 111, 82, size: 8) }
        case .ribosomes:
            for i in 0...Int(p * 8) {
                let x = 52 + 9 * sin(CGFloat(i) * 1.9)
                dot(&c, x, 22 - CGFloat(i) * 7, 3.7, i.isMultiple(of: 2) ? peach : purple)
            }
            dot(&c, 30 + 46 * p, 60, 3, Color(csHex: 0xAA7DB0))
            if captioned { text("mRNA", &c, 5, 76, size: 8); text("protein", &c, 86, 6, size: 8) }
        case .roughER:
            if p < 0.6 {
                for i in 0..<5 {
                    let a = CGFloat(i) * 1.4 + p * 7
                    dot(&c, 43 + 7 * cos(a), 25 + p * 60 + 6 * sin(a), 2.8, peach)
                }
            } else {
                let q = (p - 0.6) / 0.4
                dot(&c, 84 + 33 * q, 74 - 18 * q, 10, blue)
                dot(&c, 84 + 33 * q, 74 - 18 * q, 3.2, peach)
            }
        case .smoothER:
            let x = 76 + p * 29
            dot(&c, x, 22, 4, gold)
            line(&c, [CGPoint(x: x - 2, y: 25), CGPoint(x: x - 4, y: 36)], color: CSPalette.teal, width: 1.4)
            line(&c, [CGPoint(x: x + 2, y: 25), CGPoint(x: x + 4, y: 36)], color: CSPalette.teal, width: 1.4)
            for i in 0..<3 { dot(&c, 38 + CGFloat(i) * 13, 67 + p * 36, 2.8, blue) }
            if captioned { text("lipid", &c, 109, 12, size: 8); text("Ca²⁺", &c, 67, 105, size: 8) }
        case .golgi:
            let x: CGFloat = p < 0.5 ? -8 + p * 92 : 70 + (p - 0.5) * 100
            let y: CGFloat = p < 0.5 ? 19 + p * 16 : 68 + (p - 0.5) * 30
            dot(&c, x, y, 9, blue); dot(&c, x, y, 3, peach)
            if p > 0.5 {
                c.fill(Path(roundedRect: CGRect(x: x + 4, y: y - 11, width: 8, height: 5), cornerRadius: 2), with: .color(Color(csHex: 0x91B38D)))
            }
        case .vesicles:
            let q = p * 2 * .pi
            dot(&c, 50 + 17 * sin(q), 50 - 10 * cos(q), 3.8, gold)
            if captioned { arrow(&c, from: CGPoint(x: -20, y: 50), to: CGPoint(x: 4, y: 50)); arrow(&c, from: CGPoint(x: 96, y: 50), to: CGPoint(x: 122, y: 50)) }
        case .lysosomes:
            CSVector.draw(.lysosomes, in: &c, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
            let interior = Path(ellipseIn: CGRect(x: 24, y: 24, width: 52, height: 52))
            c.fill(interior, with: .radialGradient(Gradient(colors: [Color(csHex: 0xC5A6D3), Color(csHex: 0xCCB2D8)]),
                                                  center: CGPoint(x: 45, y: 41), startRadius: 0, endRadius: 38))
            if p < 0.45 {
                let r = CGRect(x: 35, y: 36, width: 29 * (1 - p), height: 29 * (1 - p))
                c.fill(Path(roundedRect: r, cornerRadius: 5), with: .color(peach))
                c.stroke(Path(roundedRect: r, cornerRadius: 5), with: .color(CSPalette.ink), lineWidth: 1.4)
            } else {
                for i in 0..<7 {
                    let a = CGFloat(i) * .pi * 2 / 7
                    let r = 10 + (p - 0.45) * 45
                    dot(&c, 50 + cos(a) * r, 50 + sin(a) * r, 3, peach)
                }
            }
        case .peroxisomes:
            if p < 0.5 {
                dot(&c, -5 + 100 * p, 50, 4.5, peach)
            } else {
                let q = (p - 0.5) * 2
                dot(&c, 53 + q * 62, 45 - q * 17, 3.7, blue)
                dot(&c, 53 + q * 62, 55 + q * 17, 3.7, gold)
            }
            if captioned { text("H₂O₂", &c, -10, 26, size: 8); text("H₂O + O₂", &c, 116, 88, size: 8) }
        case .mitochondria:
            for i in 0..<3 {
                let q = (p + CGFloat(i) / 3).truncatingRemainder(dividingBy: 1)
                let x = 68 + q * 54, y = 35 - q * 34 + CGFloat(i) * 19
                dot(&c, x, y, captioned ? 8 : 5, gold)
                if captioned { text("ATP", &c, x, y, size: 5) }
            }
        case .cytoskeleton, .microtubules:
            let x = 10 + 75 * p
            let y: CGFloat = part == .microtubules ? 17 : 39 + 12 * sin(p * 4)
            dot(&c, x, y, 7.5, peach)
            let foot = y + 18
            line(&c, [CGPoint(x: x, y: y + 7), CGPoint(x: x + 3, y: foot - 4), CGPoint(x: x - 4 + wave * 2, y: foot)], width: 1.8)
            line(&c, [CGPoint(x: x + 3, y: foot - 4), CGPoint(x: x + 7 - wave * 2, y: foot)], width: 1.8)
        case .microfilaments:
            let offset = 11 * (0.5 + 0.5 * wave)
            for i in 0..<9 {
                dot(&c, 6 + CGFloat(i) * 8 + offset, 38, 4.3, peach)
                dot(&c, 94 - CGFloat(i) * 8 - offset, 60, 4.3, purple)
            }
            for x in [CGFloat(37), CGFloat(61)] { line(&c, [CGPoint(x: x, y: 43), CGPoint(x: x + wave * 5, y: 55)], width: 3) }
            if captioned { text("myosin", &c, 51, 82, size: 8) }
        case .intermediateFilaments:
            let pull = 3 + abs(wave) * 5
            arrow(&c, from: CGPoint(x: 9, y: 50), to: CGPoint(x: -8 - pull, y: 50))
            arrow(&c, from: CGPoint(x: 92, y: 50), to: CGPoint(x: 108 + pull, y: 50))
        case .centrosome:
            for i in 0..<10 {
                let a = CGFloat(i) * .pi * 2 / 10
                let r = 29 + p * 37
                line(&c, [CGPoint(x: 50 + 27 * cos(a), y: 50 + 27 * sin(a)), CGPoint(x: 50 + r * cos(a), y: 50 + r * sin(a))], color: Color(csHex: 0x88B391), width: 1.7)
            }
        case .cilia:
            line(&c, [CGPoint(x: 3, y: 82), CGPoint(x: 97, y: 82)], width: 5)
            for i in 0..<6 {
                let x = CGFloat(10 + i * 16)
                let bend = CGFloat(sin(time * 2.8 - Double(i) * 0.5)) * 14
                var path = Path(); path.move(to: CGPoint(x: x, y: 80))
                path.addCurve(to: CGPoint(x: x + bend, y: 15), control1: CGPoint(x: x - bend, y: 58), control2: CGPoint(x: x + bend, y: 35))
                c.stroke(path, with: .color(CSPalette.ink), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                c.stroke(path, with: .color(blue), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            for i in 0..<3 { dot(&c, (p * 150 + CGFloat(i * 32)).truncatingRemainder(dividingBy: 116) - 8, 2, 3, gold) }
        case .flagellum:
            let points = (0...40).map { i -> CGPoint in
                let x = CGFloat(i) * 2.5
                let y = 50 + (x / 100) * 26 * sin(x * 0.08 - CGFloat(time) * 3)
                return CGPoint(x: x, y: y)
            }
            line(&c, points, color: CSPalette.ink, width: 5)
            line(&c, points, color: blue, width: 2.7)
            dot(&c, 0, 50, 6, gold)
        }
    }
}

struct CSFunctionArt: View {
    let part: CSPart
    let kind: CSCellKind
    let time: Double
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 320, size.height / 155)
            context.translateBy(x: (size.width - 320 * scale) / 2, y: (size.height - 155 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            if part == .vesicles {
                CSVector.draw(.roughER, in: &context, rect: CGRect(x: 12, y: 41, width: 57, height: 69))
                CSVector.draw(.golgi, in: &context, rect: CGRect(x: 129, y: 39, width: 58, height: 74))
                CSVector.draw(.membrane, in: &context, rect: CGRect(x: 243, y: 37, width: 63, height: 83))
                CSActiveDrawing.text("ER", &context, 37, 22, size: 10)
                CSActiveDrawing.text("Golgi", &context, 157, 22, size: 10)
                CSActiveDrawing.text("Membrane", &context, 273, 22, size: 10)
                let p = CGFloat(time.truncatingRemainder(dividingBy: 6) / 6)
                let x = 61 + p * 246
                CSActiveDrawing.dot(&context, x, 85, 10, Color(csHex: 0xC8E7EF))
                CSActiveDrawing.dot(&context, x + (p > 0.88 ? (p - 0.88) * 100 : 0), 85, 3.4, Color(csHex: 0xF3C9B5))
            } else {
                CSActiveDrawing.draw(part, kind: kind, time: time, context: &context,
                                     rect: CGRect(x: 106, y: 32, width: 108, height: 108), captioned: true)
            }
        }
        .accessibilityHidden(true)
    }
}
