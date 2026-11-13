// DNAReplicationScene.swift — original deterministic molecular animation.
// View coordinates are 360 × 420. All new DNA grows 5′ → 3′.
// Raster assets are mnemonic actors; strands, bases, ends and bonds are drawn precisely.
import SwiftUI

struct DNAReplicationScene: View {
    let step: DNAReplicationStep
    let progress: Double
    var showsLabels = true
    var background: Color = DNAReplicationTheme.paper

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 360, size.height / 420)
            var drawing = context
            drawing.translateBy(x: (size.width - 360 * scale) / 2, y: (size.height - 420 * scale) / 2)
            drawing.scaleBy(x: scale, y: scale)
            DNAReplicationPainter(context: drawing, step: step,
                                  p: CGFloat(min(max(progress, 0), 1)), labels: showsLabels).draw()
        }
        .aspectRatio(360.0 / 420.0, contentMode: .fit)
        .background(background)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(step.content.accessibility)
        .accessibilityValue("\(Int(min(max(progress, 0), 1) * 100)) percent of this teaching animation")
        .accessibilityIdentifier("dna-replication-diagram")
    }
}

private struct DNAReplicationPainter {
    var context: GraphicsContext
    let step: DNAReplicationStep
    let p: CGFloat
    let labels: Bool
    private let old = DNAReplicationTheme.parental
    private let new = DNAReplicationTheme.newDNA
    private let ink = DNAReplicationTheme.ink
    private let edge = DNAReplicationTheme.edge
    private let teal = DNAReplicationTheme.teal
    private let rna = DNAReplicationTheme.rna
    private let butter = DNAReplicationTint.butter.color
    private let sequence = DNAReplicationDiagram.sequence

    func draw() {
        switch step {
        case .origins: drawOrigins()
        case .proofread: drawProofreading()
        case .replace, .seal: drawJunction()
        case .result: drawResult()
        default: drawFork()
        }
    }

    private func clamp(_ value: CGFloat) -> CGFloat { min(max(value, 0), 1) }
    private func mix(_ a: CGFloat, _ b: CGFloat, _ value: CGFloat) -> CGFloat { a + (b - a) * value }
    private func smooth(_ value: CGFloat) -> CGFloat {
        let q = clamp(value)
        return q * q * (3 - 2 * q)
    }
    private func y(_ index: Int) -> CGFloat { 214 + CGFloat(index) * 12 }

