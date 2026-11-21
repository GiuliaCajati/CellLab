import SwiftUI

/// One visual idea per card. Carbon beads are schematic, not molecular structures.
struct RespirationProcessPainter {
    var context: GraphicsContext
    let p: CGFloat
    private let ink = RespirationTheme.ink
    private let edge = RespirationTheme.edge
    private let teal = RespirationTheme.teal
    private let peach = RespirationTint.peach.color
    private let blue = RespirationTint.blue.color
    private let sage = RespirationTint.sage.color
    private let lilac = RespirationTint.lavender.color
    private let gold = RespirationTheme.color(0xE9B953)
    private let paper = RespirationTheme.paper

    func draw(step: RespirationStep, player: String?) {
        if let player { drawPlayer(player); return }
        switch step {
        case .overview: overview()
        case .glycolysis: glycolysis()
        case .transition: prepareFuel()
        case .krebs: krebs()
        case .transport: transport()
        case .chemiosmosis: chemiosmosis()
        case .accounting: accounting()
        case .efficiency: efficiency()
        case .anaerobic: anaerobic()
        case .fermentation: fermentation()
        }
    }

    private func phase(_ start: CGFloat, _ end: CGFloat) -> CGFloat {
        let q = min(max((p - start) / (end - start), 0), 1)
        return q * q * (3 - 2 * q)
    }
    private func shape(_ path: Path, _ fill: Color, _ stroke: Color? = nil, width: CGFloat = 1.7) {
        context.fill(path, with: .color(fill))
        if let stroke { context.stroke(path, with: .color(stroke), lineWidth: width) }
    }
    private func round(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                       _ fill: Color, radius: CGFloat = 16, stroke: Color? = nil) {
        shape(Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius), fill, stroke)
    }
    private func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                         _ fill: Color, stroke: Color? = nil) {
        shape(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), fill, stroke)
    }
    private func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ fill: Color, stroke: Color? = nil) {
        ellipse(x - r, y - r, r * 2, r * 2, fill, stroke: stroke)
    }
    private func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
                      _ color: Color, width: CGFloat = 2, dash: [CGFloat] = []) {
        var path = Path(); path.move(to: CGPoint(x: x1, y: y1)); path.addLine(to: CGPoint(x: x2, y: y2))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
    }
    private func text(_ value: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat = 14,
                      color: Color = RespirationTheme.ink, bold: Bool = false) {
        context.draw(Text(value).font(.system(size: size, weight: bold ? .bold : .medium, design: .rounded))
            .foregroundStyle(color), at: CGPoint(x: x, y: y))
    }
    private func pill(_ value: String, _ x: CGFloat, _ y: CGFloat, _ fill: Color, size: CGFloat = 13) {
        let label = context.resolve(Text(value).font(.system(size: size, weight: .semibold, design: .rounded)).foregroundStyle(ink))
        let width = label.measure(in: CGSize(width: 340, height: 30)).width + 24
        round(x - width / 2, y - 15, width, 30, fill, radius: 15)
        context.draw(label, at: CGPoint(x: x, y: y))
    }
    private func arrow(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, color: Color? = nil) {
        let color = color ?? teal
        line(x1, y1, x2, y2, color, width: 2.5)
        let a = atan2(y2 - y1, x2 - x1)
        line(x2, y2, x2 - 7 * cos(a - 0.55), y2 - 7 * sin(a - 0.55), color, width: 2.5)
        line(x2, y2, x2 - 7 * cos(a + 0.55), y2 - 7 * sin(a + 0.55), color, width: 2.5)
    }
    private func carbon(_ count: Int, _ x: CGFloat, _ y: CGFloat, spacing: CGFloat = 24, color: Color? = nil) {
        let left = x - CGFloat(count - 1) * spacing / 2
        if count > 1 { line(left, y, left + CGFloat(count - 1) * spacing, y, edge, width: 3) }
        for i in 0..<count {
            let at = left + CGFloat(i) * spacing
            dot(at, y, 11, color ?? peach, stroke: ink)
            dot(at - 3, y - 3, 3, .white.opacity(0.55))
        }
    }
    private func atp(_ x: CGFloat, _ y: CGFloat, scale: CGFloat = 1) {
        var local = context
        local.translateBy(x: x, y: y); local.scaleBy(x: scale, y: scale)
        var star = Path()
        for i in 0..<16 {
            let a = CGFloat(i) * .pi / 8 - .pi / 2
            let r: CGFloat = i.isMultiple(of: 2) ? 29 : 24
            let point = CGPoint(x: cos(a) * r, y: sin(a) * r)
            if i == 0 { star.move(to: point) } else { star.addLine(to: point) }
        }
        star.closeSubpath()
        local.fill(star, with: .color(gold)); local.stroke(star, with: .color(ink), lineWidth: 1.6)
        local.draw(Text("ATP").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(ink), at: .zero)
    }
    private func proton(_ x: CGFloat, _ y: CGFloat, small: Bool = false) {
        dot(x, y, small ? 9 : 12, lilac, stroke: edge)
        text("H⁺", x, y, size: small ? 9 : 11, bold: true)
    }
    private func electron(_ x: CGFloat, _ y: CGFloat) {
        dot(x, y, 9, gold, stroke: ink); text("e⁻", x, y, size: 10, bold: true)
    }
    private func water(_ x: CGFloat, _ y: CGFloat) {
        line(x - 12, y - 8, x, y + 2, edge); line(x, y + 2, x + 12, y - 8, edge)
        dot(x - 13, y - 9, 6, paper, stroke: edge); dot(x + 13, y - 9, 6, paper, stroke: edge)
        dot(x, y + 3, 10, blue, stroke: ink)
    }
    private func oxygen(_ x: CGFloat, _ y: CGFloat) {
        line(x - 9, y, x + 9, y, ink, width: 4)
        dot(x - 10, y, 12, blue, stroke: ink); dot(x + 10, y, 12, blue, stroke: ink)
    }
    private func mitochondrion(_ x: CGFloat, _ y: CGFloat, width: CGFloat = 260, height: CGFloat = 150,
                               highlight: String? = nil) {
        let rect = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)
        shape(Path(roundedRect: rect, cornerRadius: height * 0.48), peach, ink, width: 2.5)
        let inner = rect.insetBy(dx: 11, dy: 11)
        shape(Path(roundedRect: inner, cornerRadius: height * 0.42), highlight == "matrix" ? sage : paper, edge)
        for i in 0..<4 {
            let at = inner.minX + 37 + CGFloat(i) * (inner.width - 74) / 3
            let fromTop = i.isMultiple(of: 2)
            let base = fromTop ? inner.minY + 5 : inner.maxY - 5
            let tip = fromTop ? inner.maxY - 33 : inner.minY + 33
            var fold = Path()
            fold.move(to: CGPoint(x: at - 10, y: base))
            fold.addLine(to: CGPoint(x: at - 8, y: tip))
            fold.addQuadCurve(to: CGPoint(x: at + 8, y: tip), control: CGPoint(x: at, y: tip + (fromTop ? 15 : -15)))
            fold.addLine(to: CGPoint(x: at + 10, y: base))
            context.stroke(fold, with: .color(highlight == "membrane" ? teal : edge),
                           style: StrokeStyle(lineWidth: highlight == "membrane" ? 4 : 2, lineCap: .round, lineJoin: .round))
        }
        if highlight == "compartment" {
            for i in 0..<6 { dot(x - 53 + CGFloat(i) * 21, rect.minY + 6, 3.5, lilac, stroke: edge) }
        }
    }
    private func membrane(_ y: CGFloat) {
        round(18, y - 22, 324, 44, peach.opacity(0.4), radius: 7)
        for i in 0..<22 {
            let x = 22 + CGFloat(i) * 15
            line(x - 2, y - 12, x - 3, y - 2, edge.opacity(0.55), width: 1)
            line(x + 2, y - 12, x + 3, y - 2, edge.opacity(0.55), width: 1)
            line(x - 2, y + 12, x - 3, y + 2, edge.opacity(0.55), width: 1)
            line(x + 2, y + 12, x + 3, y + 2, edge.opacity(0.55), width: 1)
            dot(x, y - 17, 4, peach, stroke: edge)
            dot(x, y + 17, 4, peach, stroke: edge)
        }
    }
    private func synthase(_ x: CGFloat, _ y: CGFloat) {
        round(x - 17, y - 30, 34, 61, sage, radius: 12, stroke: ink)
        round(x - 6, y + 20, 12, 38, teal, radius: 5, stroke: ink)
        ellipse(x - 39, y + 46, 78, 42, sage, stroke: ink)
        let angle = p * .pi * 4
        line(x - cos(angle) * 19, y + 66 - sin(angle) * 8,
             x + cos(angle) * 19, y + 66 + sin(angle) * 8, teal, width: 4)
    }

    private func overview() {
        // Glycolysis happens in the cytosol, before pyruvate enters the organelle.
        round(16, 8, 328, 107, sage.opacity(0.5), radius: 20)
        text("Glycolysis · cytosol", 180, 26, size: 15, bold: true)
        carbon(6, 78, 64, spacing: 17)
        text("Glucose", 78, 96, size: 15, bold: true)
        arrow(143, 64, 195, 64)
        carbon(3, 260, 54, spacing: 22)
        carbon(3, 260, 79, spacing: 22)
        text("2 pyruvate", 260, 103, size: 14, bold: true)
        arrow(259, 123, 242, 158)

        oxygen(63, 138)
        text("O₂", 63, 163, size: 15, bold: true)
        arrow(97, 141, 126, 164, color: RespirationTheme.color(0x4388A0))

        overviewMitochondrion()
        text("Mitochondrion", 180, 343, size: 15, bold: true)
        arrow(111, 333, 92, 355, color: edge)
        arrow(243, 329, 268, 352, color: RespirationTheme.color(0xB17D19))

        // Distinct atom colors keep the products recognizable as molecules.
        line(48, 385, 94, 385, edge, width: 3)
        dot(48, 385, 11, blue, stroke: ink)
        dot(71, 385, 9, peach, stroke: ink)
        dot(94, 385, 11, blue, stroke: ink)
        text("O", 48, 385, size: 9, bold: true)
        text("C", 71, 385, size: 9, bold: true)
        text("O", 94, 385, size: 9, bold: true)
        text("CO₂", 71, 420, size: 15, bold: true)
        water(163, 385)
        text("Water", 163, 420, size: 15, bold: true)
        atp(280, 385, scale: 1.03)
        text("Cell energy", 280, 427, size: 14, bold: true)
        for (x, y, angle) in [(CGFloat(248), CGFloat(361), -2.5), (310, 360, -0.6), (319, 391, 0.2)] {
            line(x, y, x + CGFloat(cos(angle)) * 6, y + CGFloat(sin(angle)) * 6, gold, width: 2)
        }
    }

    private func overviewMitochondrion() {
        ellipse(62, 315, 242, 17, ink.opacity(0.06))
        var shell = Path()
        shell.move(to: CGPoint(x: 45, y: 244))
        shell.addCurve(to: CGPoint(x: 56, y: 187), control1: CGPoint(x: 28, y: 214), control2: CGPoint(x: 33, y: 198))
        shell.addCurve(to: CGPoint(x: 151, y: 174), control1: CGPoint(x: 79, y: 165), control2: CGPoint(x: 115, y: 163))
        shell.addCurve(to: CGPoint(x: 235, y: 168), control1: CGPoint(x: 183, y: 183), control2: CGPoint(x: 208, y: 157))
        shell.addCurve(to: CGPoint(x: 316, y: 207), control1: CGPoint(x: 279, y: 156), control2: CGPoint(x: 309, y: 176))
        shell.addCurve(to: CGPoint(x: 309, y: 290), control1: CGPoint(x: 337, y: 231), control2: CGPoint(x: 334, y: 270))
        shell.addCurve(to: CGPoint(x: 232, y: 325), control1: CGPoint(x: 287, y: 311), control2: CGPoint(x: 263, y: 331))
        shell.addCurve(to: CGPoint(x: 135, y: 315), control1: CGPoint(x: 192, y: 323), control2: CGPoint(x: 165, y: 303))
        shell.addCurve(to: CGPoint(x: 62, y: 302), control1: CGPoint(x: 105, y: 328), control2: CGPoint(x: 77, y: 319))
        shell.addCurve(to: CGPoint(x: 45, y: 244), control1: CGPoint(x: 37, y: 284), control2: CGPoint(x: 33, y: 263))
        shell.closeSubpath()
        context.fill(shell, with: .linearGradient(Gradient(colors: [peach, RespirationTheme.color(0xEBAA99)]),
                                                  startPoint: CGPoint(x: 130, y: 170), endPoint: CGPoint(x: 200, y: 330)))
        context.stroke(shell, with: .color(ink), lineWidth: 2.5)

        // A single continuous inner membrane folds inward to form the cristae.
        var matrix = Path()
        matrix.move(to: CGPoint(x: 64, y: 202))
        matrix.addCurve(to: CGPoint(x: 109, y: 184), control1: CGPoint(x: 76, y: 183), control2: CGPoint(x: 94, y: 180))
        matrix.addQuadCurve(to: CGPoint(x: 122, y: 195), control: CGPoint(x: 119, y: 183))
        matrix.addLine(to: CGPoint(x: 127, y: 244))
        matrix.addQuadCurve(to: CGPoint(x: 144, y: 243), control: CGPoint(x: 137, y: 258))
        matrix.addLine(to: CGPoint(x: 141, y: 197))
        matrix.addQuadCurve(to: CGPoint(x: 154, y: 188), control: CGPoint(x: 140, y: 187))
        matrix.addLine(to: CGPoint(x: 174, y: 188))
        matrix.addQuadCurve(to: CGPoint(x: 187, y: 200), control: CGPoint(x: 187, y: 187))
        matrix.addLine(to: CGPoint(x: 193, y: 242))
        matrix.addQuadCurve(to: CGPoint(x: 209, y: 240), control: CGPoint(x: 205, y: 256))
        matrix.addLine(to: CGPoint(x: 204, y: 191))
        matrix.addQuadCurve(to: CGPoint(x: 222, y: 181), control: CGPoint(x: 203, y: 178))
        matrix.addCurve(to: CGPoint(x: 278, y: 188), control1: CGPoint(x: 244, y: 171), control2: CGPoint(x: 267, y: 176))
        matrix.addCurve(to: CGPoint(x: 306, y: 232), control1: CGPoint(x: 298, y: 198), control2: CGPoint(x: 312, y: 218))
        matrix.addCurve(to: CGPoint(x: 296, y: 272), control1: CGPoint(x: 311, y: 252), control2: CGPoint(x: 306, y: 268))
        matrix.addQuadCurve(to: CGPoint(x: 276, y: 285), control: CGPoint(x: 286, y: 285))
        matrix.addLine(to: CGPoint(x: 268, y: 250))
        matrix.addQuadCurve(to: CGPoint(x: 253, y: 251), control: CGPoint(x: 259, y: 237))
        matrix.addLine(to: CGPoint(x: 259, y: 297))
        matrix.addQuadCurve(to: CGPoint(x: 233, y: 306), control: CGPoint(x: 256, y: 313))
        matrix.addQuadCurve(to: CGPoint(x: 214, y: 293), control: CGPoint(x: 219, y: 306))
        matrix.addLine(to: CGPoint(x: 205, y: 273))
        matrix.addQuadCurve(to: CGPoint(x: 190, y: 273), control: CGPoint(x: 196, y: 259))
        matrix.addLine(to: CGPoint(x: 194, y: 297))
        matrix.addQuadCurve(to: CGPoint(x: 168, y: 302), control: CGPoint(x: 193, y: 312))
        matrix.addQuadCurve(to: CGPoint(x: 151, y: 289), control: CGPoint(x: 154, y: 302))
        matrix.addLine(to: CGPoint(x: 144, y: 270))
        matrix.addQuadCurve(to: CGPoint(x: 129, y: 270), control: CGPoint(x: 135, y: 258))
        matrix.addLine(to: CGPoint(x: 133, y: 293))
        matrix.addCurve(to: CGPoint(x: 92, y: 300), control1: CGPoint(x: 119, y: 305), control2: CGPoint(x: 103, y: 307))
        matrix.addCurve(to: CGPoint(x: 59, y: 270), control1: CGPoint(x: 77, y: 300), control2: CGPoint(x: 62, y: 284))
        matrix.addCurve(to: CGPoint(x: 64, y: 202), control1: CGPoint(x: 45, y: 243), control2: CGPoint(x: 47, y: 222))
        matrix.closeSubpath()
        context.fill(matrix, with: .linearGradient(Gradient(colors: [paper, RespirationTheme.color(0xFFF0D9)]),
                                                   startPoint: CGPoint(x: 180, y: 185), endPoint: CGPoint(x: 180, y: 310)))
        context.stroke(matrix, with: .color(edge), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
        var shine = Path()
        shine.move(to: CGPoint(x: 43, y: 220))
        shine.addQuadCurve(to: CGPoint(x: 76, y: 180), control: CGPoint(x: 43, y: 192))
        context.stroke(shine, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        dot(86, 254, 2.2, ink); dot(102, 254, 2.2, ink)
        var smile = Path(); smile.move(to: CGPoint(x: 88, y: 264))
        smile.addQuadCurve(to: CGPoint(x: 101, y: 264), control: CGPoint(x: 95, y: 274))
        context.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    private func glycolysis() {
        carbon(6, 180, 42)
        text("1 glucose · 6 carbons", 180, 74, bold: true)
        let q = phase(0.12, 0.7)
        arrow(158, 94, 111, 132); arrow(202, 94, 249, 132)
        carbon(3, 128 - 36 * q, 166)
        carbon(3, 232 + 36 * q, 166)
        text("Pyruvate", 92, 200, bold: true); text("Pyruvate", 268, 200, bold: true)
        text("3 carbons", 92, 221, size: 12); text("3 carbons", 268, 221, size: 12)
        round(25, 252, 310, 60, paper.opacity(0.8))
        atp(64, 282, scale: 0.7)
        text("2 net ATP", 136, 282, bold: true)
        pill("2 NADH", 263, 282, blue)
    }

    private func prepareFuel() {
        text("2 pyruvate", 86, 22, bold: true)
        text("2 acetyl CoA", 267, 22, bold: true)
        for i in 0..<2 {
            let y: CGFloat = i == 0 ? 92 : 187
            carbon(3, 85, y)
            arrow(132, y, 199, y)
            carbon(2, 250, y, color: sage)
            pill("CoA", 296, y, lilac, size: 11)
            let q = phase(0.12 + CGFloat(i) * 0.2, 0.65 + CGFloat(i) * 0.2)
            dot(153, y - 24 - q * 19, 10, peach, stroke: edge)
            text("CO₂", 181, y - 39, size: 12, bold: true)
        }
        round(32, 256, 296, 52, paper.opacity(0.8))
        pill("2 NADH", 112, 282, blue)
        text("0 direct ATP", 252, 282, bold: true)
    }

    private func krebs() {
        let cx: CGFloat = 180, cy: CGFloat = 151, r: CGFloat = 72
        context.stroke(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                       with: .color(teal.opacity(0.25)), lineWidth: 9)
        for i in 0..<3 {
            let a = CGFloat(i) * 2 * .pi / 3 + 0.5
            let x = cx + cos(a) * r, y = cy + sin(a) * r
            arrow(x, y, x - sin(a) * 13, y + cos(a) * 13)
        }
        let a = -CGFloat.pi / 2 + p * .pi * 4
        dot(cx + cos(a) * r, cy + sin(a) * r, 9, gold, stroke: ink)
        text("Krebs", cx, cy - 9, size: 22, bold: true)
        text("cycle", cx, cy + 17, size: 18)
        carbon(2, 64, 34, spacing: 22, color: sage)
        text("Acetyl CoA", 67, 60, size: 12, bold: true)
        arrow(96, 40, 153, 75)
        pill("CO₂", 292, 132, peach)
        arrow(259, 140, 269, 136)
        pill("2 turns per glucose", 180, 252, sage)
        text("6 NADH + 2 FADH₂", 137, 299, bold: true)
        atp(293, 296, scale: 0.65); text("2", 259, 297, size: 16, bold: true)
    }

    private func transport() {
        text("H⁺ builds up outside the matrix", 180, 21, size: 13, bold: true)
        for (i, x) in [CGFloat(41), 87, 135, 183, 230, 276, 319].enumerated() {
            proton(x, i.isMultiple(of: 2) ? 60 : 85, small: true)
        }
        membrane(155)
        for x: CGFloat in [83, 171, 259] {
            round(x - 23, 120, 46, 70, blue, radius: 18, stroke: ink)
            arrow(x, 177, x, 102)
            let q = (p * 2 + x / 180).truncatingRemainder(dividingBy: 1)
            proton(x, 178 - q * 77, small: true)
        }
        line(58, 208, 288, 208, gold, width: 3, dash: [4, 6])
        for i in 0..<3 {
            let x = 66 + (p + CGFloat(i) / 3).truncatingRemainder(dividingBy: 1) * 216
            electron(x, 208)
        }
        pill("NADH + FADH₂", 108, 252, blue, size: 12)
        arrow(58, 232, 58, 218)
        arrow(288, 209, 270, 233, color: gold)
        oxygen(264, 252); arrow(264, 272, 264, 286); water(264, 302)
        text("O₂ → H₂O", 155, 296, size: 13, bold: true)
        text("Matrix", 61, 302, size: 12, color: edge)
    }

    private func chemiosmosis() {
        text("High H⁺ concentration", 180, 23, size: 13, bold: true)
        for (i, x) in [CGFloat(45), 90, 135, 225, 270, 315].enumerated() {
            proton(x, i.isMultiple(of: 2) ? 63 : 84, small: true)
        }
        membrane(138)
        synthase(180, 138)
        arrow(180, 59, 180, 105)
        let q = (p * 2).truncatingRemainder(dividingBy: 1)
        proton(180, 70 + q * 111, small: true)
        text("ATP synthase", 76, 196, size: 13, bold: true)
        line(119, 194, 144, 194, edge, width: 1)
        pill("ADP + Pᵢ", 85, 266, blue)
        arrow(142, 266, 234, 266)
        atp(281, 266, scale: 0.95)
        text("Back into the matrix", 180, 316, size: 13, color: edge)
    }

    private func accounting() {
        round(30, 14, 300, 127, paper.opacity(0.85), radius: 24)
        atp(85, 77, scale: 0.85 + 0.3 * phase(0.1, 0.8))
        text("~30 ATP", 223, 63, size: 30, bold: true)
        text("actual yield per glucose", 222, 100, size: 12)
        round(30, 163, 140, 100, sage.opacity(0.6), radius: 20)
        round(190, 163, 140, 100, blue.opacity(0.65), radius: 20)
        text("4 ATP", 100, 191, size: 23, bold: true)
        text("made directly", 100, 221, size: 12)
        text("Most ATP", 260, 191, size: 19, bold: true)
        text("via ATP synthase", 260, 221, size: 12)
        text("36 ATP in the theoretical model", 180, 298, size: 12, color: edge)
    }

    private func efficiency() {
        let center = CGPoint(x: 180, y: 117)
        context.stroke(Path(ellipseIn: CGRect(x: 104, y: 41, width: 152, height: 152)), with: .color(peach), lineWidth: 26)
        var arc = Path()
        arc.addArc(center: center, radius: 76, startAngle: .degrees(-90),
                   endAngle: .degrees(Double(-90 + 115.2 * phase(0.05, 0.85))), clockwise: false)
        context.stroke(arc, with: .color(teal), style: StrokeStyle(lineWidth: 26, lineCap: .butt))
        carbon(6, 180, 115, spacing: 15)
        text("Glucose energy", 180, 153, size: 12, bold: true)
        atp(82, 252, scale: 0.8)
        text("~32%", 82, 298, size: 18, bold: true)
        for i in 0..<3 {
            var wave = Path()
            let x = 253 + CGFloat(i) * 14
            wave.move(to: CGPoint(x: x, y: 272))
            wave.addCurve(to: CGPoint(x: x, y: 229), control1: CGPoint(x: x - 14, y: 260), control2: CGPoint(x: x + 14, y: 246))
            context.stroke(wave, with: .color(edge), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
        text("~68% heat", 269, 298, size: 18, bold: true)
        arrow(127, 201, 99, 222); arrow(233, 201, 255, 222)
    }

    private func anaerobic() {
        text("Keep the electron transport chain", 180, 27, size: 14, bold: true)
        membrane(112)
        for x: CGFloat in [80, 160, 240] {
            round(x - 21, 78, 42, 68, blue, radius: 17, stroke: ink)
        }
        for i in 0..<3 {
            electron(80 + (p + CGFloat(i) / 3).truncatingRemainder(dividingBy: 1) * 160, 112)
        }
        arrow(108, 112, 128, 112, color: gold); arrow(188, 112, 208, 112, color: gold)
        arrow(277, 130, 277, 165)
        pill("NO₃⁻", 90, 197, blue)
        pill("SO₄²⁻", 180, 197, lilac)
        pill("CO₂", 270, 197, peach)
        text("A different final electron acceptor", 180, 241, size: 13, bold: true)
        pill("No oxygen needed", 180, 295, sage)
    }

    private func fermentation() {
        carbon(6, 180, 31, spacing: 18)
        arrow(180, 52, 180, 78)
        text("Glycolysis", 180, 99, size: 19, bold: true)
        atp(285, 99, scale: 0.65); text("2", 253, 99, size: 15, bold: true)
        pill("NAD⁺", 80, 149, blue)
        pill("NADH", 280, 149, lilac)
        arrow(126, 149, 234, 149)
        var recycle = Path()
        recycle.move(to: CGPoint(x: 280, y: 171))
        recycle.addCurve(to: CGPoint(x: 80, y: 171), control1: CGPoint(x: 280, y: 259), control2: CGPoint(x: 80, y: 259))
        context.stroke(recycle, with: .color(teal), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        arrow(80, 188, 80, 170)
        if p > 0, p < 1 {
            let q = phase(0.1, 0.9), r = 1 - q
            electron(280 * r * r * r + 840 * r * r * q + 240 * r * q * q + 80 * q * q * q,
                     171 * r * r * r + 777 * r * r * q + 777 * r * q * q + 171 * q * q * q)
        }
        text("Recycle NAD⁺", 180, 254, size: 14, bold: true)
        pill("Lactate", 94, 294, peach)
        text("or", 180, 294, size: 12)
        pill("Ethanol + CO₂", 269, 294, sage, size: 12)
        text("Pyruvate → products", 180, 186, size: 12, color: edge)
    }

    private func drawPlayer(_ id: String) {
        switch id {
        case "mitochondrion", "matrix", "membrane", "compartment", "cytosol":
            mitochondrion(180, 132, width: 276, height: 152, highlight: id)
            if id == "cytosol" {
                for x: CGFloat in [31, 79, 285, 331] { dot(x, 32, 5, blue, stroke: edge) }
                pill("Cytosol", 180, 235, blue)
            } else {
                let label = id == "matrix" ? "Matrix" : id == "membrane" ? "Inner membrane" : id == "compartment" ? "H⁺ holding space" : "Folded inner membrane"
                pill(label, 180, 235, id == "matrix" ? sage : peach)
            }
        case "atp":
            atp(180, 115, scale: 1.85)
            for i in 0..<3 {
                let a = CGFloat(i) * 2 * .pi / 3 - .pi / 2
                dot(180 + cos(a) * 104, 120 + sin(a) * 83, 7, gold.opacity(0.5))
            }
            pill("Energy for cell work", 180, 231, sage)
        case "nad", "fad":
            let unloaded = id == "nad" ? "NAD⁺" : "FAD"
            let loaded = id == "nad" ? "NADH" : "FADH₂"
            round(30, 77, 125, 91, paper.opacity(0.85), radius: 26, stroke: edge)
            round(205, 77, 125, 91, blue, radius: 26, stroke: ink)
            text(unloaded, 92, 121, size: 21, bold: true)
            text(loaded, 267, 121, size: 21, bold: true)
            electron(253, 64); electron(280, 64)
            arrow(166, 123, 194, 123)
            pill("Picks up energetic electrons", 180, 227, blue)
        case "synthase":
            membrane(85); synthase(180, 85)
            proton(180, 29); arrow(180, 43, 180, 69)
            pill("ADP + Pᵢ", 78, 213, blue); arrow(137, 213, 234, 213); atp(283, 213)
        case "acetyl":
            carbon(3, 82, 100); arrow(135, 100, 205, 100)
            carbon(2, 252, 100, color: sage); pill("CoA", 303, 100, lilac, size: 11)
            pill("CO₂", 177, 57, peach); pill("3 carbons → 2 carbons", 180, 221, sage)
        case "cycle":
            carbon(2, 66, 82, color: sage); text("+", 142, 82, size: 24)
            carbon(4, 237, 82, color: blue)
            arrow(180, 112, 180, 149)
            carbon(6, 180, 183)
            text("2C + 4C → 6C citrate", 180, 235, size: 16, bold: true)
        case "phosphorylation":
            pill("Direct transfer", 92, 38, blue)
            pill("H⁺ flow", 270, 38, sage)
            carbon(2, 92, 101, color: blue)
            arrow(92, 124, 92, 170); atp(92, 211)
            proton(270, 99); arrow(270, 124, 270, 170); atp(270, 211)
        case "redox":
            pill("Donor", 78, 65, blue); pill("Acceptor", 278, 65, peach)
            arrow(113, 126, 247, 126)
            electron(164, 126); electron(195, 126)
            text("Loses e⁻", 78, 173, size: 15, bold: true)
            text("Gains e⁻", 278, 173, size: 15, bold: true)
            pill("Oxidation → reduction", 180, 235, sage)
        default:
            pill("NADH", 84, 89, lilac); arrow(137, 89, 224, 89); pill("NAD⁺", 278, 89, blue)
            carbon(3, 84, 171); arrow(137, 171, 224, 171); pill("Lactate", 278, 171, peach)
            text("Recycle NAD⁺ to keep glycolysis going", 180, 235, size: 13, bold: true)
        }
    }
}
