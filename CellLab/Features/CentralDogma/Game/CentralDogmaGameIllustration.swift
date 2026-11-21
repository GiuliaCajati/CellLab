import SwiftUI

/// The same cell stays on screen while the player's message moves out of its nucleus.
struct CentralDogmaGameJourney: View {
    var rnaCount = 0
    var chainCount = 0
    var exported = false
    var assembled = false
    var phase = "Transcribe"
    var preview = false
    var rnaSequence = "AUGAUGAUGUAA"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var outside: Bool { exported || preview }
    private var visibleRNA: Int { preview ? 12 : rnaCount }
    private var aminoCount: Int { preview ? 3 : chainCount }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            ZStack {
                Canvas { context, size in
                    let cell = CGRect(x: 1, y: 12, width: size.width - 2, height: 174)
                    let nucleus = CGRect(x: size.width * 0.04, y: 30, width: size.width * 0.43, height: 136)
                    context.fill(Path(ellipseIn: cell), with: .color(CentralDogmaGameTheme.sage.opacity(0.26)))
                    context.stroke(Path(ellipseIn: cell), with: .color(CentralDogmaGameTheme.edge.opacity(0.6)), lineWidth: 1.5)
                    context.fill(Path(ellipseIn: nucleus), with: .color(CentralDogmaGameTheme.blue.opacity(0.7)))
                    context.stroke(Path(ellipseIn: nucleus), with: .color(CentralDogmaGameTheme.teal), lineWidth: 2)
                    context.stroke(Path(ellipseIn: nucleus.insetBy(dx: 5, dy: 5)), with: .color(CentralDogmaGameTheme.edge.opacity(0.35)), lineWidth: 1)
                    // A visible pore in the double nuclear envelope.
                    let pore = CGRect(x: size.width * 0.425, y: 117, width: 20, height: 25)
                    context.fill(Path(roundedRect: pore, cornerRadius: 6), with: .color(CentralDogmaGameTheme.paper))
                    context.stroke(Path(roundedRect: pore, cornerRadius: 6), with: .color(CentralDogmaGameTheme.teal), lineWidth: 2)
                    var route = Path()
                    route.move(to: CGPoint(x: size.width * 0.37, y: 131))
                    route.addQuadCurve(to: CGPoint(x: size.width * 0.78, y: 133), control: CGPoint(x: size.width * 0.55, y: 168))
                    context.stroke(route, with: .color(CentralDogmaGameTheme.edge.opacity(0.4)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 5]))
                }
                Text("Nucleus").font(.system(.caption, design: .rounded, weight: .bold))
                    .position(x: w * 0.25, y: 45)
                CentralDogmaGameHelix(height: 46).frame(width: w * 0.3, height: 46)
                    .position(x: w * 0.24, y: 84)
                Text("DNA").font(.system(.caption2, design: .rounded, weight: .bold))
                    .position(x: w * 0.17, y: 115)
                Text("Cytoplasm").font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(CentralDogmaGameTheme.muted).position(x: w * 0.74, y: 36)
                CentralDogmaGameRibosome(large: preview || assembled || !outside)
                    .frame(width: w * 0.28, height: 64)
                    .opacity(outside ? 1 : 0.3)
                    .position(x: w * 0.76, y: 105)
                Text("Ribosome").font(.system(.caption2, design: .rounded, weight: .bold))
                    .position(x: w * 0.77, y: 178)
                if visibleRNA > 0 {
                    VStack(spacing: 1) {
                        CentralDogmaGameMessenger(sequence: String(rnaSequence.prefix(visibleRNA)))
                            .frame(width: w * 0.31, height: 24)
                        Text(outside ? "mRNA" : "RNA").font(.system(.caption2, design: .rounded, weight: .bold))
                    }
                    .position(x: w * (outside ? 0.72 : 0.31), y: outside ? 135 : 139)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.85), value: outside)
                    .transition(.opacity)
                }
                if aminoCount > 0 {
                    CentralDogmaGameBeads(count: aminoCount, compact: true)
                        .frame(width: w * 0.28, height: 25)
                        .rotationEffect(.degrees(-24))
                        .position(x: w * 0.79, y: 65)
                    Text("Amino acids").font(.system(.caption2, design: .rounded, weight: .bold))
                        .position(x: w * 0.76, y: 15)
                }
            }
            .foregroundStyle(CentralDogmaGameTheme.ink)
        }
        .frame(height: 192)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cell journey. DNA stays in the nucleus. \(outside ? "mRNA has left through a nuclear pore to the cytoplasm and ribosome." : visibleRNA > 0 ? "RNA is in the nucleus." : "The DNA gene is ready to copy.")")
        .accessibilityValue("\(outside ? "mRNA in cytoplasm" : "In nucleus"); \(aminoCount) amino acids")
        .accessibilityIdentifier("rna-relay-cell-journey")
    }
}

