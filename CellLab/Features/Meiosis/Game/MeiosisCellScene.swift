import SwiftUI

/// Drawing, hit targets and spindle endpoints share these normalized coordinates.
nonisolated enum MeiosisLayout {
    static let rows: [CGFloat] = [0.35, 0.65]
    static func center(_ cell: Int) -> CGFloat { cell == 0 ? 0.27 : 0.73 }
    static func looseHomolog(_ id: Int) -> UnitPoint {
        UnitPoint(x: id % 2 == 0 ? 0.32 : 0.68, y: rows[id / 2])
    }
    static func paired(_ pair: Int) -> UnitPoint {
        UnitPoint(x: pair == 0 ? 0.37 : 0.63, y: rows[pair])
    }
    static func chromosomeII(_ key: Int, aligned: Bool) -> UnitPoint {
        let cell = key / 2, pair = key % 2
        return UnitPoint(x: center(cell) + (pair == 0 ? -0.085 : 0.085),
                         y: aligned ? 0.5 : (pair == 0 ? 0.40 : 0.60))
    }
    static func product(_ product: Int) -> UnitPoint {
        UnitPoint(x: center(product / 2), y: product % 2 == 0 ? 0.28 : 0.72)
    }
}

struct MeiosisCellScene: View {
    let session: MeiosisSession
    let onAction: (MeiosisSession.Action) -> Void
    var showsParts = false
    @State private var dragged: [Int: CGPoint] = [:]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MeiosisCellDrawing(session: session, motion: MeiosisMotion(session),
                                   dragged: dragged, showsParts: showsParts)
                    .accessibilityHidden(true)
                targets(in: geometry.size)
            }
            .coordinateSpace(name: "meiosisCell")
        }
        .aspectRatio(1.05, contentMode: .fit)
        .onChange(of: session.stage) { _, _ in dragged.removeAll() }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private func targets(in size: CGSize) -> some View {
        switch session.stage {
        case .prophaseI:
            if session.condensedI.count < 4 {
                ForEach(MeiosisSession.chromosomeIDs, id: \.self) { id in
                    if !session.condensedI.contains(id) {
                        target("Condense chromosome \(id + 1)", at: MeiosisLayout.looseHomolog(id), in: size) {
                            onAction(.condenseI(id))
                        }
                    }
                }
            } else if !session.envelopeOpenI {
                sceneButton("Open envelope", at: UnitPoint(x: 0.5, y: 0.12), in: size) { onAction(.openEnvelopeI) }
            } else if session.synapsed.count < 2 {
                ForEach(MeiosisSession.pairIDs, id: \.self) { pair in
                    if !session.synapsed.contains(pair) {
                        let id = pair * 2 + 1
                        let origin = MeiosisLayout.looseHomolog(id)
                        let at = dragged[id].map { UnitPoint(x: $0.x / size.width, y: $0.y / size.height) } ?? origin
                        target("Pair homologs \(pair + 1)", at: at, in: size,
                               onDrag: { dragged[id] = $0 }, onDrop: { drop in
                            dragged[id] = nil
                            let match = MeiosisLayout.looseHomolog(pair * 2)
                            onAction(.synapse(pair, matched: abs(drop.x / size.width - match.x) < 0.13 &&
                                              abs(drop.y / size.height - match.y) < 0.12))
                        }) { onAction(.synapse(pair, matched: true)) }
                    }
                }
            } else {
                ForEach(MeiosisSession.pairIDs, id: \.self) { pair in
                    if !session.crossed.contains(pair) {
                        let point = MeiosisLayout.paired(pair)
                        target("Cross over matching non-sister segments in pair \(pair + 1)",
                               at: UnitPoint(x: point.x, y: point.y + 0.07), in: size) {
                            onAction(.crossOver(pair, matched: true))
                        }
                    }
                }
            }
        case .metaphaseI:
            if !session.attachmentsIComplete {
                ForEach(MeiosisSession.chromosomeIDs, id: \.self) { id in
                    let attached = session.leftAttachments.contains(id) || session.rightAttachments.contains(id)
                    if !attached {
                        target("Connect \(id % 2 == 0 ? "maternal" : "paternal") homolog of pair \(id / 2 + 1) to \(session.poleForHomolog(id).rawValue.lowercased()) pole",
                               at: homologPoint(id), in: size, diameter: 44) { onAction(.attachI(id)) }
                    }
                }
            } else {
                ForEach(MeiosisSession.pairIDs, id: \.self) { pair in
                    if !session.alignedI.contains(pair) {
                        let at = dragged[10 + pair].map { UnitPoint(x: $0.x / size.width, y: $0.y / size.height) }
                            ?? MeiosisLayout.paired(pair)
                        target("Align pair \(pair + 1)", at: at, in: size, diameter: 60,
                               onDrag: { dragged[10 + pair] = $0 }, onDrop: { drop in
                            dragged[10 + pair] = nil
                            onAction(.alignI(pair, nearEquator: abs(drop.x / size.width - 0.5) < 0.12 &&
                                             abs(drop.y / size.height - MeiosisLayout.rows[pair]) < 0.16))
                        }) { onAction(.alignI(pair, nearEquator: true)) }
                    }
                }
            }
        case .telophaseI:
            ForEach(0..<2, id: \.self) { cell in
                if !session.nucleiI.contains(cell) {
                    target("Rebuild nucleus \(cell + 1)", at: UnitPoint(x: MeiosisLayout.center(cell), y: 0.5),
                           in: size, diameter: 72) { onAction(.rebuildI(cell)) }
                }
            }
        case .prophaseII:
            if session.condensedII.count < 4 {
                ForEach(0..<4, id: \.self) { key in
                    if !session.condensedII.contains(key) {
                        target("Condense chromosome \(key % 2 + 1) in cell \(key / 2 + 1)",
                               at: MeiosisLayout.chromosomeII(key, aligned: false), in: size, diameter: 44) {
                            onAction(.condenseII(key))
                        }
                    }
                }
            } else {
                ForEach(0..<2, id: \.self) { cell in
                    if !session.envelopesOpenII.contains(cell) {
                        sceneButton("Open", at: UnitPoint(x: MeiosisLayout.center(cell), y: 0.18), in: size) {
                            onAction(.openEnvelopeII(cell))
                        }
                        .accessibilityLabel("Open nuclear envelope in cell \(cell + 1)")
                    }
                }
            }
        case .metaphaseII:
            ForEach(0..<4, id: \.self) { key in
                let attached = (session.selectedPole == .top ? session.topAttachments : session.bottomAttachments).contains(key)
                if !session.attachmentsIIComplete && !attached {
                    target("Connect chromosome \(key % 2 + 1) in cell \(key / 2 + 1) to \(session.selectedPole.rawValue.lowercased()) pole",
                           at: MeiosisLayout.chromosomeII(key, aligned: session.alignedII.contains(key)), in: size, diameter: 44) {
                        onAction(.attachII(key))
                    }
                } else if session.attachmentsIIComplete && !session.alignedII.contains(key) {
                    let at = dragged[20 + key].map { UnitPoint(x: $0.x / size.width, y: $0.y / size.height) }
                        ?? MeiosisLayout.chromosomeII(key, aligned: false)
                    target("Align chromosome \(key % 2 + 1) in cell \(key / 2 + 1)", at: at, in: size, diameter: 44,
                           onDrag: { dragged[20 + key] = $0 }, onDrop: { drop in
                        dragged[20 + key] = nil
                        let center = MeiosisLayout.center(key / 2)
                        onAction(.alignII(key, nearEquator: abs(drop.y / size.height - 0.5) < 0.10 &&
                                          abs(drop.x / size.width - center) < 0.17))
                    }) { onAction(.alignII(key, nearEquator: true)) }
                }
            }
        case .telophaseII:
            ForEach(0..<4, id: \.self) { product in
                if !session.nucleiII.contains(product) {
                    target("Rebuild haploid nucleus \(product + 1)", at: MeiosisLayout.product(product),
                           in: size, diameter: 60) { onAction(.rebuildII(product)) }
                }
            }
        default: EmptyView()
        }
    }

    private func homologPoint(_ id: Int) -> UnitPoint {
        let pair = id / 2
        let center = session.alignedI.contains(pair) ? CGFloat(0.5) : MeiosisLayout.paired(pair).x
        return UnitPoint(x: center + (session.poleForHomolog(id) == .left ? -0.065 : 0.065), y: MeiosisLayout.rows[pair])
    }
    private func sceneButton(_ title: String, at point: UnitPoint, in size: CGSize,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(.caption, design: .rounded, weight: .bold))
                .padding(.horizontal, 12).frame(minHeight: 44)
                .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .position(x: size.width * point.x, y: size.height * point.y)
    }
    private func target(_ label: String, at point: UnitPoint, in size: CGSize, diameter: CGFloat = 48,
                        onDrag: ((CGPoint) -> Void)? = nil, onDrop: ((CGPoint) -> Void)? = nil,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle().fill(.white.opacity(0.001))
                .overlay(Circle().stroke(.white.opacity(0.95), style: StrokeStyle(lineWidth: 2, dash: [3, 4])))
                .frame(width: diameter, height: diameter).contentShape(Circle())
        }
        .buttonStyle(.plain).accessibilityLabel(label)
        .accessibilityHint(onDrag == nil ? "Double-tap to act" : "Drag, or double-tap to place automatically")
        .simultaneousGesture(DragGesture(minimumDistance: 8, coordinateSpace: .named("meiosisCell"))
            .onChanged { point in
                onDrag?(CGPoint(x: min(max(point.location.x, 16), size.width - 16),
                                y: min(max(point.location.y, 16), size.height - 16)))
            }
            .onEnded { onDrop?($0.location) }, including: onDrag == nil ? .none : .all)
        .position(x: size.width * point.x, y: size.height * point.y)
    }
}

