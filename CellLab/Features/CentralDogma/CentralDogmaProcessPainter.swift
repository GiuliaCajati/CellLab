import SwiftUI

/// One short teaching sequence shared by transcription and translation.
/// DNA is read 3′ → 5′; RNA is built and read 5′ → 3′.
nonisolated enum CentralDogmaMolecules {
    static let exons = ["AUGGCU", "UUCUAA"]
    static let intron = "GUACAG"
    static let preMessenger = Array(exons[0] + intron + exons[1]).map(String.init)
    static let messenger = Array(exons.joined()).map(String.init)
    static let template = preMessenger.map { complement($0, rna: false) }
    static let coding = template.map { complement($0, rna: false) }
    static let codons = ["AUG", "GCU", "UUC", "UAA"]
    static let aminoAcids = ["Met", "Ala", "Phe"]

    static func complement(_ base: String, rna: Bool = true) -> String {
        switch base {
        case "A": rna ? "U" : "T"
        case "T", "U": "A"
        case "G": "C"
        case "C": "G"
        default: "?"
        }
    }

    static func anticodon(for codon: String) -> String? {
        guard !["UAA", "UAG", "UGA"].contains(codon) else { return nil }
        return codon.map { complement(String($0)) }.joined()
    }
}

/// Native molecular drawings, in the same 360 × 420 coordinate space and
/// sugar / phosphate / base vocabulary as the S phase illustrations.
struct CentralDogmaProcessPainter {
    var context: GraphicsContext
    let step: CentralDogmaStep
    let p: CGFloat
    private let ink = CentralDogmaTheme.ink
    private let edge = CentralDogmaTheme.edge
    private let dna = CentralDogmaTheme.parental
    private let rna = CentralDogmaTheme.rna
    private let protein = CentralDogmaTheme.newDNA
    private let paper = CentralDogmaTheme.paper
    private let blue = DNAReplicationTint.blue.color
    private let mint = MeiPalette.mint
    private let lilac = MeiPalette.lilac
    private let butter = MeiPalette.butter

    func draw() {
        switch step {
        case .overview: overview()
        case .transcriptionStart: openDNA()
        case .transcriptionBuild: writeRNA()
        case .transcriptionEnd: releaseRNA()
        case .processing: editRNA()
        case .translationStart: startTranslation()
        case .translationBuild: buildProtein()
        case .translationEnd: releaseProtein()
        case .folding: foldProtein()
        case .finishing: finishProtein()
        }
    }

