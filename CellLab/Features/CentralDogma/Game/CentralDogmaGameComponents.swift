import SwiftUI

struct CentralDogmaGameArt: View {
    let name: String
    var height: CGFloat = 100
    var body: some View {
        Image(name).resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: height)
            .padding(8).accessibilityHidden(true)
    }
}

/// A real molecule or docking site is the hit area, rather than a separate answer card.
@MainActor struct CentralDogmaGameTarget<Artwork: View>: View {
    @Bindable var session: CentralDogmaGameSession
    let step: CentralDogmaGameStep
    let target: String
    let title: String
    var automatic: String? = nil
    var solved = false
    @ViewBuilder var artwork: () -> Artwork
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var active: Bool {
        !solved && (automatic == nil || automatic == step.payload) &&
            (step.target == target || (step.target == "hemoglobin:*" && target.hasPrefix("hemoglobin:")))
    }
    var body: some View {
        Button {
            if let payload = automatic ?? session.selectedPayload ?? step.autoPayload {
                withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                    _ = session.submit(payload, target: target, stepID: step.id)
                }
            } else { session.showHint() }
        } label: {
            artwork()
                .padding(5)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(active ? CentralDogmaGameTheme.teal.opacity(0.08) : .clear,
                            in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    if active {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(CentralDogmaGameTheme.teal, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    }
                }
                .shadow(color: active ? CentralDogmaGameTheme.teal.opacity(0.15) : .clear, radius: 5)
                .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain).disabled(solved || session.pending != nil)
        .dropDestination(for: String.self) { values, _ in
            guard !solved, let payload = values.first else { return false }
            return withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                session.submit(payload, target: target, stepID: step.id)
            }
        }
        .accessibilityLabel(title + (active ? ". Current target" : ""))
        .accessibilityHint(automatic == nil ? "Choose a molecule, then tap here, or drag it here." : "Tap to perform this action.")
        .accessibilityValue(solved ? "Complete" : active ? "Current target" : "")
        .accessibilityIdentifier("rna-target-\(step.id)-\(target)-\(automatic ?? "drop")")
    }
}

@MainActor struct CentralDogmaGameToolbox: View {
    @Bindable var session: CentralDogmaGameSession
    let step: CentralDogmaGameStep
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var options: [CentralDogmaGameOption] { step.options.filter { !session.usedPieces.contains($0.payload) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if !options.isEmpty {
                Text(step.kind == "rna" ? "Tap the matching RNA base" : session.selectedPayload == nil ? "Pick a molecule → tap the glow" : "Now tap the glow")
                    .font(.system(.caption, design: .rounded, weight: .semibold)).foregroundStyle(CentralDogmaGameTheme.muted)
                HStack(alignment: .top, spacing: 7) {
                    ForEach(options) { option in tool(option) }
                }
            }
        }
    }
    private func tool(_ option: CentralDogmaGameOption) -> some View {
        let selected = session.selectedPayload == option.payload
        let isBase = option.payload.hasPrefix("rna:") && option.label.count == 1
        return Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
                session.choose(option.payload, stepID: step.id)
            }
        } label: {
            VStack(spacing: 6) {
                if isBase {
                    Text(option.label).font(.system(size: 28, weight: .bold, design: .rounded)).frame(minHeight: 48)
                } else {
                    CentralDogmaGameToolArt(payload: option.payload).frame(height: 40).padding(.horizontal, 4)
                }
                if !isBase {
                    Text(option.label).font(.system(.caption, design: .rounded, weight: .bold))
                }
            }
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            .padding(7).frame(maxWidth: .infinity, minHeight: 60)
            .background(isBase ? CentralDogmaGameTheme.nucleotide(option.label) : CentralDogmaGameTheme.paper, in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(selected ? CentralDogmaGameTheme.teal : CentralDogmaGameTheme.edge.opacity(0.22), lineWidth: selected ? 3 : 1))
        }
        .buttonStyle(.plain).draggable(option.payload)
        .accessibilityLabel(option.label + ". " + option.detail)
        .accessibilityValue(selected ? "Selected" : "")
        .accessibilityIdentifier("rna-tool-\(option.payload)")
    }
}

struct CentralDogmaGameHelix: View {
    var open = false
    var height: CGFloat = 82
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
        .frame(height: height).accessibilityHidden(true)
    }
}

struct CentralDogmaGameChain: View, Animatable {
    var foldProgress: CGFloat = 0
    var height: CGFloat = 125

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
        .frame(height: height)
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