/// 49 independently interpolated values: no scene change relies on a static screenshot.
nonisolated struct MeiosisMotion: VectorArithmetic {
    var values: [Double]
    static var zero: Self { Self(values: Array(repeating: 0, count: 49)) }
    init(values: [Double]) { self.values = values }
    init(_ s: MeiosisSession) {
        values = [s.replicated ? 1 : 0, s.divisionPrepared ? 1 : 0]
        values += (0..<4).map { s.condensedI.contains($0) ? 1 : 0 }
        values += [s.envelopeOpenI ? 1 : 0]
        values += (0..<2).map { s.synapsed.contains($0) ? 1 : 0 }
        values += (0..<2).map { s.crossed.contains($0) ? 1 : 0 }
        values += (0..<2).map { s.alignedI.contains($0) ? 1 : 0 }
        values += [s.separatedI ? 1 : 0]
        values += (0..<2).map { s.nucleiI.contains($0) ? 1 : 0 }
        values += [s.dividedI ? 1 : 0]
        values += (0..<4).map { s.condensedII.contains($0) ? 1 : 0 }
        values += (0..<2).map { s.envelopesOpenII.contains($0) ? 1 : 0 }
        values += (0..<4).map { s.alignedII.contains($0) ? 1 : 0 }
        values += [s.centromeresSplit ? 1 : 0, s.separatedII ? 1 : 0]
        values += (0..<4).map { s.nucleiII.contains($0) ? 1 : 0 }
        values += [s.relaxedII ? 1 : 0, s.dividedII ? 1 : 0]
        values += s.maternalLeft.map { $0 ? 1 : 0 }
        values += (0..<4).map { s.leftAttachments.contains($0) || s.rightAttachments.contains($0) ? 1 : 0 }
        values += (0..<4).map { s.topAttachments.contains($0) ? 1 : 0 }
        values += (0..<4).map { s.bottomAttachments.contains($0) ? 1 : 0 }
    }
    static func + (a: Self, b: Self) -> Self { Self(values: zip(a.values, b.values).map { $0.0 + $0.1 }) }
    static func - (a: Self, b: Self) -> Self { Self(values: zip(a.values, b.values).map { $0.0 - $0.1 }) }
    mutating func scale(by rhs: Double) { values = values.map { $0 * rhs } }
    var magnitudeSquared: Double { values.reduce(0) { $0 + $1 * $1 } }
}

