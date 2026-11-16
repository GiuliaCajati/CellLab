import SwiftUI

struct CentralDogmaGameArt: View {
    let name: String
    var height: CGFloat = 100
    var body: some View {
        Image(name).resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: height)
            .padding(8).accessibilityHidden(true)
    }
}

@MainActor struct CentralDogmaGameTarget: View {
    @Bindable var session: CentralDogmaGameSession
    let step: CentralDogmaGameStep
    let target: String
    let title: String
    var detail = ""
    var automatic: String? = nil
    var solved = false
    var tint: Color = CentralDogmaGameTheme.sage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var active: Bool {
        !solved && (automatic == nil || automatic == step.payload) &&
            (step.target == target || (step.target == "hemoglobin:*" && target.hasPrefix("hemoglobin:")))
    }
    var body: some View {
        Button {
            if let payload = automatic ?? session.selectedPayload ?? step.autoPayload {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85)) { () -> Void in
                    _ = session.submit(payload, target: target, stepID: step.id)
                }
            } else { session.showHint() }
        } label: {
            VStack(spacing: 5) {
                Text(solved ? "✓ " + title : title).font(.system(.subheadline, design: .rounded, weight: .bold))
                if !detail.isEmpty { Text(detail).font(.system(.caption2, design: .rounded)).foregroundStyle(CentralDogmaGameTheme.muted) }
            }
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 7).padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(active ? tint : CentralDogmaGameTheme.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(active ? CentralDogmaGameTheme.teal : CentralDogmaGameTheme.edge.opacity(0.25), style: StrokeStyle(lineWidth: active ? 2 : 1, dash: active ? [5, 3] : [])))
        }
        .buttonStyle(.plain).disabled(solved || session.pending != nil)
        .dropDestination(for: String.self) { values, _ in
            guard !solved, let payload = values.first else { return false }
            return withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85)) { () -> Bool in
                session.submit(payload, target: target, stepID: step.id)
            }
        }
        .accessibilityLabel(title + (active ? ". Current target" : ""))
        .accessibilityHint("Tap after choosing a tool, or drop a tool here.")
    }
}

@MainActor struct CentralDogmaGameToolbox: View {
    @Bindable var session: CentralDogmaGameSession
    let step: CentralDogmaGameStep
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var float = false

    private var options: [CentralDogmaGameOption] { step.options.filter { !session.usedPieces.contains($0.payload) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !options.isEmpty {
                Text(step.kind == "rna" ? "RNA nucleotides" : "Your toolkit")
                    .font(.system(.caption, design: .rounded, weight: .semibold)).foregroundStyle(CentralDogmaGameTheme.muted)
                if step.kind == "rna" {
                    HStack(spacing: 8) {
                        ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                            tool(option)
                                .offset(y: reduceMotion ? 0 : (float ? (index.isMultiple(of: 2) ? -4 : 4) : 0))
                                .animation(reduceMotion ? nil : .easeInOut(duration: 1.5 + Double(index) * 0.15).repeatForever(autoreverses: true), value: float)
                        }
                    }
                    .padding(.vertical, 5).onAppear { float = true }
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(options) { option in tool(option) }
                    }
                }
                Text("Drag, or tap a tool then a highlighted target.")
                    .font(.system(.caption2, design: .rounded)).foregroundStyle(CentralDogmaGameTheme.muted)
            }
        }
    }
    private func tool(_ option: CentralDogmaGameOption) -> some View {
        let selected = session.selectedPayload == option.payload
        let isBase = option.payload.hasPrefix("rna:") && option.label.count == 1
        return Button { session.choose(option.payload) } label: {
            VStack(spacing: 6) {
                if isBase {
                    Text(option.label).font(.system(size: 28, weight: .bold, design: .rounded)).frame(minHeight: 48)
                } else if let asset = option.asset {
                    Image(asset).resizable().scaledToFit().frame(height: 58).padding(3).accessibilityHidden(true)
                } else {
                    Image(systemName: option.symbol).font(.system(size: 26)).frame(height: 45).accessibilityHidden(true)
                }
                if !isBase {
                    Text(option.label).font(.system(.subheadline, design: .rounded, weight: .bold))
                    Text(option.detail).font(.system(.caption2, design: .rounded)).foregroundStyle(CentralDogmaGameTheme.muted)
                }
            }
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            .padding(10).frame(maxWidth: .infinity, minHeight: 66)
            .background(isBase ? CentralDogmaGameTheme.nucleotide(option.label) : CentralDogmaGameTheme.paper, in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(selected ? CentralDogmaGameTheme.teal : CentralDogmaGameTheme.edge.opacity(0.22), lineWidth: selected ? 3 : 1))
        }
        .buttonStyle(.plain).draggable(option.payload)
        .accessibilityLabel(option.label + ". " + option.detail)
        .accessibilityValue(selected ? "Selected" : "")
    }
}