    private func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
                      _ color: Color = DNAReplicationTheme.edge, _ width: CGFloat = 1.4,
                      dash: [CGFloat] = []) {
        var path = Path()
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
    }

    private func rawText(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 12,
                         _ weight: Int = 600, _ color: Color = DNAReplicationTheme.ink) {
        let fontWeight: Font.Weight = weight >= 750 ? .heavy : (weight >= 650 ? .bold : .medium)
        let text = Text(value).font(.system(size: size, weight: fontWeight, design: .rounded)).foregroundColor(color)
        context.draw(context.resolve(text), at: CGPoint(x: x, y: y), anchor: .center)
    }
    private func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 12,
                      _ weight: Int = 600, _ color: Color = DNAReplicationTheme.ink) {
        if labels { rawText(value, x, y, size, weight, color) }
    }
    private func round(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat,
                       _ radius: CGFloat, _ fill: Color, _ stroke: Color? = nil, _ lineWidth: CGFloat = 1) {
        let path = Path(roundedRect: CGRect(x: x, y: y, width: width, height: height), cornerRadius: radius)
        context.fill(path, with: .color(fill))
        if let stroke { context.stroke(path, with: .color(stroke), lineWidth: lineWidth) }
    }
    private func circle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ fill: Color,
                        _ stroke: Color? = nil, _ width: CGFloat = 1) {
        let path = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        context.fill(path, with: .color(fill))
        if let stroke { context.stroke(path, with: .color(stroke), lineWidth: width) }
    }
    private func arrow(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
                       _ color: Color = DNAReplicationTheme.teal, _ width: CGFloat = 1.7) {
        line(x1, y1, x2, y2, color, width)
        let angle = atan2(y2 - y1, x2 - x1)
        line(x2, y2, x2 - 6 * cos(angle - 0.55), y2 - 6 * sin(angle - 0.55), color, width)
        line(x2, y2, x2 - 6 * cos(angle + 0.55), y2 - 6 * sin(angle + 0.55), color, width)
    }
    private func pill(_ value: String, _ x: CGFloat, _ y: CGFloat,
                      _ fill: Color = DNAReplicationTheme.cream,
                      _ color: Color = DNAReplicationTheme.ink, _ size: CGFloat = 11) {
        guard labels else { return }
        let label = context.resolve(Text(value).font(.system(size: size, weight: .bold, design: .rounded)))
        let width = label.measure(in: CGSize(width: 340, height: 40)).width + 16
        round(x - width / 2, y - 11, width, 22, 11, fill)
        rawText(value, x, y, size, 650, color)
    }
    private func sugar(_ x: CGFloat, _ y: CGFloat, _ color: Color, _ radius: CGFloat = 4) {
        var path = Path()
        for index in 0..<5 {
            let angle = -CGFloat.pi / 2 + CGFloat(index) * 2 * .pi / 5
            let point = CGPoint(x: x + radius * cos(angle), y: y + radius * sin(angle))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        context.fill(path, with: .color(color))
        context.stroke(path, with: .color(ink), lineWidth: 0.7)
    }
    private func base(_ x: CGFloat, _ y: CGFloat, _ value: String,
                      isRNA: Bool = false, error: Bool = false, size: CGFloat = 12, alpha: CGFloat = 1) {
        var local = self
        local.context.opacity *= Double(alpha)
        let fill: Color
        if error { fill = DNAReplicationTheme.color(0xF4B5BC) }
        else if isRNA { fill = butter }
        else {
            switch value {
            case "A": fill = DNAReplicationTint.peach.color
            case "T": fill = DNAReplicationTint.blue.color
            case "U": fill = butter
            case "C": fill = DNAReplicationTint.lavender.color
            default: fill = DNAReplicationTint.sage.color
            }
        }
        local.round(x - size / 2, y - 7, size, 14, 3, fill, error ? DNAReplicationTheme.error : edge, error ? 1.5 : 0.7)
        if !isRNA { local.rawText(value, x, y + 0.3, min(size - 1, 10), 800, error ? DNAReplicationTheme.error : ink) }
        if isRNA { local.line(x - size / 2, y + 8, x + size / 2, y + 8, rna, 2) }
    }
    private func icon(_ name: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 48, _ alpha: CGFloat = 1) {
        var local = context
        local.opacity *= Double(alpha)
        local.draw(local.resolve(Image(name)), in: CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size))
    }
    private func verticalPair(oldX: CGFloat, newX: CGFloat, y: CGFloat, oldBase: String,
                              newBase: String, hasNew: Bool = true, isRNA: Bool = false) {
        let direction: CGFloat = newX > oldX ? 1 : -1
        let oldBaseX = oldX + direction * 10
        let newBaseX = newX - direction * 10
        sugar(oldX, y, old)
        line(oldX, y, oldBaseX, y, old, 1.2)
        base(oldBaseX, y, oldBase)
        circle(oldX, y + 6, 2.1, butter, edge, 0.6)
        if hasNew {
            sugar(newX, y, isRNA ? rna : new)
            circle(newX, y + 6, 2.1, butter, edge, 0.6)
            line(newX, y, newBaseX, y, isRNA ? rna : new, 1.2)
            base(newBaseX, y, newBase, isRNA: isRNA)
            line(oldBaseX + direction * 6, y, newBaseX - direction * 6, y, edge, 0.9, dash: [1.1, 1.5])
        }
    }

    private func drawOrigins() {
        line(36, 192, 324, 192, old, 3)
        line(36, 232, 324, 232, old, 3)
        for index in 0..<12 {
            let x = CGFloat(48 + index * 24)
            line(x, 192, x, 202, old, 1.2)
            line(x, 222, x, 232, old, 1.2)
            base(x, 203, sequence[index])
            base(x, 221, DNAReplicationDiagram.complement(sequence[index]))
            line(x, 210, x, 214, edge, 1, dash: [1, 2])
        }
        text("5′", 30, 174, 13, 750, old); text("3′", 330, 174, 13, 750, old)
        text("3′", 30, 251, 13, 750, old); text("5′", 330, 251, 13, 750, old)
        pill("Origins of replication", 180, 119, butter)
        for x in [CGFloat(72), 168, 264] {
            circle(x, 212, 5, butter, edge, 0.8)
            line(180, 132, x, 204, edge, 1, dash: [3, 3])
        }
        text("Starting locations along DNA", 180, 292, 12, 650)
    }

    private func drawFork() {
        let forkY = step == .unzip ? mix(296, 160, smooth(p)) : 160
        let showNew = step.rawValue >= DNAReplicationStep.prime.rawValue
        let branches: [(CGFloat, CGFloat)] = [(164, 75), (196, 285)]
        for (start, end) in branches {
            var path = Path()
            path.move(to: CGPoint(x: start, y: 38))
            path.addLine(to: CGPoint(x: start, y: forkY - 25))
            path.addCurve(to: CGPoint(x: end, y: forkY + 54),
                          control1: CGPoint(x: start, y: forkY + 6),
                          control2: CGPoint(x: end, y: forkY + 24))
            path.addLine(to: CGPoint(x: end, y: 352))
            context.stroke(path, with: .color(old), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        var row: CGFloat = 51
        var pairIndex = 0
        while row < forkY - 26 {
            let value = sequence[pairIndex % 12]
            sugar(164, row, old, 3); sugar(196, row, old, 3)
            base(174, row, value, size: 10)
            base(186, row, DNAReplicationDiagram.complement(value), size: 10)
            line(179, row, 181, row, edge, 0.8, dash: [1, 1])
            row += 18; pairIndex += 1
        }
        text("5′", 149, 30, 13, 750, old); text("3′", 211, 30, 13, 750, old)
        text("3′", 62, 366, 13, 750, old); text("5′", 298, 366, 13, 750, old)

        let leading = (0..<12).map { DNAReplicationDiagram.visible(leading: true, index: $0, step: step, progress: Double(p)) }
        let lagging = (0..<12).map { DNAReplicationDiagram.visible(leading: false, index: $0, step: step, progress: Double(p)) }
        if showNew {
            if let top = leading.firstIndex(of: true) {
                line(111, y(top), 111, y(11), new, 3)
                line(111, max(y(top), y(10)), 111, y(11), rna, 3)
            }
            for group in 0..<3 {
                let visible = (group * 4 ..< group * 4 + 4).filter { lagging[$0] }
                if let first = visible.first, let last = visible.last {
                    line(249, y(first), 249, y(last), new, 3)
                    line(249, y(group * 4), 249, y(group * 4 + 1), rna, 3)
                }
            }
        }
        for index in 0..<12 where y(index) >= forkY + 50 {
            let left = sequence[index]
            let right = DNAReplicationDiagram.complement(left)
            let lp = DNAReplicationDiagram.isPrimer(leading: true, index: index)
            let rp = DNAReplicationDiagram.isPrimer(leading: false, index: index)
            verticalPair(oldX: 75, newX: 111, y: y(index), oldBase: left,
                         newBase: lp ? DNAReplicationDiagram.rnaComplement(left) : DNAReplicationDiagram.complement(left),
                         hasNew: showNew && leading[index], isRNA: lp)
            verticalPair(oldX: 285, newX: 249, y: y(index), oldBase: right,
                         newBase: rp ? DNAReplicationDiagram.rnaComplement(right) : DNAReplicationDiagram.complement(right),
                         hasNew: showNew && lagging[index], isRNA: rp)
        }
        if step.rawValue >= DNAReplicationStep.stabilize.rawValue {
            for (rank, index) in [1, 5, 9].enumerated() {
                var local = self
                local.context.opacity *= Double(step == .stabilize ? clamp(p * 3 - CGFloat(rank)) : 1)
                if !leading[index] { local.round(58, y(index) - 5, 12, 10, 4, DNAReplicationTint.lavender.color, edge, 0.9) }
                if !lagging[index + 1] { local.round(290, y(index + 1) - 5, 12, 10, 4, DNAReplicationTint.lavender.color, edge, 0.9) }
            }
        }
        icon("DNAHelicaseZipper", 180, forkY + 3, 53)
        if step == .unzip {
            pill("Hydrogen bonds", 77, forkY - 31, DNAReplicationTint.blue.color)
            line(135, forkY - 25, 180, row - 18, edge, 1, dash: [2, 2])
            pill("Helicase", 276, forkY + 10, DNAReplicationTint.peach.color)
            line(234, forkY + 10, 191, forkY + 3, edge, 1)
            arrow(314, 325, 314, 281); text("Fork ↑", 314, 345, 10, 650, teal)
        }
        if step == .stabilize {
            pill("Binding proteins", 180, 280, DNAReplicationTint.lavender.color)
            line(129, 280, 72, 274, edge, 1); line(231, 280, 290, 286, edge, 1)
        }
        if step == .prime {
            icon("DNAPrimaseStarter", 180, 275, 110)
            pill("RNA primers", 180, 340, butter)
            line(130, 340, 114, 340, edge, 1); line(230, 340, 246, 316, edge, 1)
            text("3′", 128, 320, 11, 750, rna); text("5′", 125, 366, 12, 750, new)
        }
        if step == .build {
            let leadingDone = min(10, Int(floor(p * 10 + 1e-8)))
            let leadingY = y(10 - leadingDone)
            let rank = min(2, Int(p * 3))
            let group = 2 - rank
            let local = p >= 1 ? 1 : p * 3 - CGFloat(rank)
            let laggingDone = min(2, Int(floor(clamp(local) * 2 + 1e-8)))
            let laggingY = y(group * 4 + 1 + laggingDone)
            if leadingDone < 10 {
                let index = 9 - leadingDone
                let q = smooth(clamp(p * 10 - CGFloat(leadingDone)))
                base(mix(180, 101, q), mix(y(index) + 18, y(index), q),
                     DNAReplicationDiagram.complement(sequence[index]), alpha: 0.35 + 0.65 * q)
            }
            if laggingDone < 2 {
                let index = group * 4 + 2 + laggingDone
                let q = smooth(clamp(local * 2 - CGFloat(laggingDone)))
                base(mix(180, 259, q), mix(y(index) - 18, y(index), q), sequence[index], alpha: 0.35 + 0.65 * q)
            }
            icon("DNAPolymeraseBuilder", 146, leadingY, 39)
            icon("DNAPolymeraseBuilder", 213, laggingY, 39)
            text("3′", 119, leadingY - 16, 12, 800, new)
            text("3′", 240, laggingY + 17, 12, 800, new)
            text("5′", 126, 366, 12, 750, new)
            text("5′", 238, y(group * 4) - 13, 12, 750, new)
            arrow(145, leadingY + 27, 145, leadingY + 10, new)
            arrow(213, laggingY - 26, 213, laggingY - 10, new)
            pill("Okazaki fragments", 278, 110, butter)
            line(278, 122, 251, 225, edge, 1, dash: [2, 3])
        }
        if step == .prime || step == .build {
            text("Leading", 91, 386, 13, 750); text("Lagging", 270, 386, 13, 750)
            text("continuous ↑", 91, 403, 11, 550, DNAReplicationTheme.muted)
            text("fragments ↓", 270, 403, 11, 550, DNAReplicationTheme.muted)
        } else {
            text("Parental template", 91, 391, 10, 600, old)
            text("Parental template", 270, 391, 10, 600, old)
        }
    }

    private func drawProofreading() {
        text("ZOOM · GROWING 3′ END", 180, 40, 12, 750)
        let rows: [CGFloat] = [126, 177, 228, 279, 330]
        let bases = ["A", "C", "G", "T", "A"]
        line(120, 108, 120, 346, old, 4)
        let hasTip = p < 0.35 || p >= 0.9
        line(210, hasTip ? 126 : 177, 210, 346, new, 4)
        for index in 0..<rows.count {
            let row = rows[index]
            sugar(120, row, old, 6); line(120, row, 147, row, old, 1.5)
            base(147, row, bases[index], size: 20)
            if index > 0 {
                sugar(210, row, new, 6); line(210, row, 184, row, new, 1.5)
                base(184, row, DNAReplicationDiagram.complement(bases[index]), size: 20)
                line(158, row, 173, row, edge, 1.2, dash: [2, 3])
            }
        }
        if p < 0.35 {
            sugar(210, 126, new, 6)
            line(210, 126, 184, 126, new, 1.5)
            base(184, 126, "G", error: true, size: 20)
            line(163, 121, 171, 131, DNAReplicationTheme.error, 1.7)
            line(163, 131, 171, 121, DNAReplicationTheme.error, 1.7)
        } else if p < 0.6 {
            let q = clamp((p - 0.35) / 0.25)
            base(mix(184, 285, q), mix(126, 78, q), "G", error: true, size: 20, alpha: 1 - q)
        }
        if p >= 0.6 {
            let q = clamp((p - 0.6) / 0.3)
            base(mix(300, 184, smooth(q)), mix(104, 126, smooth(q)), "T", size: 20)
            if q >= 1 {
                line(210, 126, 184, 126, new, 1.5); sugar(210, 126, new, 6)
                line(158, 126, 173, 126, teal, 1.3, dash: [2, 3])
            }
        }
        text("5′", 120, 89, 14, 800, old); text("3′", 120, 369, 14, 800, old)
        text("5′", 210, 369, 14, 800, new)
        text("3′", 224, (hasTip ? 126 : 177) - 22, 14, 800, new)
        icon("DNAPolymeraseBuilder", 286, 191, 69)
        pill(p < 0.6 ? "Mismatch" : "Correct base", 278, 73,
             p < 0.6 ? DNAReplicationTheme.color(0xF4D4D6) : DNAReplicationTint.sage.color,
             p < 0.6 ? DNAReplicationTheme.error : ink)
        pill("DNA polymerase", 270, 250, DNAReplicationTint.blue.color)
        arrow(90, 311, 90, 255, new); text("5′ → 3′", 74, 337, 11, 700, new)
    }

    private func drawJunction() {
        let removal = step == .seal ? 1 : clamp((p - 0.12) / 0.32)
        let filling = step == .seal ? 1 : clamp((p - 0.48) / 0.42)
        let filled = Int(floor(filling * 2 + 1e-8))
        let sealed = step == .seal && p >= 0.64
        let xs = (0..<9).map { CGFloat(50 + $0 * 32) }
        let bases = ["A", "G", "C", "T", "A", "C", "G", "T", "A"]
        text("ZOOM · INTERNAL FRAGMENT JUNCTION", 180, 42, 11, 750)
        text("3′", 43, 130, 13, 750, old); text("5′", 317, 130, 13, 750, old)
        line(43, 166, 317, 166, old, 4)
        line(43, 228, 114, 228, new, 4); line(210, 228, 317, 228, new, 4)
        if removal == 0 && step == .replace {
            // Before replacement, the older RNA–DNA fragment is separate from
            // the upstream fragment. The original nick is not prematurely sealed.
            line(114, 228, 126, 228, new, 4)
            line(134, 228, 210, 228, rna, 4)
        }
        if filled > 0 { line(114, 228, filled == 1 ? 146 : 178, 228, new, 4) }
        if filled == 2 {
            line(178, 228, 190, 228, new, 4); line(198, 228, 210, 228, new, 4)
        }
        if sealed { line(190, 228, 198, 228, new, 4) }
        for index in 0..<9 {
            let x = xs[index]
            sugar(x, 166, old, 5)
            if index < 8 { circle(x + 16, 166, 2.5, butter, edge, 0.7) }
            line(x, 166, x, 182, old, 1.3); base(x, 184, bases[index], size: 20)
            let primer = index == 3 || index == 4
            let replaced = primer && index - 3 < filled
            if !primer || replaced {
                line(x, 228, x, 213, new, 1.3); sugar(x, 228, new, 5)
                circle(x - 8, 228, 2.5, butter, edge, 0.7)
                base(x, 210, DNAReplicationDiagram.complement(bases[index]), size: 20)
                line(x, 193, x, 200, edge, 1, dash: [2, 2])
            }
            if primer && removal < 1 && !replaced {
                var local = self
                local.context.opacity *= Double(1 - removal)
                let row = 228 + removal * 70
                local.sugar(x, row, rna, 5)
                local.circle(x - 8, row, 2.5, butter, edge, 0.7)
                local.base(x, 210 + removal * 70, DNAReplicationDiagram.rnaComplement(bases[index]), isRNA: true, size: 20)
                if removal == 0 {
                    local.line(x, 228, x, 213, rna, 1.3)
                    local.line(x, 193, x, 200, edge, 1, dash: [2, 2])
                }
            }
        }
        text("5′", 43, 256, 13, 750, new); text("3′", 317, 256, 13, 750, new)
        if step == .replace {
            text("3′", 114 + CGFloat(32 * filled), 254, 10.5, 750, new)
            if p < 0.5 {
                pill("RNA primer", 179, 101, butter)
                line(178, 113, 178, 198, edge, 1, dash: [2, 3])
                text("Repair enzymes remove RNA", 180, 327, 12, 650)
            } else {
                icon("DNAPolymeraseBuilder", mix(114, 178, filling), 282, 52)
                text("Extend an existing 3′ end →", 180, 341, 12, 650)
            }
            if filled == 2 {
                circle(194, 228, 11, DNAReplicationTheme.paper, DNAReplicationTheme.error, 1.1)
                line(178, 228, 190, 228, new, 3); line(198, 228, 210, 228, new, 3)
                circle(202, 228, 2.5, butter, edge, 0.7)
                pill("Nick", 252, 296, DNAReplicationTint.peach.color)
                line(232, 287, 200, 239, edge, 1)
            }
        } else {
            icon("DNALigaseGlue", 194, mix(306, 284, smooth(p)), 67)
            if p > 0.2 && p < 0.7 { circle(194, mix(263, 228, clamp((p - 0.2) / 0.5)), 3.5, rna) }
            if !sealed {
                circle(194, 228, 12, DNAReplicationTheme.paper, DNAReplicationTheme.error, 1.1)
                line(178, 228, 190, 228, new, 3); line(198, 228, 210, 228, new, 3)
                circle(202, 228, 2.5, butter, edge, 0.7)
                pill("Backbone nick", 180, 99, DNAReplicationTint.peach.color)
            } else {
                circle(194, 228, 9, butter.opacity(0.4), teal, 1.2)
                line(184, 228, 204, 228, new, 4)
                circle(202, 228, 2.5, butter, edge, 0.7)
                pill("Covalent bond sealed", 180, 99, DNAReplicationTint.sage.color)
            }
            line(180, 111, 194, 214, edge, 1, dash: [2, 3])
            text("Ligase seals the sugar-phosphate backbone", 180, 358, 10.5, 650)
        }
        arrow(54, 291, 104, 291, new); text("5′ → 3′", 65, 314, 10.5, 700, new)
        text("Template DNA", 180, 146, 10.5, 600, old)
    }

    private func drawResult() {
        let q = smooth(p)
        let oldLeft = mix(150, 74, q), oldRight = mix(210, 286, q)
        let newLeft = oldLeft + 36, newRight = oldRight - 36
        let alpha = clamp((p - 0.12) / 0.5)
        text("SEMICONSERVATIVE", 180, 46, 13, 800)
        line(oldLeft, 106, oldLeft, 338, old, 4); line(oldRight, 106, oldRight, 338, old, 4)
        if alpha > 0 {
            var local = self; local.context.opacity *= Double(alpha)
            local.line(newLeft, 106, newLeft, 338, new, 4)
            local.line(newRight, 106, newRight, 338, new, 4)
        }
        for index in 0..<12 {
            let row = CGFloat(117 + index * 18)
            if p < 0.3 {
                var local = self; local.context.opacity *= Double(1 - p / 0.3)
                local.line(oldLeft, row, oldRight, row, edge, 1, dash: [3, 3])
            }
            verticalPair(oldX: oldLeft, newX: newLeft, y: row, oldBase: sequence[index],
                         newBase: DNAReplicationDiagram.complement(sequence[index]), hasNew: alpha > 0.2)
            verticalPair(oldX: oldRight, newX: newRight, y: row,
                         oldBase: DNAReplicationDiagram.complement(sequence[index]), newBase: sequence[index], hasNew: alpha > 0.2)
        }
        text("5′", oldLeft, 88, 13, 800, old); text("3′", oldRight, 88, 13, 800, old)
        text("3′", oldLeft, 355, 13, 800, old); text("5′", oldRight, 355, 13, 800, old)
        if alpha > 0.5 {
            text("3′", newLeft, 88, 13, 800, new); text("5′", newRight, 88, 13, 800, new)
            text("5′", newLeft, 355, 13, 800, new); text("3′", newRight, 355, 13, 800, new)
        }
        text("DNA copy 1", 92, 382, 12, 750); text("DNA copy 2", 268, 382, 12, 750)
        text("1 parental + 1 new strand in each", 180, 406, 11, 650)
    }
}