private nonisolated struct MeiosisCellDrawing: View, Animatable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let session: MeiosisSession
    var motion: MeiosisMotion
    let dragged: [Int: CGPoint]
    let showsParts: Bool
    var animatableData: MeiosisMotion {
        get { motion }
        set { motion = newValue }
    }
    @MainActor var body: some View {
        if reduceMotion { canvas(time: 0) }
        else {
            TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { frame in
                canvas(time: frame.date.timeIntervalSinceReferenceDate)
            }
        }
    }
    @MainActor private func canvas(time: Double) -> some View {
        Canvas { context, size in
            MeiosisPainter(context: context, size: size, session: session, motion: motion,
                           dragged: dragged, showsParts: showsParts, time: time).draw()
        }
    }
}

private struct MeiosisPainter {
    let context: GraphicsContext
    let size: CGSize
    let session: MeiosisSession
    let motion: MeiosisMotion
    let dragged: [Int: CGPoint]
    let showsParts: Bool
    let time: Double
    private let ink = Color(red: 0.12, green: 0.23, blue: 0.25)
    private let teal = Color(red: 0.09, green: 0.49, blue: 0.43)
    private let purple = Color(red: 0.44, green: 0.27, blue: 0.76)
    private var colors: [Color] { [purple, Color(red: 0.80, green: 0.32, blue: 0.53),
                                  Color(red: 0.14, green: 0.56, blue: 0.74), Color(red: 0.72, green: 0.49, blue: 0.13)] }
    private var names: [String] { ["Purple", "Pink", "Blue", "Gold"] }
    private var scale: CGFloat { size.width / 360 }
    private var later: Bool { session.stage.rawValue >= MeiosisSession.Stage.interkinesis.rawValue }
    private func m(_ i: Int) -> CGFloat { CGFloat(motion.values[i]) }
    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * size.width, y: y * size.height) }
    private func mix(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
    private var sway: CGFloat { time == 0 ? 0 : CGFloat(sin(time * 1.7)) }

    func draw() {
        membranes()
        nuclei()
        equators()
        spindles()
        chromosomes()
        centrosomes()
        if session.stage == .prophaseI { chiasmata() }
        if showsParts { labels() }
        text(modelCaption, at: p(0.5, 0.037), font: 10, color: ink)
        if session.stage == .complete { productLabels() }
    }

    private var modelCaption: String {
        if session.dividedII { return "4 HAPLOID CELLS · n = 2" }
        if session.stage == .anaphaseII || session.stage == .telophaseII { return "TWO CELLS · SISTERS SEPARATING" }
        if session.dividedI { return "2 HAPLOID CELLS · n = 2" }
        return "ILLUSTRATED DIPLOID CELL · 2n = 4"
    }
    private func membranes() {
        if m(16) < 0.999 {
            membrane(rect: CGRect(x: size.width * 0.045, y: size.height * 0.09,
                                  width: size.width * 0.91, height: size.height * 0.82),
                     pinch: m(16), horizontal: true)
        } else {
            for cell in 0..<2 {
                membrane(rect: CGRect(x: size.width * (MeiosisLayout.center(cell) - 0.205), y: size.height * 0.10,
                                      width: size.width * 0.41, height: size.height * 0.80),
                         pinch: m(34), horizontal: false)
            }
        }
    }
    /// A real furrow closes, then two separate cell shells replace the constricted outline.
    private func membrane(rect: CGRect, pinch: CGFloat, horizontal: Bool) {
        if pinch < 0.001 {
            context.draw(context.resolve(Image("CellLabCellShell")), in: rect.insetBy(dx: -rect.width / 28, dy: -rect.height / 28))
            return
        }
        if pinch > 0.999 {
            let gap: CGFloat = 0.015 * size.width
            let first: CGRect, second: CGRect
            if horizontal {
                first = CGRect(x: rect.minX, y: rect.minY, width: rect.width / 2 - gap, height: rect.height)
                second = first.offsetBy(dx: rect.width / 2 + gap, dy: 0)
            } else {
                first = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 2 - gap)
                second = first.offsetBy(dx: 0, dy: rect.height / 2 + gap)
            }
            for r in [first, second] {
                context.draw(context.resolve(Image("CellLabCellShell")), in: r.insetBy(dx: -r.width / 28, dy: -r.height / 28))
            }
            return
        }
        var local = context
        local.translateBy(x: rect.midX, y: rect.midY)
        if !horizontal { local.rotate(by: .degrees(90)) }
        let w = horizontal ? rect.width : rect.height
        let h = horizontal ? rect.height : rect.width
        let neck = h * 0.5 * (1 - pinch)
        var path = Path()
        path.move(to: CGPoint(x: -w / 2, y: 0))
        path.addCurve(to: CGPoint(x: 0, y: -neck), control1: CGPoint(x: -w / 2, y: -h * 0.67), control2: CGPoint(x: -w * 0.17, y: -h * 0.58))
        path.addCurve(to: CGPoint(x: w / 2, y: 0), control1: CGPoint(x: w * 0.17, y: -h * 0.58), control2: CGPoint(x: w / 2, y: -h * 0.67))
        path.addCurve(to: CGPoint(x: 0, y: neck), control1: CGPoint(x: w / 2, y: h * 0.67), control2: CGPoint(x: w * 0.17, y: h * 0.58))
        path.addCurve(to: CGPoint(x: -w / 2, y: 0), control1: CGPoint(x: -w * 0.17, y: h * 0.58), control2: CGPoint(x: -w / 2, y: h * 0.67))
        path.closeSubpath()
        local.fill(path, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.83, blue: 0.81), Color(red: 0.87, green: 0.57, blue: 0.66)]),
                                               startPoint: CGPoint(x: -w / 2, y: -h / 2), endPoint: CGPoint(x: w / 2, y: h / 2)))
        local.stroke(path, with: .color(teal.opacity(0.85)), lineWidth: 2 * scale)
        local.stroke(path, with: .color(.white.opacity(0.6)), lineWidth: 0.7 * scale)
    }

    private func nuclei() {
        if session.stage.rawValue <= MeiosisSession.Stage.prophaseI.rawValue {
            nucleus(at: p(0.5, 0.5), width: 0.70, height: 0.72, alpha: 1 - m(6))
        }
        for cell in 0..<2 {
            let envelope = m(14 + cell) * (1 - m(21 + cell))
            let height = mix(0.60, 0.62, m(16))
            nucleus(at: p(MeiosisLayout.center(cell), 0.5), width: 0.32, height: height, alpha: envelope)
        }
        for product in 0..<4 {
            let at = MeiosisLayout.product(product)
            nucleus(at: p(at.x, at.y), width: 0.29, height: 0.27, alpha: m(29 + product))
        }
    }
    private func nucleus(at center: CGPoint, width: CGFloat, height: CGFloat, alpha: CGFloat) {
        guard alpha > 0.001 else { return }
        var local = context; local.opacity = Double(alpha) * 0.92
        local.draw(context.resolve(Image("CellLabPhaseNucleus")),
                   in: CGRect(x: center.x - size.width * width / 2, y: center.y - size.height * height / 2,
                              width: size.width * width, height: size.height * height))
    }
    private func equators() {
        if session.stage == .metaphaseI {
            line([p(0.5, 0.17), p(0.5, 0.83)], color: teal.opacity(0.65), width: 1.4, dash: [3, 5])
        } else if session.stage == .metaphaseII {
            for cell in 0..<2 {
                let x = MeiosisLayout.center(cell)
                line([p(x - 0.16, 0.5), p(x + 0.16, 0.5)], color: teal.opacity(0.65), width: 1.4, dash: [3, 5])
            }
        }
    }

    private func homolog(_ id: Int) -> CGPoint {
        let pair = id / 2, maternal = id % 2 == 0
        let loose = MeiosisLayout.looseHomolog(id), pairPoint = MeiosisLayout.paired(pair)
        let orientation = m(35 + pair)
        let leftness = maternal ? orientation : 1 - orientation
        let pairedX = pairPoint.x + (maternal ? -0.065 : 0.065)
        let syn = m(7 + pair)
        var x = mix(loose.x, pairedX, syn)
        let align = m(11 + pair)
        if session.stage.rawValue >= MeiosisSession.Stage.metaphaseI.rawValue {
            x = mix(pairPoint.x + mix(0.065, -0.065, leftness), 0.5 + mix(0.065, -0.065, leftness), align)
        }
        var y = loose.y
        if let drag = dragged[id], session.stage == .prophaseI { return drag }
        if let drag = dragged[10 + pair], session.stage == .metaphaseI {
            return CGPoint(x: drag.x + mix(0.065, -0.065, leftness) * size.width, y: drag.y)
        }
        x = mix(x, mix(0.73, 0.27, leftness), m(13))
        let cell = session.poleForHomolog(id) == .left ? 0 : 1
        let after = MeiosisLayout.chromosomeII(cell * 2 + pair, aligned: false)
        x = mix(x, after.x, m(16)); y = mix(y, after.y, m(16))
        return p(x, y)
    }
    private func chromosomeII(_ key: Int, sister: Int) -> CGPoint {
        let at = MeiosisLayout.chromosomeII(key, aligned: false)
        let aligned = m(23 + key)
        var point = p(at.x, mix(at.y, 0.5, aligned))
        if session.stage == .metaphaseII, let drag = dragged[20 + key] { point = drag }
        point.y = mix(point.y, size.height * (sister == 0 ? 0.28 : 0.72), m(28))
        return point
    }
    private func chromosomes() {
        if !later {
            for id in 0..<4 {
                let at = homolog(id), packed = m(2 + id)
                let loosened = m(14 + (session.poleForHomolog(id) == .left ? 0 : 1))
                let compact = packed * (1 - loosened)
                for sister in 0..<2 {
                    let visible = sister == 0 ? CGFloat(1) : m(0)
                    ribbon(id: id, sister: sister, at: at, compact: compact,
                           visibility: visible, angle: 0, single: false)
                }
                if compact > 0.4 { identity(id, at: at, compact: compact) }
            }
        } else {
            for key in 0..<4 {
                let id = session.homolog(in: key / 2, pair: key % 2)
                let packed = m(17 + key) * (1 - m(33))
                for sister in 0..<2 {
                    ribbon(id: id, sister: sister, at: chromosomeII(key, sister: sister),
                           compact: packed, visibility: 1, angle: 90 * m(17 + key), single: true)
                }
                if session.stage == .metaphaseII || session.stage == .anaphaseII {
                    let c = chromosomeII(key, sister: 0)
                    line([CGPoint(x: c.x, y: c.y - 4 * scale), CGPoint(x: c.x, y: c.y + 4 * scale)],
                         color: Color.yellow.opacity(Double((1 - m(27)) * (1 - m(28)))), width: 3)
                }
            }
        }
    }

    private func ribbon(id: Int, sister: Int, at center: CGPoint, compact: CGFloat,
                        visibility: CGFloat, angle: CGFloat, single: Bool) {
        let extent: CGFloat = (id / 2 == 0 ? 62 : 48) * scale
        let exchanged = (id % 2 == 0 && sister == 1) || (id % 2 == 1 && sister == 0)
        let exchange = exchanged ? m(9 + id / 2) : 0
        let donor = id % 2 == 0 ? id + 1 : id - 1
        let split = single ? m(28) : 0
        let rect = CGRect(x: -extent / 2, y: -extent / 2, width: extent, height: extent)
        if compact > 0.001 {
            var local = context
            local.translateBy(x: center.x, y: center.y)
            local.rotate(by: .degrees(Double(angle + sway * (later ? 1 : 2))))
            local.opacity = Double(compact * visibility * (1 - split))
            local.clip(to: Path(CGRect(x: sister == 0 ? -extent / 2 : 0, y: -extent / 2,
                                       width: extent / 2, height: extent)))
            local.draw(context.resolve(Image("CellLab\(names[id])Replicated")), in: rect)
            if exchange > 0 {
                local.opacity *= Double(exchange)
                local.clip(to: Path(CGRect(x: -extent / 2, y: extent * 0.15, width: extent, height: extent * 0.35)))
                local.draw(context.resolve(Image("CellLab\(names[donor])Replicated")), in: rect)
            }
            if split > 0.001 {
                var chromatid = context
                chromatid.translateBy(x: center.x, y: center.y)
                chromatid.rotate(by: .degrees(Double(sway * 3)))
                chromatid.opacity = Double(compact * split)
                chromatid.draw(context.resolve(Image("CellLab\(names[id])Single")), in: rect)
                if exchange > 0 {
                    chromatid.opacity *= Double(exchange)
                    chromatid.clip(to: Path(CGRect(x: -extent / 2, y: extent * 0.15, width: extent, height: extent * 0.35)))
                    chromatid.draw(context.resolve(Image("CellLab\(names[donor])Single")), in: rect)
                }
            }
        }
        if compact < 0.999 {
            var c = center
            if split < 0.01 { c.x += (sister == 0 ? -4 : 4) * scale }
            thread(at: c, color: colors[id], donor: colors[donor], exchange: exchange,
                   alpha: Double((1 - compact) * visibility), small: later)
        }
        kinetochores(id: id, sister: sister, center: center, angle: angle, compact: compact, split: split)
    }
    private func thread(at c: CGPoint, color: Color, donor: Color, exchange: CGFloat, alpha: Double, small: Bool) {
        guard alpha > 0.001 else { return }
        let w: CGFloat = (small ? 12 : 17) * scale
        var path = Path()
        path.move(to: CGPoint(x: c.x - w, y: c.y - w * 0.6))
        path.addCurve(to: CGPoint(x: c.x + w * 0.2, y: c.y), control1: CGPoint(x: c.x - w * 0.7, y: c.y - w * (1.5 + sway * 0.15)), control2: CGPoint(x: c.x + w, y: c.y - w))
        path.addCurve(to: CGPoint(x: c.x - w * 0.1, y: c.y + w * 0.8), control1: CGPoint(x: c.x - w, y: c.y + w * 0.6), control2: CGPoint(x: c.x - w * 0.5, y: c.y + w * 0.1))
        path.addCurve(to: CGPoint(x: c.x + w, y: c.y + w * 0.7), control1: CGPoint(x: c.x + w * 0.8, y: c.y + w * (1.5 - sway * 0.15)), control2: CGPoint(x: c.x + w * 1.1, y: c.y + w))
        context.stroke(path, with: .color(ink.opacity(alpha * 0.18)), style: StrokeStyle(lineWidth: 3.8 * scale, lineCap: .round))
        context.stroke(path, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round))
        context.stroke(path.trimmedPath(from: 0.62, to: 1), with: .color(donor.opacity(alpha * Double(exchange))), style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round))
        var shine = context
        shine.translateBy(x: -0.4 * scale, y: -0.6 * scale)
        shine.stroke(path, with: .color(.white.opacity(alpha * 0.45)), style: StrokeStyle(lineWidth: 0.7 * scale, lineCap: .round))
    }
    private func kinetochores(id: Int, sister: Int, center: CGPoint, angle: CGFloat, compact: CGFloat, split: CGFloat) {
        guard [.metaphaseI, .anaphaseI, .metaphaseII, .anaphaseII].contains(session.stage), compact > 0.1 else { return }
        if later && m(27) > 0.8 && split > 0.8 { return }
        let a = angle * .pi / 180
        let shift: CGFloat = (sister == 0 ? -4 : 4) * scale
        dot(at: CGPoint(x: center.x + shift * cos(a), y: center.y + shift * sin(a)), radius: 2.4,
            fill: .yellow, stroke: Color(red: 0.66, green: 0.42, blue: 0.06))
    }
    private func identity(_ id: Int, at c: CGPoint, compact: CGFloat) {
        text("\(id / 2 + 1)\(id % 2 == 0 ? "M" : "P")", at: CGPoint(x: c.x, y: c.y - (id / 2 == 0 ? 30 : 24) * scale),
             font: 9, color: ink.opacity(Double(compact)))
    }
    private func spindles() {
        if !later && session.stage.rawValue >= MeiosisSession.Stage.metaphaseI.rawValue {
            for id in 0..<4 {
                let opacity = motion.values[37 + id] * (1 - motion.values[14 + (session.poleForHomolog(id) == .left ? 0 : 1)])
                let origin = p(session.poleForHomolog(id) == .left ? 0.105 : 0.895, 0.5)
                let c = homolog(id)
                for sister in 0..<2 {
                    fiber(from: origin, to: CGPoint(x: c.x + (sister == 0 ? -4 : 4) * scale, y: c.y), alpha: opacity)
                }
            }
        } else if later {
            for key in 0..<4 {
                for sister in 0..<2 {
                    let product = key / 2 * 2 + sister
                    let alpha = motion.values[(sister == 0 ? 41 : 45) + key] * (1 - motion.values[29 + product])
                    let c = chromosomeII(key, sister: sister)
                    fiber(from: p(MeiosisLayout.center(key / 2), sister == 0 ? 0.17 : 0.83),
                          to: CGPoint(x: c.x, y: c.y + (sister == 0 ? -4 : 4) * scale * (1 - m(28))), alpha: alpha)
                }
            }
        }
    }
    private func fiber(from start: CGPoint, to end: CGPoint, alpha: Double) {
        guard alpha > 0.001 else { return }
        var local = context; local.opacity = alpha * (0.63 + Double(sway) * 0.10)
        local.translateBy(x: start.x, y: start.y)
        local.rotate(by: .radians(atan2(end.y - start.y, end.x - start.x)))
        local.draw(context.resolve(Image("CellLabSpindleFiber")),
                   in: CGRect(x: 0, y: -2.4 * scale, width: hypot(end.x - start.x, end.y - start.y), height: 4.8 * scale))
    }
    private func centrosomes() {
        if !later {
            let spread = session.stage == .interphase ? CGFloat(0) : m(1)
            for pole in 0..<2 {
                let alpha = (pole == 0 ? CGFloat(1) : m(1)) * (1 - m(16)) * (1 - m(14 + pole))
                let at = p(mix(pole == 0 ? 0.44 : 0.56, pole == 0 ? 0.105 : 0.895, spread), mix(0.14, 0.5, spread))
                centrosome(at: at, alpha: alpha)
                if session.stage == .metaphaseI { text(pole == 0 ? "L" : "R", at: CGPoint(x: at.x, y: at.y + 24 * scale), font: 10, color: ink) }
            }
        } else if session.stage.rawValue >= MeiosisSession.Stage.prophaseII.rawValue {
            for cell in 0..<2 {
                for sister in 0..<2 {
                    centrosome(at: p(MeiosisLayout.center(cell), sister == 0 ? 0.17 : 0.83),
                               alpha: 1 - m(29 + cell * 2 + sister))
                }
            }
        }
    }
    private func centrosome(at center: CGPoint, alpha: CGFloat) {
        guard alpha > 0.001 else { return }
        var local = context; local.opacity = Double(alpha)
        let r = (23 + sway * 2) * scale
        local.draw(context.resolve(Image("CellLabCentrosome")), in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        for index in 0..<2 {
            var barrel = local
            barrel.translateBy(x: center.x + (index == 0 ? -3 : 4) * scale, y: center.y)
            barrel.rotate(by: .degrees(index == 0 ? 0 : 90))
            barrel.draw(context.resolve(Image("CellLabCentriole")), in: CGRect(x: -5 * scale, y: -8 * scale, width: 10 * scale, height: 16 * scale))
        }
    }
    private func chiasmata() {
        for pair in 0..<2 where m(7 + pair) > 0.8 {
            let a = homolog(pair * 2), b = homolog(pair * 2 + 1)
            let y = a.y + (pair == 0 ? 15 : 12) * scale
            let center = CGPoint(x: (a.x + b.x) / 2, y: y)
            line([CGPoint(x: a.x + 9 * scale, y: y + 6 * scale), center,
                  CGPoint(x: b.x - 9 * scale, y: y - 3 * scale)], color: colors[pair * 2].opacity(0.8), width: 2)
            line([CGPoint(x: a.x + 9 * scale, y: y - 3 * scale), center,
                  CGPoint(x: b.x - 9 * scale, y: y + 6 * scale)], color: colors[pair * 2 + 1].opacity(0.8), width: 2)
            dot(at: center, radius: 3.5, fill: .yellow, stroke: ink.opacity(0.7))
        }
    }
    private func productLabels() {
        for product in 0..<4 {
            let at = MeiosisLayout.product(product)
            text(session.gameteAlleles(product), at: p(at.x, at.y + 0.15), font: 10, color: ink)
        }
        text("Allele markers · colors track segment origin", at: p(0.5, 0.965), font: 9, color: ink.opacity(0.8))
    }
    private func labels() {
        switch session.stage {
        case .interphase:
            callout("Chromatin", at: p(0.25, 0.94), anchor: homolog(0))
            callout("Nuclear envelope", at: p(0.73, 0.94), anchor: p(0.78, 0.5))
        case .prophaseI:
            let pair = MeiosisLayout.paired(0)
            callout(session.synapsed.contains(0) ? "Homologous pair" : "Homologs", at: p(0.27, 0.94), anchor: homolog(0))
            if session.synapsed.contains(0) { callout("Chiasma", at: p(0.75, 0.94), anchor: p(pair.x, pair.y + 0.045)) }
            else { callout("Centrosome", at: p(0.77, 0.10), anchor: p(0.895, 0.5)) }
        case .metaphaseI, .anaphaseI:
            callout("Sisters stay joined", at: p(0.30, 0.94), anchor: homolog(0))
            callout("Kinetochores", at: p(0.77, 0.09), anchor: homolog(1))
        case .telophaseI, .interkinesis:
            callout("Replicated chromosome", at: p(0.31, 0.95), anchor: homolog(0))
        case .prophaseII, .metaphaseII, .anaphaseII:
            callout(session.separatedII ? "Chromosome" : "Sister chromatids", at: p(0.28, 0.95), anchor: chromosomeII(0, sister: 0))
            callout("Spindle fiber", at: p(0.78, 0.95), anchor: p(0.73, 0.23))
        case .telophaseII:
            callout("Nuclear envelope", at: p(0.5, 0.95), anchor: p(0.405, 0.28))
        case .complete: break
        }
    }
    private func callout(_ title: String, at point: CGPoint, anchor: CGPoint) {
        let label = context.resolve(Text(title).font(.system(size: 11 * scale, weight: .semibold, design: .rounded)).foregroundColor(ink))
        let measured = label.measure(in: CGSize(width: size.width * 0.45, height: 40 * scale))
        let w = measured.width + 14 * scale, h = measured.height + 10 * scale
        let x = min(max(point.x, w / 2 + 2), size.width - w / 2 - 2)
        line([anchor, CGPoint(x: x, y: point.y)], color: ink.opacity(0.5), width: 0.9)
        dot(at: anchor, radius: 2.2, fill: .yellow, stroke: ink.opacity(0.6))
        let path = Path(roundedRect: CGRect(x: x - w / 2, y: point.y - h / 2, width: w, height: h), cornerRadius: 8 * scale)
        context.fill(path, with: .color(Color(red: 1, green: 0.97, blue: 0.88)))
        context.stroke(path, with: .color(ink.opacity(0.4)), lineWidth: 0.8 * scale)
        context.draw(label, at: CGPoint(x: x, y: point.y))
    }
    private func line(_ points: [CGPoint], color: Color, width: CGFloat, dash: [CGFloat] = []) {
        guard let first = points.first else { return }
        var path = Path(); path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width * scale, lineCap: .round, lineJoin: .round, dash: dash))
    }
    private func dot(at point: CGPoint, radius: CGFloat, fill: Color, stroke: Color) {
        let path = Path(ellipseIn: CGRect(x: point.x - radius * scale, y: point.y - radius * scale, width: radius * 2 * scale, height: radius * 2 * scale))
        context.fill(path, with: .color(fill)); context.stroke(path, with: .color(stroke), lineWidth: scale)
    }
    private func text(_ value: String, at point: CGPoint, font: CGFloat, color: Color) {
        context.draw(Text(value).font(.system(size: font * scale, weight: .bold, design: .rounded)).foregroundColor(color), at: point)
    }
}