    private func clamp(_ x: CGFloat) -> CGFloat { min(max(x, 0), 1) }
    private func smooth(_ x: CGFloat) -> CGFloat { let q = clamp(x); return q * q * (3 - 2 * q) }
    private func phase(_ from: CGFloat, _ to: CGFloat) -> CGFloat { smooth((p - from) / (to - from)) }
    private func mix(_ a: CGFloat, _ b: CGFloat, _ q: CGFloat) -> CGFloat { a + (b - a) * q }
    private func point(_ a: CGPoint, _ b: CGPoint, _ q: CGFloat) -> CGPoint {
        CGPoint(x: mix(a.x, b.x, q), y: mix(a.y, b.y, q))
    }
    private func line(_ a: CGPoint, _ b: CGPoint, _ color: Color, _ width: CGFloat = 1.5, dash: [CGFloat] = []) {
        var path = Path(); path.move(to: a); path.addLine(to: b)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
    }
    private func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat,
                      _ color: Color, _ width: CGFloat = 1.5, dash: [CGFloat] = []) {
        line(CGPoint(x: x1, y: y1), CGPoint(x: x2, y: y2), color, width, dash: dash)
    }
    private func shape(_ path: Path, _ fill: Color, _ stroke: Color? = nil, _ width: CGFloat = 1.5) {
        context.fill(path, with: .color(fill))
        if let stroke { context.stroke(path, with: .color(stroke), lineWidth: width) }
    }
    private func round(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                       _ fill: Color, _ radius: CGFloat = 12, _ stroke: Color? = nil) {
        shape(Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius), fill, stroke)
    }
    private func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ fill: Color, _ stroke: Color? = nil) {
        shape(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), fill, stroke)
    }
    private func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 12,
                      _ color: Color = CentralDogmaTheme.ink, bold: Bool = false) {
        context.draw(Text(value).font(.system(size: size, weight: bold ? .bold : .medium, design: .rounded))
            .foregroundStyle(color), at: CGPoint(x: x, y: y))
    }
    private func pill(_ value: String, _ x: CGFloat, _ y: CGFloat, _ fill: Color, _ size: CGFloat = 11) {
        let label = context.resolve(Text(value).font(.system(size: size, weight: .bold, design: .rounded)).foregroundStyle(ink))
        let width = label.measure(in: CGSize(width: 330, height: 30)).width + 20
        round(x - width / 2, y - 12, width, 24, fill)
        context.draw(label, at: CGPoint(x: x, y: y))
    }
    private func arrow(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ color: Color) {
        line(x1, y1, x2, y2, color, 1.8)
        let a = atan2(y2 - y1, x2 - x1)
        line(x2, y2, x2 - 7 * cos(a - 0.55), y2 - 7 * sin(a - 0.55), color, 1.8)
        line(x2, y2, x2 - 7 * cos(a + 0.55), y2 - 7 * sin(a + 0.55), color, 1.8)
    }
    private func sugar(_ x: CGFloat, _ y: CGFloat, _ color: Color, _ r: CGFloat = 4) {
        var path = Path()
        for i in 0..<5 {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * 2 * .pi / 5
            let pt = CGPoint(x: x + r * cos(angle), y: y + r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath(); shape(path, color, ink, 0.7)
    }
    private func base(_ value: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat = 20, rna isRNA: Bool = false) {
        let color: Color
        switch value {
        case "A": color = DNAReplicationTint.peach.color
        case "T": color = blue
        case "U": color = butter
        case "C": color = lilac
        default: color = mint
        }
        round(x - width / 2, y - 10, width, 20, color, 4, edge)
        text(value, x, y + 0.5, min(14, width - 3), ink, bold: true)
        if isRNA { line(x - width / 2 + 2, y + 12, x + width / 2 - 2, y + 12, rna, 2) }
    }
    private func nucleotide(_ value: String, _ x: CGFloat, _ backboneY: CGFloat, _ baseY: CGFloat,
                            rna isRNA: Bool = false, width: CGFloat = 20) {
        let color = isRNA ? rna : dna
        line(x, backboneY, x, baseY, color)
        sugar(x, backboneY, color)
        circle(x + 10, backboneY, 2.3, butter, edge)
        base(value, x, baseY, width, rna: isRNA)
    }
    private func singleRNA(_ values: [String], x: CGFloat, y: CGFloat, spacing: CGFloat = 24) {
        guard !values.isEmpty else { return }
        line(x - 10, y + 22, x + CGFloat(values.count - 1) * spacing + 10, y + 22, rna, 3)
        for (i, value) in values.enumerated() {
            let at = x + CGFloat(i) * spacing
            guard at > 25, at < 335 else { continue }
            nucleotide(value, at, y + 22, y, rna: true, width: min(20, spacing - 5))
        }
    }
    private func amino(_ name: String?, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat = 14, color: Color? = nil) {
        circle(x, y, r, color ?? protein, ink)
        circle(x - r * 0.28, y - r * 0.3, r * 0.22, .white.opacity(0.55))
        if let name { text(name, x, y + 1, 9, ink, bold: true) }
    }
    private func polymerase(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat = 104) {
        // Preserve the existing artwork's 3:2 proportions at every zoom level.
        let height = width * 2 / 3
        context.draw(context.resolve(Image("CentralRNAWriter")),
                     in: CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height))
    }
    private func ribosome(_ x: CGFloat, top: CGFloat, bottom: CGFloat, width: CGFloat = 176) {
        // Two separate subunits leave an open channel for the message.
        var upper = Path()
        upper.move(to: CGPoint(x: x - width / 2, y: top + 29))
        upper.addCurve(to: CGPoint(x: x + width / 2, y: top + 29),
                       control1: CGPoint(x: x - width * 0.43, y: top - 63),
                       control2: CGPoint(x: x + width * 0.4, y: top - 63))
        upper.addQuadCurve(to: CGPoint(x: x - width / 2, y: top + 29), control: CGPoint(x: x, y: top + 12))
        shape(upper, lilac.opacity(0.75), ink, 1.8)
        var lower = Path()
        lower.move(to: CGPoint(x: x - width * 0.43, y: bottom))
        lower.addQuadCurve(to: CGPoint(x: x + width * 0.43, y: bottom), control: CGPoint(x: x, y: bottom - 14))
        lower.addCurve(to: CGPoint(x: x - width * 0.43, y: bottom),
                       control1: CGPoint(x: x + width * 0.35, y: bottom + 40),
                       control2: CGPoint(x: x - width * 0.35, y: bottom + 40))
        shape(lower, mint, ink, 1.8)
    }
    private func trna(_ x: CGFloat, _ y: CGFloat, anticodon: String, amino name: String? = nil) {
        var path = Path()
        path.move(to: CGPoint(x: x - 6, y: y - 53))
        path.addLine(to: CGPoint(x: x - 6, y: y - 35))
        path.addCurve(to: CGPoint(x: x - 16, y: y - 8), control1: CGPoint(x: x - 52, y: y - 60), control2: CGPoint(x: x - 48, y: y + 4))
        path.addQuadCurve(to: CGPoint(x: x - 13, y: y + 25), control: CGPoint(x: x - 3, y: y + 7))
        path.addQuadCurve(to: CGPoint(x: x + 13, y: y + 25), control: CGPoint(x: x, y: y + 43))
        path.addQuadCurve(to: CGPoint(x: x + 16, y: y - 8), control: CGPoint(x: x + 3, y: y + 7))
        path.addCurve(to: CGPoint(x: x + 6, y: y - 35), control1: CGPoint(x: x + 48, y: y + 4), control2: CGPoint(x: x + 52, y: y - 60))
        path.addLine(to: CGPoint(x: x + 6, y: y - 53))
        shape(path, mint, ink, 1.5)
        for (i, value) in anticodon.enumerated() { base(String(value), x + CGFloat(i - 1) * 24, y + 34, 18, rna: true) }
        if let name {
            line(x, y - 53, x, y - 65, protein, 2)
            amino(name, x, y - 79)
        }
    }

    private func overview() {
        pill("IN THE NUCLEUS", 180, 20, blue)
        for i in 0..<8 {
            let x = CGFloat(65 + i * 32)
            let offset = sin(CGFloat(i) * 0.9 + p * .pi) * 12
            line(x, 66 + offset, x, 99 - offset, edge, 1, dash: [2, 2])
            circle(x, 66 + offset, 3, dna); circle(x, 99 - offset, 3, dna)
        }
        var a = Path(), b = Path()
        for i in 0...80 {
            let x = CGFloat(58) + CGFloat(i) * 3.05
            let wave = sin((x - 65) / 32 * 0.9 + p * .pi) * 12
            if i == 0 { a.move(to: CGPoint(x: x, y: 66 + wave)); b.move(to: CGPoint(x: x, y: 99 - wave)) }
            else { a.addLine(to: CGPoint(x: x, y: 66 + wave)); b.addLine(to: CGPoint(x: x, y: 99 - wave)) }
        }
        context.stroke(a, with: .color(dna), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        context.stroke(b, with: .color(dna), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        text("DNA · a gene", 180, 123, 12, dna, bold: true)
        arrow(180, 143, 180, 168, ink)
        pill("Transcription", 271, 155, butter)
        singleRNA(Array(CentralDogmaMolecules.messenger.prefix(8)), x: 68, y: 194, spacing: 32)
        text("RNA · the message", 180, 241, 12, rna, bold: true)
        line(24, 266, 152, 266, edge, 1, dash: [3, 4]); line(208, 266, 336, 266, edge, 1, dash: [3, 4])
        arrow(180, 254, 180, 286, ink)
        text("CYTOPLASM", 72, 281, 10, edge, bold: true)
        ribosome(137, top: 315, bottom: 384, width: 126)
        singleRNA(["A", "U", "G", "G", "C", "U"], x: 69, y: 357, spacing: 27)
        let count = 3 + Int(floor(p * 3))
        for i in 0..<count {
            let x = CGFloat(165 + i * 20), y = CGFloat(310 - i * 5)
            if i > 0 { line(x - 20, y + 5, x, y, protein, 3) }
            amino(nil, x, y, 9)
        }
        pill("Translation", 271, 337, lilac)
        text("Protein chain", 275, 405, 12, ink, bold: true)
    }

    private func doubleDNA(opening: CGFloat, center: CGFloat = 180, y: CGFloat = 170) {
        let xs = (0..<12).map { CGFloat(48 + $0 * 24) }
        for top in [true, false] {
            var path = Path()
            for j in 0...140 {
                let x = CGFloat(35) + CGFloat(j) * 2.1
                let bubble = opening * pow(max(0, 1 - abs(x - center) / 88), 1.5)
                let atY = y + (top ? -25 - bubble : 25 + bubble)
                if j == 0 { path.move(to: CGPoint(x: x, y: atY)) } else { path.addLine(to: CGPoint(x: x, y: atY)) }
            }
            context.stroke(path, with: .color(dna), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        for i in 0..<xs.count {
            let x = xs[i], bubble = opening * pow(max(0, 1 - abs(x - center) / 88), 1.5)
            let upper = y - 25 - bubble, lower = y + 25 + bubble
            nucleotide(CentralDogmaMolecules.coding[i], x, upper, upper + 16, width: 15)
            nucleotide(CentralDogmaMolecules.template[i], x, lower, lower - 16, width: 15)
            if bubble < 8 { line(x, upper + 26, x, lower - 26, edge, 1, dash: [2, 2]) }
        }
        text("5′", 19, y - 25, 12, dna, bold: true); text("3′", 341, y - 25, 12, dna, bold: true)
        text("3′", 19, y + 25, 12, dna, bold: true); text("5′", 341, y + 25, 12, dna, bold: true)
    }

    private func openDNA() {
        pill("NUCLEUS · FIND THE START", 180, 20, blue)
        round(57, 129, 48, 82, butter.opacity(0.7), 12)
        let q = smooth(p)
        doubleDNA(opening: 65 * q)
        polymerase(mix(277, 180, q), mix(315, 170, q), 132)
        pill("Promoter", 76, 84, butter)
        line(76, 98, 76, 126, edge, 1, dash: [2, 3])
        for i in 0..<2 {
            let x = CGFloat(70 + i * 26)
            round(x - 11, 244, 22, 19, lilac, 7, edge)
            line(x, 244, 82 + CGFloat(i) * 6, 209, edge, 1, dash: [2, 3])
        }
        text("Transcription factors", 92, 283, 11, ink, bold: true)
        pill("RNA polymerase", 130, 337, blue)
        line(157, 326, mix(277, 180, q) - 44, mix(315, 170, q) + 32, edge)
        text("A small DNA bubble opens", 180, 389, 13, ink, bold: true)
    }

    private func writeRNA() {
        pill("ZOOM · THE EXPOSED TEMPLATE", 180, 20, blue)
        let values = Array(CentralDogmaMolecules.template.prefix(6))
        let xs = (0..<6).map { CGFloat(65 + $0 * 46) }
        let completed = min(6, Int(floor(p * 6 + 0.00001)))
        let local = p >= 1 ? CGFloat(1) : smooth(p * 6 - CGFloat(completed))
        let tip = p >= 1 ? xs[5] : mix(xs[max(0, completed - 1)], xs[completed], local)
        // Keep the writer beside the growing end so every base pair stays visible.
        polymerase(tip, 267)
        line(tip, 224, tip, 232, edge, 1, dash: [2, 2])
        line(46, 126, 314, 126, dna, 3)
        for i in 0..<6 { nucleotide(values[i], xs[i], 126, 150, width: 24) }
        text("3′", 30, 126, 13, dna, bold: true); text("5′", 330, 126, 13, dna, bold: true)
        text("DNA template", 180, 85, 12, dna, bold: true)
        if completed > 0 {
            line(46, 224, xs[completed - 1], 224, rna, 3)
            for i in 0..<completed {
                nucleotide(CentralDogmaMolecules.messenger[i], xs[i], 224, 198, rna: true, width: 24)
                line(xs[i], 162, xs[i], 185, edge, 1, dash: [2, 3])
            }
            text("5′", 30, 224, 13, rna, bold: true)
            text("3′", min(328, xs[completed - 1] + 20), 224, 12, rna, bold: true)
        }
        if completed < 6 {
            let x = mix(315, xs[completed], local), y = mix(307, 198, local)
            base(CentralDogmaMolecules.messenger[completed], x, y, 24, rna: true)
        }
        pill("RNA polymerase", 180, 315, blue)
        line(180, 303, tip, 301, edge, 1, dash: [2, 3])
        arrow(65, 337, 295, 337, rna)
        text("New RNA grows 5′ → 3′", 180, 363, 13, ink, bold: true)
        text("Each new base matches the DNA", 180, 395, 11, edge)
    }

    private func releaseRNA() {
        pill("FINISH THE RNA COPY", 180, 20, blue)
        let q = smooth(p)
        doubleDNA(opening: (1 - q) * 58)
        polymerase(mix(180, 280, q), mix(170, 76, q), 92)
        text("DNA closes again", 120, 62, 12, dna, bold: true)
        let y = mix(271, 321, q)
        line(35, y, 325, y, rna, 3)
        round(35, y - 14, 105, 28, blue, 8, edge); text("Exon 1", 87, y, 11, ink, bold: true)
        round(145, y - 14, 70, 28, mint, 8, edge); text("Intron", 180, y, 11, ink, bold: true)
        round(220, y - 14, 105, 28, lilac, 8, edge); text("Exon 2", 272, y, 11, ink, bold: true)
        text("5′", 21, y, 12, rna, bold: true); text("3′", 337, y, 12, rna, bold: true)
        arrow(180, mix(236, 258, q), 180, mix(249, 292, q), rna)
        pill("Pre-mRNA released", 180, 387, butter)
        text("RNA polymerase", 275, 242, 11, ink, bold: true)
        line(275, 230, mix(180, 280, q) + 24, mix(170, 76, q) + 23,
             edge, 1, dash: [2, 3])
    }

    private func editRNA() {
        pill("NUCLEUS · CAP, TAIL & SPLICE", 180, 20, blue)
        text("Pre-mRNA", 180, 61, 12, ink, bold: true)
        line(34, 107, 326, 107, rna, 3)
        round(35, 89, 105, 36, blue, 9, edge); text("Exon 1", 87, 107, 12, ink, bold: true)
        round(220, 89, 105, 36, lilac, 9, edge); text("Exon 2", 272, 107, 12, ink, bold: true)
        let removed = phase(0.15, 0.55)
        round(145, 89 + removed * 62, 70, 36, mint, 9, edge)
        text("Intron", 180, 107 + removed * 62, 11, ink, bold: true)
        arrow(90, 143, 128, 218, edge); arrow(270, 143, 232, 218, edge)
        text("Remove the intron", 180, 197, 11, ink, bold: true)
        let join = phase(0.4, 0.75)
        let left = mix(92, 123, join), right = mix(268, 237, join)
        line(left - 49, 268, right + 49, 268, rna, 3)
        round(left - 51, 250, 102, 36, blue, 9, edge); text(CentralDogmaMolecules.exons[0], left, 268, 12, ink, bold: true)
        round(right - 51, 250, 102, 36, lilac, 9, edge); text(CentralDogmaMolecules.exons[1], right, 268, 12, ink, bold: true)
        if join > 0.8 { line(left + 51, 268, right - 51, 268, rna, 4) }
        let cap = phase(0, 0.3)
        circle(mix(28, left - 60, cap), mix(215, 268, cap), 8, butter, ink)
        text("5′ cap", 53, 315, 11, ink, bold: true)
        let tail = phase(0.05, 0.4)
        for i in 0..<6 {
            let x = right + 57 + CGFloat(i) * mix(2, 7, join)
            circle(x, 268 + sin(CGFloat(i) * 0.6) * 3 + (1 - tail) * 40, 3, butter, edge)
        }
        text("poly-A tail", 290, 315, 11, ink, bold: true)
        text("Mature mRNA · exons joined", 180, 358, 13, ink, bold: true)
        arrow(180, 375, 180, 397, rna)
        text("To the cytoplasm", 265, 395, 11, edge)
    }

    private func translationMessage(x: CGFloat = 40, shift: CGFloat = 0, y: CGFloat = 300) {
        singleRNA(CentralDogmaMolecules.messenger, x: x - shift, y: y)
        for codon in 0..<4 {
            let center = x + CGFloat(codon * 72 + 24) - shift
            if center > 40 && center < 320 {
                line(center - 31, y + 33, center + 31, y + 33, rna, 2)
            }
        }
        text("5′", 16, y + 22, 12, rna, bold: true); text("3′", 343, y + 22, 12, rna, bold: true)
    }

    private func startTranslation() {
        pill("CYTOPLASM · START AT AUG", 180, 20, lilac)
        let docking = phase(0.08, 0.55), joining = phase(0.55, 0.95)
        ribosome(100, top: mix(101, 254, joining), bottom: mix(363, 328, phase(0, 0.3)), width: 181)
        let x = mix(278, 64, docking), y = mix(193, 237, docking)
        trna(x, y, anticodon: "UAC", amino: "Met")
        translationMessage(y: 300)
        if docking > 0.9 {
            for at in [CGFloat(40), 64, 88] { line(at, 283, at, 288, edge, 1, dash: [1, 2]) }
        }
        pill("Ribosome", 269, 87, lilac)
        line(236, 101, 167, mix(101, 254, joining), edge, 1, dash: [2, 3])
        text("tRNA brings methionine", 180, 405, 11, ink, bold: true)
        pill("AUG · start codon", 269, 376, butter)
        text("mRNA", 280, 354, 11, rna, bold: true)
    }

    private func buildProtein() {
        pill("MATCH → LINK → MOVE", 180, 20, lilac)
        let arrival = phase(0, 0.32), bond = phase(0.32, 0.58), move = phase(0.7, 1)
        ribosome(100, top: 253, bottom: 328, width: 181)
        translationMessage(shift: move * 72)
        var leaving = self; leaving.context.opacity *= Double(1 - phase(0.7, 0.98))
        leaving.trna(mix(64, 23, move), mix(237, 207, move), anticodon: "UAC", amino: bond == 0 ? "Met" : nil)
        let x = mix(280, 136, arrival) - move * 72
        let y = mix(220, 237, arrival)
        trna(x, y, anticodon: "CGA", amino: "Ala")
        if bond > 0 {
            let metX = mix(64, x - 8, bond), metY = mix(158, y - 111, bond)
            line(metX, metY, x, y - 79, protein, 3)
            amino("Met", metX, metY)
        }
        pill("Peptide bond", 265, 94, MeiPalette.blush)
        line(236, 108, max(89, x), y - 94, edge, 1, dash: [2, 3])
        text("tRNAs match the mRNA codons", 180, 58, 12, ink, bold: true)
        arrow(67, 376, 292, 376, ink)
        text("Move 5′ → 3′. Repeat for each codon.", 180, 402, 11, ink, bold: true)
    }

    private func releaseProtein() {
        pill("A STOP CODON ENDS TRANSLATION", 180, 20, lilac, 10)
        let release = phase(0.35, 0.7), separate = phase(0.7, 1)
        ribosome(175, top: 253 - separate * 67, bottom: 328 + separate * 14, width: 208)
        singleRNA(Array("UUCUAA").map(String.init), x: 106, y: 300, spacing: 24)
        text("5′", 79, 322, 12, rna, bold: true); text("3′", 264, 322, 12, rna, bold: true)
        line(170, 333, 234, 333, protein, 2)
        let rfY = mix(110, 250, phase(0, 0.35)) - separate * 35
        round(187, rfY - 22, 30, 44, butter, 12, ink); text("RF", 202, rfY, 10, ink, bold: true)
        pill("Release factor", 269, 71, butter)
        var carrier = self; carrier.context.opacity *= Double(1 - separate)
        carrier.trna(130, 237, anticodon: "AAG")
        for i in 0..<3 {
            let x = 130 - CGFloat(i) * 14 - release * 55
            let y = 157 - CGFloat(i) * 29 - release * 55
            if i > 0 { line(x + 14, y + 29, x, y, protein, 3) }
            amino(CentralDogmaMolecules.aminoAcids[2 - i], x, y)
        }
        text("Protein chain released", 180, 52, 11, ink, bold: true)
        pill("UAA · stop", 292, 278, MeiPalette.blush, 10)
        line(253, 292, 235, 305, edge, 1, dash: [2, 3])
        text("A release factor binds instead of tRNA", 180, 406, 10, ink, bold: true)
    }

    private func foldProtein() {
        pill("ONE CHAIN → A FUNCTIONAL SHAPE", 180, 20, MeiPalette.blush, 10)
        let fold = phase(0.08, 0.85)
        var helper = self; helper.context.opacity *= Double(1 - phase(0.8, 1) * 0.65)
        let ring = Path(ellipseIn: CGRect(x: 67, y: 149, width: 226, height: 158))
        helper.context.stroke(ring, with: .color(edge.opacity(0.55)), style: StrokeStyle(lineWidth: 13, dash: [44, 22]))
        let colors = [protein, blue, butter, mint, lilac]
        var previous: CGPoint?
        for i in 0..<20 {
            let t = CGFloat(i) / 19
            let start = CGPoint(x: 30 + t * 300, y: 112 + sin(t * .pi * 3) * 15)
            let angle = t * .pi * 4.4
            let radius = 18 + t * 52
            let end = CGPoint(x: 180 + cos(angle) * radius, y: 220 + sin(angle) * radius * 0.8)
            let at = point(start, end, fold)
            if let previous { line(previous, at, protein, 3) }
            amino(nil, at.x, at.y, 8, color: colors[i % colors.count])
            if i == 0 { text("N", at.x - 13, at.y - 14, 10, ink, bold: true) }
            if i == 19 { text("C", at.x + 13, at.y + 14, 10, ink, bold: true) }
            previous = at
        }
        pill("Chaperone proteins help folding", 180, 347, mint)
        text("Same chain. A new 3D shape.", 180, 397, 13, ink, bold: true)
    }

    private func finishProtein() {
        pill("CLEAVAGE · TRIM A PRECURSOR", 180, 20, MeiPalette.blush, 10)
        let trim = phase(0, 0.55)
        let left = mix(95, 145, trim), right = mix(265, 205, trim)
        for chain in 0..<2 {
            let x = chain == 0 ? left : right
            for i in 0..<5 {
                let y = CGFloat(80 + i * 13)
                if i > 0 { line(x, y - 13, x, y, protein, 3) }
                amino(nil, x, y, 6, color: chain == 0 ? blue : protein)
            }
            text(chain == 0 ? "A" : "B", x, 62, 11, ink, bold: true)
        }
        if trim > 0.5 {
            line(left + 7, 93, right - 7, 93, rna, 2)
            line(left + 7, 119, right - 7, 119, rna, 2)
        }
        let connector = self
        if trim < 0.2 {
            connector.line(left, 132, left + trim * 90, 145 + trim * 20, edge, 2)
            connector.line(right, 132, right + trim * 90, 145 + trim * 20, edge, 2)
        }
        for i in 0..<7 {
            let t = CGFloat(i) / 6
            let x = mix(left, right, t) + trim * 90
            let y = 145 + sin(t * .pi) * 25 + trim * 20
            if i > 0 {
                let oldT = CGFloat(i - 1) / 6
                connector.line(mix(left, right, oldT) + trim * 90, 145 + sin(oldT * .pi) * 25 + trim * 20, x, y, edge, 2)
            }
            connector.amino(nil, x, y, 5, color: mint)
        }
        if trim > 0.2 { text("C-peptide", 284, 153, 10, edge) }
        text("Proinsulin → insulin · 51 amino acids", 180, 209, 11, ink, bold: true)
        line(28, 232, 332, 232, edge.opacity(0.25))
        pill("ASSEMBLY · BRING CHAINS TOGETHER", 180, 257, blue, 10)
        let assemble = phase(0.45, 1)
        let starts = [CGPoint(x: 74, y: 300), CGPoint(x: 286, y: 300), CGPoint(x: 74, y: 364), CGPoint(x: 286, y: 364)]
        let ends = [CGPoint(x: 160, y: 311), CGPoint(x: 200, y: 311), CGPoint(x: 160, y: 347), CGPoint(x: 200, y: 347)]
        for i in 0..<4 {
            let at = point(starts[i], ends[i], assemble)
            shape(Path(ellipseIn: CGRect(x: at.x - 25, y: at.y - 22, width: 50, height: 44)), i < 2 ? blue : lilac, ink)
            circle(at.x, at.y, 5, protein, ink)
        }
        text("Hemoglobin · four subunits", 180, 405, 12, ink, bold: true)
    }
}