struct CentralDogmaGameMessenger: View {
    var sequence = "AUGAUGAUGUAA"
    var cap = false
    var tail = false
    var body: some View {
        Canvas { context, size in
            let bases = Array(sequence)
            let spacing = (size.width - 22) / CGFloat(max(1, bases.count - 1))
            var backbone = Path()
            for (i, base) in bases.enumerated() {
                let x = 11 + CGFloat(i) * spacing
                let y = size.height * 0.46 + sin(CGFloat(i) * 0.85) * size.height * 0.14
                if i == 0 { backbone.move(to: CGPoint(x: x, y: y)) } else { backbone.addLine(to: CGPoint(x: x, y: y)) }
                let rect = CGRect(x: x - min(6, spacing * 0.38), y: y + 2, width: min(12, spacing * 0.76), height: size.height * 0.33)
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(CentralDogmaGameTheme.nucleotide(String(base))))
                context.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(CentralDogmaGameTheme.edge), lineWidth: 0.8)
            }
            context.stroke(backbone, with: .color(CentralDogmaGameTheme.teal), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            if cap {
                let capRect = CGRect(x: 1, y: size.height * 0.32, width: 13, height: 13)
                context.fill(Path(ellipseIn: capRect), with: .color(CentralDogmaGameTheme.blue))
                context.stroke(Path(ellipseIn: capRect), with: .color(CentralDogmaGameTheme.teal), lineWidth: 2)
            }
            if tail {
                context.draw(Text("AAA").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(CentralDogmaGameTheme.ink),
                             at: CGPoint(x: size.width - 14, y: size.height * 0.85))
            }
        }.accessibilityHidden(true)
    }
}

struct CentralDogmaGameRibosome: View {
    var large = true
    var small = true
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            if large {
                var lobe = Path()
                lobe.move(to: CGPoint(x: w * 0.05, y: h * 0.61))
                lobe.addCurve(to: CGPoint(x: w * 0.95, y: h * 0.61), control1: CGPoint(x: w * 0.07, y: -h * 0.1), control2: CGPoint(x: w * 0.89, y: -h * 0.08))
                lobe.addQuadCurve(to: CGPoint(x: w * 0.05, y: h * 0.61), control: CGPoint(x: w * 0.5, y: h * 0.5))
                context.fill(lobe, with: .linearGradient(Gradient(colors: [CentralDogmaGameTheme.lavender, CentralDogmaGameTheme.color(0xB59AD3)]), startPoint: .zero, endPoint: CGPoint(x: w, y: h)))
                context.stroke(lobe, with: .color(CentralDogmaGameTheme.edge), lineWidth: 1.7)
                for x in [0.37, 0.64] {
                    context.fill(Path(ellipseIn: CGRect(x: w * x, y: h * 0.34, width: 3.5, height: 4.5)), with: .color(CentralDogmaGameTheme.ink))
                }
                var smile = Path()
                smile.move(to: CGPoint(x: w * 0.46, y: h * 0.43))
                smile.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.43), control: CGPoint(x: w * 0.52, y: h * 0.55))
                context.stroke(smile, with: .color(CentralDogmaGameTheme.ink), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                context.fill(Path(ellipseIn: CGRect(x: w * 0.28, y: h * 0.19, width: w * 0.18, height: h * 0.07)), with: .color(.white.opacity(0.4)))
            }
            if small {
                let lower = Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.67, width: w * 0.76, height: h * 0.27))
                context.fill(lower, with: .color(CentralDogmaGameTheme.sage))
                context.stroke(lower, with: .color(CentralDogmaGameTheme.edge), lineWidth: 1.7)
            }
        }.accessibilityHidden(true)
    }
}