struct CentralDogmaGameHelix: View {
    var open = false
    var body: some View {
        Canvas { context, size in
            var a = Path(), b = Path()
            for i in 0...70 {
                let x = 12 + (size.width - 24) * CGFloat(i) / 70
                let wave = open ? CGFloat(22) : sin(CGFloat(i) / 70 * .pi * 3) * 22
                let p = CGPoint(x: x, y: size.height / 2 + wave)
                let q = CGPoint(x: x, y: size.height / 2 - wave)
                if i == 0 { a.move(to: p); b.move(to: q) } else { a.addLine(to: p); b.addLine(to: q) }
                if i.isMultiple(of: 5) && !open {
                    var line = Path(); line.move(to: p); line.addLine(to: q)
                    context.stroke(line, with: .color(CentralDogmaGameTheme.edge.opacity(0.5)), lineWidth: 2)
                }
            }
            context.stroke(a, with: .color(CentralDogmaGameTheme.teal), lineWidth: 3)
            context.stroke(b, with: .color(CentralDogmaGameTheme.color(0x6589A4)), lineWidth: 3)
        }
        .frame(height: 82).accessibilityHidden(true)
    }
}

struct CentralDogmaGameChain: View, Animatable {
    var foldProgress: CGFloat = 0

    var animatableData: CGFloat {
        get { foldProgress }
        set { foldProgress = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let positions = chainPoints(in: size)
            var backbone = Path()
            backbone.addLines(positions)
            let bondColor = CentralDogmaGameTheme.color(0xCF7595)
            context.stroke(backbone, with: .color(bondColor), lineWidth: 5)

            for point in positions {
                let rect = CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12)
                let bead = Path(ellipseIn: rect)
                context.fill(bead, with: .color(CentralDogmaGameTheme.pink))
                context.stroke(bead, with: .color(CentralDogmaGameTheme.edge), lineWidth: 1)
            }
        }
        .frame(height: 125)
        .accessibilityLabel(spokenDescription)
    }

    private var spokenDescription: String {
        foldProgress > 0.9
            ? "Schematic folded full-length protein"
            : "Schematic full-length polypeptide, separate from the practice fragment"
    }

    private func chainPoints(in size: CGSize) -> [CGPoint] {
        let progress: CGFloat = min(max(foldProgress, 0), 1)
        let centerX: CGFloat = size.width / 2
        let centerY: CGFloat = size.height / 2
        let span: CGFloat = size.width - 36
        var points: [CGPoint] = []
        points.reserveCapacity(24)

        for index in 0..<24 {
            let t: CGFloat = CGFloat(index) / 23
            let waveAngle: CGFloat = t * CGFloat.pi * 4
            let foldAngle: CGFloat = t * CGFloat.pi * 4.5
            let straightX: CGFloat = 18 + t * span
            let straightY: CGFloat = centerY + sin(waveAngle) * 30
            let foldedX: CGFloat = centerX + cos(foldAngle) * 48
            let foldedY: CGFloat = centerY + sin(foldAngle) * 40
            let x: CGFloat = straightX + (foldedX - straightX) * progress
            let y: CGFloat = straightY + (foldedY - straightY) * progress
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
}

struct CentralDogmaGameCheckpointArt: View {
    let badge: String
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Group {
            if badge == "Folding friend" {
                CentralDogmaGameChain(foldProgress: animate ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.1), value: animate)
            } else if badge == "Codon captain" {
                VStack(spacing: 8) {
                    HStack { ForEach(0..<3, id: \.self) { _ in Text("Met").font(.caption.bold()).padding(10).background(CentralDogmaGameTheme.pink, in: Circle()) } }
                        .offset(y: animate && !reduceMotion ? -7 : 0)
                    HStack(spacing: 16) {
                        Capsule().fill(CentralDogmaGameTheme.lavender).frame(width: 82, height: 30).offset(x: animate ? -16 : 0)
                        Capsule().fill(CentralDogmaGameTheme.sage).frame(width: 72, height: 22).offset(x: animate ? 16 : 0)
                    }
                }.padding(.vertical, 16).animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: animate)
            } else if badge == "Gene expression champion" {
                Image(systemName: "trophy.fill").font(.system(size: 55)).foregroundStyle(CentralDogmaGameTheme.teal).padding(12)
            } else {
                Image(systemName: badge == "Message editor" ? "envelope.badge.fill" : "sparkles")
                    .font(.system(size: 42)).foregroundStyle(CentralDogmaGameTheme.teal).padding(12)
            }
        }.onAppear { animate = true }.accessibilityHidden(true)
    }
}