struct CentralDogmaGameBeads: View {
    let count: Int
    var compact = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { i in
                if i > 0 { Rectangle().fill(CentralDogmaGameTheme.color(0xCE789B)).frame(width: compact ? 6 : 10, height: 4) }
                ZStack {
                    Circle().fill(CentralDogmaGameTheme.pink.gradient)
                    Circle().strokeBorder(CentralDogmaGameTheme.color(0xAE6584), lineWidth: 1.5)
                    if !compact { Text("Met").font(.system(.caption2, design: .rounded, weight: .bold)) }
                }
                .frame(width: compact ? 18 : 36, height: compact ? 18 : 36)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.7), value: count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) linked methionine amino acids")
    }
}

/// Tools resemble the molecules they act on; every tRNA uses the same art.
struct CentralDogmaGameToolArt: View {
    let payload: String
    var body: some View {
        Group {
            if payload == "tool:polymerase" {
                Image("CentralRNAWriter").resizable().scaledToFit()
            } else if payload.hasPrefix("trna:") {
                if payload == "trna:empty" {
                    transferRNA
                } else { Image("CentralTRNACourier").resizable().scaledToFit() }
            } else if payload.hasPrefix("ribosome:") {
                CentralDogmaGameRibosome(large: payload == "ribosome:large", small: payload == "ribosome:small")
                    .frame(width: 66, height: 40)
            } else if payload == "rna:mature" || payload == "tool:tail" {
                CentralDogmaGameMessenger(sequence: payload == "tool:tail" ? "AAAAAA" : "AUGAUG", cap: payload == "rna:mature", tail: true)
            } else if payload == "tool:cap" {
                ZStack { Circle().fill(CentralDogmaGameTheme.blue); Text("5′").font(.system(.headline, design: .rounded)) }.padding(7)
            } else if payload == "tool:splice" || payload == "protein:cleavage" {
                ZStack {
                    CentralDogmaGameMessenger(sequence: "AUGCGU").frame(height: 22)
                    Image(systemName: "scissors").font(.system(size: 31, weight: .medium)).rotationEffect(.degrees(-25))
                }
            } else if payload == "protein:chaperone" || payload.hasPrefix("subunit:") {
                CentralDogmaGameChain(foldProgress: 1).frame(width: 110).scaleEffect(0.32).frame(width: 50, height: 40)
            } else {
                ZStack {
                    Capsule().fill(CentralDogmaGameTheme.sage).frame(width: 45, height: 23).rotationEffect(.degrees(35))
                    Capsule().fill(CentralDogmaGameTheme.blue).frame(width: 45, height: 23).rotationEffect(.degrees(-35))
                    Circle().fill(CentralDogmaGameTheme.lavender).frame(width: 25, height: 25)
                }
            }
        }.foregroundStyle(CentralDogmaGameTheme.ink).accessibilityHidden(true)
    }
    private var transferRNA: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var stem = Path()
            stem.move(to: CGPoint(x: w * 0.5, y: h * 0.04))
            stem.addLine(to: CGPoint(x: w * 0.5, y: h * 0.38))
            stem.addCurve(to: CGPoint(x: w * 0.37, y: h * 0.6),
                          control1: CGPoint(x: w * 0.03, y: h * 0.03), control2: CGPoint(x: w * 0.03, y: h * 0.85))
            stem.addCurve(to: CGPoint(x: w * 0.63, y: h * 0.6),
                          control1: CGPoint(x: w * 0.28, y: h * 1.1), control2: CGPoint(x: w * 0.72, y: h * 1.1))
            stem.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.38),
                          control1: CGPoint(x: w * 0.97, y: h * 0.85), control2: CGPoint(x: w * 0.97, y: h * 0.03))
            context.stroke(stem, with: .color(CentralDogmaGameTheme.teal), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            context.stroke(stem, with: .color(CentralDogmaGameTheme.sage), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

struct CentralDogmaGameNucleotide: View {
    let base: String
    var filled = true
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Circle().fill(CentralDogmaGameTheme.teal).frame(width: 5, height: 5)
                UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 8, bottomTrailingRadius: 3, topTrailingRadius: 8)
                    .fill(CentralDogmaGameTheme.blue).frame(width: 14, height: 13)
            }
            Text(base).font(.system(size: 24, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(filled ? CentralDogmaGameTheme.nucleotide(base) : CentralDogmaGameTheme.paper, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(CentralDogmaGameTheme.edge.opacity(0.5), lineWidth: 1))
        }.accessibilityElement(children: .ignore).accessibilityLabel(base)
    }
}
