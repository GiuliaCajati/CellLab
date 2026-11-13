//
//  MitosisCellScene.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//

import SwiftUI

// Shared normalized coordinates keep the artwork and touch targets together.

enum MitosisLayout {

    static let ys: [CGFloat] = [0.27, 0.42, 0.58, 0.73]

    static let xs: [CGFloat] = [0.37, 0.63, 0.37, 0.63]

    static func chromosome(_ id: Int, aligned: Bool) -> UnitPoint {

        UnitPoint(x: aligned ? 0.5 : xs[id], y: ys[id])

    }

    static func pole(_ pole: MitosisSession.Pole, moved: Bool) -> UnitPoint {

        UnitPoint(x: moved ? (pole == .left ? 0.09 : 0.91) : (pole == .left ? 0.29 : 0.71),

                  y: moved ? 0.5 : 0.15)

    }

}

struct MitosisCellScene: View {

    let session: MitosisSession

    let onAction: (MitosisSession.Action) -> Void
    var showsParts = false

    @State private var dragPositions: [Int: CGPoint] = [:]

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                MitosisCellDrawing(session: session, motion: CellMotion(session: session), dragged: dragPositions, showsParts: showsParts)

                    .accessibilityHidden(true)

                targets(in: geometry.size)

            }

            .coordinateSpace(name: "mitosisCell")

        }

        .aspectRatio(1.05, contentMode: .fit)

        .onChange(of: session.stage) { _, _ in dragPositions.removeAll() }

    }

    @ViewBuilder

    private func targets(in size: CGSize) -> some View {

        switch session.stage {

        case .prophase:

            if session.condensed.count < 4 {

                ForEach(MitosisSession.chromosomeIDs, id: \.self) { id in

                    if !session.condensed.contains(id) {

                        target("Condense chromosome \(id + 1)", at: MitosisLayout.chromosome(id, aligned: false), in: size) {

                            onAction(.condense(id))

                        }

                    }

                }

            } else {

                ForEach(MitosisSession.Pole.allCases) { pole in

                    if !session.movedPoles.contains(pole) {

                        target("Move \(pole.rawValue.lowercased()) centrosome",

                               at: MitosisLayout.pole(pole, moved: false), in: size) {

                            onAction(.movePole(pole))

                        }

                    }

                }

            }

        case .prometaphase:

            if !session.envelopeOpen {

                Button { onAction(.openEnvelope) } label: {

                    Label("Open envelope", systemImage: "arrow.up.left.and.arrow.down.right")

                        .font(.system(.caption, design: .rounded, weight: .bold))

                        .padding(.horizontal, 12)

                        .frame(minHeight: 44)

                        .background(.regularMaterial, in: Capsule())

                }

                .buttonStyle(.plain)

                .position(x: size.width / 2, y: size.height * 0.10)

            } else {

                ForEach(MitosisSession.chromosomeIDs, id: \.self) { id in

                    let attached = session.selectedPole == .left

                        ? session.leftAttachments.contains(id) : session.rightAttachments.contains(id)

                    if !attached {

                        target("Connect chromosome \(id + 1) to \(session.selectedPole.rawValue.lowercased()) pole",

                               at: MitosisLayout.chromosome(id, aligned: false), in: size) {

                            onAction(.attach(id))

                        }

                    }

                }

            }

        case .metaphase:

            ForEach(MitosisSession.chromosomeIDs, id: \.self) { id in

                if !session.aligned.contains(id) {

                    let location = dragPositions[id].map { UnitPoint(x: $0.x / size.width, y: $0.y / size.height) }

                        ?? MitosisLayout.chromosome(id, aligned: false)

                    target("Align chromosome \(id + 1)", at: location, in: size,

                           onDrag: { location in

                               dragPositions[id] = CGPoint(

                                   x: min(max(location.x, 20), size.width - 20),

                                   y: min(max(location.y, 20), size.height - 20))

                           },

                           onDrop: { location in

                               dragPositions[id] = nil

                               onAction(.align(id, nearEquator: abs(location.x - size.width / 2) < size.width * 0.12))

                           }) {

                        onAction(.align(id, nearEquator: true))

                    }

                    .accessibilityHint("Double-tap to align automatically")

                }

            }

        case .telophase:

            ForEach(MitosisSession.Pole.allCases) { pole in

                if !session.rebuiltNuclei.contains(pole) {

                    target("Rebuild \(pole.rawValue.lowercased()) nucleus",

                           at: UnitPoint(x: pole == .left ? 0.28 : 0.72, y: 0.5), in: size, diameter: 76) {

                        onAction(.rebuildNucleus(pole))

                    }

                }

            }

        default: EmptyView()

        }

    }

    private func target(_ label: String, at point: UnitPoint, in size: CGSize,

                        diameter: CGFloat = 48, onDrag: ((CGPoint) -> Void)? = nil,

                        onDrop: ((CGPoint) -> Void)? = nil, action: @escaping () -> Void) -> some View {

        Button(action: action) {

            Circle()

                .fill(.white.opacity(0.001))

                .overlay(Circle().stroke(.white.opacity(0.95), style: StrokeStyle(lineWidth: 2, dash: [3, 4])))

                .frame(width: diameter, height: diameter)

                .contentShape(Circle())

        }

        .buttonStyle(.plain)

        .accessibilityLabel(label)

        .simultaneousGesture(

            DragGesture(minimumDistance: 8, coordinateSpace: .named("mitosisCell"))

                .onChanged { onDrag?($0.location) }

                .onEnded { onDrop?($0.location) },

            including: onDrag == nil ? .none : .all

        )

        .position(x: size.width * point.x, y: size.height * point.y)

    }

}

// Four alignments, separation, envelope opening, two poles, four condensations, two nuclei.

// Drawing and spindle endpoints use the same values so fibers follow their chromosomes.

nonisolated struct CellMotion: VectorArithmetic {

    var values: [Double]

    static var zero: Self { Self(values: Array(repeating: 0, count: 14)) }

    init(values: [Double]) { self.values = values }

    init(session: MitosisSession) {

        values = MitosisSession.chromosomeIDs.map { session.aligned.contains($0) ? 1 : 0 }

        values += [session.separated ? 1 : 0, session.envelopeOpen ? 1 : 0,

                   session.movedPoles.contains(.left) ? 1 : 0,

                   session.movedPoles.contains(.right) ? 1 : 0]

        values += MitosisSession.chromosomeIDs.map { session.condensed.contains($0) ? 1 : 0 }

        values += [session.rebuiltNuclei.contains(.left) ? 1 : 0,

                   session.rebuiltNuclei.contains(.right) ? 1 : 0]

    }

    static func + (lhs: Self, rhs: Self) -> Self {

        Self(values: zip(lhs.values, rhs.values).map { $0.0 + $0.1 })

    }

    static func - (lhs: Self, rhs: Self) -> Self {

        Self(values: zip(lhs.values, rhs.values).map { $0.0 - $0.1 })

    }

    mutating func scale(by rhs: Double) { values = values.map { $0 * rhs } }

    var magnitudeSquared: Double { values.reduce(0) { $0 + $1 * $1 } }

}

private nonisolated struct MitosisCellDrawing: View, Animatable {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let session: MitosisSession

    var motion: CellMotion

    let dragged: [Int: CGPoint]
    let showsParts: Bool

    var animatableData: CellMotion {

        get { motion }

        set { motion = newValue }

    }

    @MainActor var body: some View {
        if reduceMotion {
            canvas(at: 0, animated: false)
        } else {
            // Regular frames keep the scene moving while waiting for a tap.
            TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { frame in
                canvas(at: frame.date.timeIntervalSinceReferenceDate, animated: true)
            }
        }
    }

    @MainActor private func canvas(at time: Double, animated: Bool) -> some View {
        Canvas { context, size in
            CellPainter(context: context, size: size, session: session, motion: motion,
                        dragged: dragged, showsParts: showsParts,
                        ambientTime: time, ambientEnabled: animated).draw()
        }
    }
}

// Procedural, resolution-independent biological artwork. Real buttons supply accessibility.

private struct CellPainter {

    let context: GraphicsContext

    let size: CGSize

    let session: MitosisSession

    let motion: CellMotion

    let dragged: [Int: CGPoint]
    let showsParts: Bool
    let ambientTime: Double
    let ambientEnabled: Bool
    private var shimmer: Double { ambientEnabled ? 0.76 + 0.24 * sin(ambientTime * 2) : 1 }
    private var sway: CGFloat { ambientEnabled ? CGFloat(sin(ambientTime * 1.65)) : 0 }

    private let purple = Color(red: 0.44, green: 0.27, blue: 0.76)

    private let teal = Color(red: 0.09, green: 0.49, blue: 0.43)

    private let ink = Color(red: 0.12, green: 0.21, blue: 0.25)

    private var colors: [Color] { [purple, Color(red: 0.12, green: 0.42, blue: 0.75), Color(red: 0.76, green: 0.22, blue: 0.46), Color(red: 0.74, green: 0.40, blue: 0.10)] }

    private var scale: CGFloat { size.width / 360 }

    private var split: CGFloat { CGFloat(motion.values[4]) }

    private var opening: Double { motion.values[5] }

    private var nuclei: Double { (motion.values[12] + motion.values[13]) / 2 }

    func draw() {

        membrane()

        originalNucleus()

        spindle()

        daughterNuclei()

        if session.stage == .metaphase {

            line([p(0.5, 0.13), p(0.5, 0.87)], color: teal.opacity(0.6), width: 1.5, dash: [3, 6])

            text("EQUATOR", at: p(0.5, 0.095), font: 10, color: ink)

        }

        dna()

        centrosomes()
        if showsParts { partLabels() }

    }

    private func membrane() {

        let rect = CGRect(x: size.width * (0.06 - 0.025 * split), y: size.height * 0.06,

                          width: size.width * (0.88 + 0.05 * split), height: size.height * 0.88)

        context.draw(context.resolve(Image("CellLabCellShell")), in: rect)
    }

    private func originalNucleus() {

        guard session.stage.rawValue <= MitosisSession.Stage.prometaphase.rawValue else { return }


        var nuclearBody = context
        nuclearBody.opacity = 0.9 * (1 - opening)
        let rim: CGFloat = 240.0 / 224.0
        nuclearBody.draw(context.resolve(Image("CellLabPhaseNucleus")),
                         in: CGRect(x: size.width * (0.5 - 0.27 * rim),
                                    y: size.height * (0.5 - 0.36 * rim),
                                    width: size.width * 0.54 * rim, height: size.height * 0.72 * rim))

        // Envelope breaks into visible fragments which drift outward and fade.

        for segment in 0..<16 {

            var arc = Path()

            for step in 0...8 {

                let a = (Double(segment) + Double(step) / 8 * (1 - opening * 0.38)) * .pi / 8

                let point = p(0.5 + CGFloat(cos(a)) * (0.27 + CGFloat(opening) * 0.06),

                              0.5 + CGFloat(sin(a)) * (0.36 + CGFloat(opening) * 0.05))

                if step == 0 { arc.move(to: point) } else { arc.addLine(to: point) }

            }

            context.stroke(arc, with: .color(purple.opacity(0.58 * (1 - opening))), lineWidth: 2.5 * scale)

        }

        let packed = motion.values[8...11].reduce(0, +) / 4

        ellipse(center: p(0.50, 0.49), width: 17, height: 17,

                fill: purple.opacity(0.4 * (1 - packed)), stroke: .clear)

    }

    private func spindle() {

        guard session.stage != .complete else { return }

        let fade = 1 - nuclei

        for side in MitosisSession.Pole.allCases {

            let growth = motion.values[side == .left ? 6 : 7]

            guard growth > 0 else { continue }

            let attachments = side == .left ? session.leftAttachments : session.rightAttachments

            let selected = session.stage == .prometaphase && session.selectedPole == side

            let opacity = (selected ? 0.85 : 0.42) * fade

            for id in MitosisSession.chromosomeIDs {

                if attachments.contains(id) {

                    let c = chromosome(id, side: side)

                    let sign: CGFloat = side == .left ? -1 : 1

                    let end = CGPoint(x: c.x + sign * 4 * scale, y: c.y)

                    spindleFiber(from: pole(side), to: end, alpha: opacity, thickness: selected ? 7 : 5)

                    line([CGPoint(x: pole(side).x, y: pole(side).y - 2 * scale), CGPoint(x: end.x, y: end.y - 1.5 * scale)], color: .white.opacity(0.55 * fade), width: 0.7)

                } else {

                    spindleFiber(from: pole(side), to: p(side == .left ? 0.21 : 0.79, MitosisLayout.ys[id]), alpha: 0.3 * growth * fade, thickness: 4)

                }

            }

        }

        if session.envelopeOpen {

            for y in [CGFloat(0.18), CGFloat(0.82)] {

                spindleFiber(from: pole(.left), to: p(0.59, y), alpha: 0.3 * fade, thickness: 4)

                spindleFiber(from: pole(.right), to: p(0.41, y), alpha: 0.3 * fade, thickness: 4)

            }

        }

    }

    private func daughterNuclei() {

        for side in MitosisSession.Pole.allCases {

            let progress = motion.values[side == .left ? 12 : 13]

            guard progress > 0 else { continue }

            let x: CGFloat = side == .left ? 0.28 : 0.72

            let rect = CGRect(x: size.width * (x - 0.15), y: size.height * 0.18, width: size.width * 0.30, height: size.height * 0.64)

            let path = Path(ellipseIn: rect)

            var rebuilt = context
            rebuilt.opacity = progress * 0.9
            rebuilt.draw(context.resolve(Image("CellLabPhaseNucleus")),
                         in: rect.insetBy(dx: -rect.width / 28, dy: -rect.height / 28))

            context.stroke(path.trimmedPath(from: 0, to: CGFloat(progress)), with: .color(purple.opacity(0.65)), style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round))

            context.stroke(Path(ellipseIn: rect.insetBy(dx: 3 * scale, dy: 3 * scale)), with: .color(.white.opacity(0.6 * progress)), lineWidth: scale)

            ellipse(center: p(x, 0.5), width: 12, height: 12, fill: purple.opacity(0.45 * progress), stroke: .clear)

        }

    }

    private func dna() {

        for id in MitosisSession.chromosomeIDs {

            if session.separated {

                for side in MitosisSession.Pole.allCases {

                    let center = chromosome(id, side: side)

                    let unpack = motion.values[side == .left ? 12 : 13]

                    ribbon(center, side: side, color: colors[id], alpha: 1 - unpack)

                    thread(center, color: colors[id], alpha: unpack, small: true)

                    identity(id, at: center, alpha: 1 - unpack)

                }

            } else {

                let center = chromosome(id, side: nil)

                let compact = motion.values[8 + id]

                thread(center, color: colors[id], alpha: 1 - compact, small: false)

                ribbon(center, side: .left, color: colors[id], alpha: compact)

                ribbon(center, side: .right, color: colors[id], alpha: compact)


                identity(id, at: center, alpha: compact)

                if session.stage == .prometaphase || session.stage == .metaphase {

                    for side in MitosisSession.Pole.allCases {

                        let dx: CGFloat = side == .left ? -5 : 5

                        let c = CGPoint(x: center.x + dx * scale, y: center.y)

                        let linked = (side == .left ? session.leftAttachments : session.rightAttachments).contains(id)

                        ellipse(center: c, width: linked ? 8 : 10, height: linked ? 8 : 10, fill: Color.yellow.opacity(0.28), stroke: .clear)

                        ellipse(center: c, width: 5, height: 7, fill: .yellow, stroke: Color(red: 0.66, green: 0.42, blue: 0.06))

                    }

                }

            }

        }

    }

    private func ribbon(_ c: CGPoint, side: MitosisSession.Pole, color: Color, alpha: Double) {
        guard alpha > 0 else { return }
        let replicatedName: String
        let singleName: String
        if color == colors[0] {
            replicatedName = "CellLabPurpleReplicated"; singleName = "CellLabPurpleSingle"
        } else if color == colors[1] {
            replicatedName = "CellLabBlueReplicated"; singleName = "CellLabBlueSingle"
        } else if color == colors[2] {
            replicatedName = "CellLabPinkReplicated"; singleName = "CellLabPinkSingle"
        } else {
            replicatedName = "CellLabGoldReplicated"; singleName = "CellLabGoldSingle"
        }
        // Crop each sister from the same replicated asset. Each half follows the
        // original interpolated chromosome center during the separation action.
        let extent: CGFloat = 48 * scale
        var sister = context
        sister.opacity = alpha * Double(1 - split)
        sister.translateBy(x: c.x, y: c.y)
        let angle: CGFloat = session.stage == .prophase ? 6 : session.stage == .prometaphase ? 3 : 1.5
        sister.rotate(by: .degrees(Double(sway * angle)))
        sister.clip(to: Path(CGRect(x: side == .left ? -extent / 2 : 0,
                                   y: -extent / 2, width: extent / 2, height: extent)))
        sister.draw(context.resolve(Image(replicatedName)),
                    in: CGRect(x: -extent / 2, y: -extent / 2, width: extent, height: extent))
        // Rotate single chromatids around their centromeres, keeping touch targets
        // and spindle endpoints fixed. The action's existing 1.2-second path is unchanged.
        var single = context
        single.opacity = alpha * Double(split)
        single.translateBy(x: c.x, y: c.y)
        single.rotate(by: .degrees(Double(sway) * 5))
        single.draw(context.resolve(Image(singleName)),
                    in: CGRect(x: -extent / 2, y: -extent / 2, width: extent, height: extent))
    }

    private func spindleFiber(from start: CGPoint, to end: CGPoint, alpha: Double, thickness: CGFloat) {
        var fiber = context
        fiber.opacity = alpha * shimmer
        let dx = end.x - start.x, dy = end.y - start.y
        fiber.translateBy(x: start.x, y: start.y)
        fiber.rotate(by: .radians(atan2(dy, dx)))
        fiber.draw(context.resolve(Image("CellLabSpindleFiber")),
                   in: CGRect(x: 0, y: -thickness * scale / 2, width: hypot(dx, dy), height: thickness * scale))
    }

    private func thread(_ c: CGPoint, color: Color, alpha: Double, small: Bool) {
        guard alpha > 0 else { return }
        // Two loose fibers before separation; one after sisters have separated.
        // The small beads suggest DNA-associated histones, rather than extra chromosomes.
        let fibers = small ? 1 : 2
        let width: CGFloat = (small ? 16 : 20) * scale
        let wave = ambientEnabled ? CGFloat(sin(ambientTime * 1.8 + Double(c.y / scale) * 0.025)) : 0
        let breath = 1 + (small ? 0.05 : 0.10) * wave
        var local = context
        local.opacity = alpha
        if session.stage == .prophase || session.stage == .prometaphase {
            let open = CGFloat(opening)
            let interior = CGRect(x: size.width * (0.23 - 0.06 * open),
                                  y: size.height * (0.14 - 0.05 * open),
                                  width: size.width * (0.54 + 0.12 * open),
                                  height: size.height * (0.72 + 0.10 * open))
            local.clip(to: Path(ellipseIn: interior.insetBy(dx: 2 * scale, dy: 2 * scale)))
        }
        local.translateBy(x: c.x, y: c.y)
        local.rotate(by: .degrees(Double(wave) * (small ? 4 : 8)))
        local.scaleBy(x: breath, y: breath)
        for fiber in 0..<fibers {
            var strand = local
            let offset: CGFloat = small ? 0 : (fiber == 0 ? -3 : 3) * scale
            strand.translateBy(x: small ? 0 : (fiber == 0 ? -1.5 : 1.5) * scale, y: offset)
            let h = width * (small ? 0.65 : 0.64)
            var path = Path()
            let nodes: [CGPoint]
            if fiber == 0 {
                path.move(to: CGPoint(x: -width, y: -h * 0.5))
                path.addCurve(to: CGPoint(x: width * 0.35, y: -h * 0.1),
                              control1: CGPoint(x: -width * 0.65, y: -h * (1.5 + 0.15 * wave)),
                              control2: CGPoint(x: width * 0.8, y: -h * 1.15))
                path.addCurve(to: CGPoint(x: -width * 0.05, y: h * 0.8),
                              control1: CGPoint(x: width * 0.1, y: h * 0.55),
                              control2: CGPoint(x: -width * 0.55, y: h * 0.15))
                path.addCurve(to: CGPoint(x: width * 0.85, y: h * 0.35),
                              control1: CGPoint(x: width * 0.2, y: h * (1.5 - 0.15 * wave)),
                              control2: CGPoint(x: width * 1.2, y: h * 1.1))
                nodes = [CGPoint(x: width * 0.35, y: -h * 0.1), CGPoint(x: -width * 0.05, y: h * 0.8)]
            } else {
                path.move(to: CGPoint(x: -width * 0.85, y: h * 0.15))
                path.addCurve(to: CGPoint(x: -width * 0.1, y: -h * 0.55),
                              control1: CGPoint(x: -width * 1.3, y: -h * 0.6),
                              control2: CGPoint(x: -width * 0.5, y: -h * (1.2 - 0.15 * wave)))
                path.addCurve(to: CGPoint(x: width * 0.05, y: h * 0.6),
                              control1: CGPoint(x: width * 0.6, y: -h * 0.1),
                              control2: CGPoint(x: width * 0.6, y: h * 0.1))
                path.addCurve(to: CGPoint(x: width, y: h * 0.8),
                              control1: CGPoint(x: -width * 0.5, y: h * (1.2 + 0.15 * wave)),
                              control2: CGPoint(x: width * 0.45, y: h * 1.7))
                nodes = [CGPoint(x: -width * 0.1, y: -h * 0.55), CGPoint(x: width * 0.05, y: h * 0.6)]
            }
            strand.stroke(path, with: .color(ink.opacity(0.14)),
                          style: StrokeStyle(lineWidth: 3.8 * scale, lineCap: .round, lineJoin: .round))
            strand.stroke(path, with: .color(color.opacity(fiber == 0 ? 0.9 : 0.7)),
                          style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round, lineJoin: .round))
            var shine = strand
            shine.translateBy(x: -0.5 * scale, y: -0.7 * scale)
            shine.stroke(path, with: .color(.white.opacity(0.5)),
                         style: StrokeStyle(lineWidth: 0.9 * scale, lineCap: .round))
            for bead in nodes {
                let dot = Path(ellipseIn: CGRect(x: bead.x - 2.3 * scale, y: bead.y - 2.3 * scale,
                                                width: 4.6 * scale, height: 4.6 * scale))
                strand.fill(dot, with: .color(color.opacity(0.95)))
                strand.stroke(dot, with: .color(ink.opacity(0.2)), lineWidth: 0.6 * scale)
                strand.fill(Path(ellipseIn: CGRect(x: bead.x - 1.6 * scale, y: bead.y - 1.8 * scale,
                                                   width: 1.8 * scale, height: 1.5 * scale)),
                            with: .color(.white.opacity(0.75)))
            }
        }
    }

    private func centrosomes() {

        let fade = 1 - nuclei

        guard fade > 0, session.stage != .complete else { return }

        for side in MitosisSession.Pole.allCases {

            let center = pole(side)

            if session.stage == .prometaphase && session.envelopeOpen && session.selectedPole == side {

                ellipse(center: center, width: 38, height: 38, fill: .yellow.opacity(0.22), stroke: .orange.opacity(0.7))

                ellipse(center: center, width: 46, height: 46, fill: .clear, stroke: .orange.opacity(0.2))

            }

            var halo = context
            halo.opacity = fade
            let radius = (24 + 5 * sway) * scale
            halo.draw(context.resolve(Image("CellLabCentrosome")),
                      in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            for angle in [0.0, Double.pi / 2] {
                var local = context
                local.opacity = fade
                local.translateBy(x: center.x + (angle == 0 ? -4 : 5) * scale, y: center.y)
                local.rotate(by: .radians(angle + Double(sway) * 0.08))
                local.draw(context.resolve(Image("CellLabCentriole")),
                           in: CGRect(x: -8 * scale, y: -12 * scale, width: 16 * scale, height: 24 * scale))
            }

            if session.stage == .prometaphase {

                text(side == .left ? "L" : "R", at: CGPoint(x: center.x, y: center.y + 25 * scale), font: 11, color: ink)

            }

        }

    }

    private func chromosome(_ id: Int, side: MitosisSession.Pole?) -> CGPoint {

        if session.stage == .metaphase, let dragged = dragged[id] { return dragged }

        let x = MitosisLayout.xs[id] + (0.5 - MitosisLayout.xs[id]) * CGFloat(motion.values[id])

        let target: CGFloat = side == .left ? 0.28 : 0.72

        return p(side == nil ? x : x + (target - x) * split, MitosisLayout.ys[id])

    }

    private func pole(_ side: MitosisSession.Pole) -> CGPoint {

        let t = CGFloat(motion.values[side == .left ? 6 : 7])

        let a = MitosisLayout.pole(side, moved: false)

        let b = MitosisLayout.pole(side, moved: true)

        let stretch: CGFloat = side == .left ? -0.015 : 0.015

        return p(a.x + (b.x - a.x) * t + stretch * split, a.y + (b.y - a.y) * t)

    }

    /// Optional labels use the same live geometry as the artwork; they never intercept input.
    private func partLabels() {
        switch session.stage {
        case .prophase:
            callout(motion.values[11] > 0.5 ? "Sister chromatids" : "Chromatin",
                    at: p(0.74, 0.92), anchor: chromosome(3, side: nil))
            callout("Nuclear envelope", at: p(0.26, 0.92), anchor: p(0.34, 0.79))
            let left = pole(.left)
            callout("Centrioles", at: CGPoint(x: left.x, y: max(16 * scale, left.y - 38 * scale)),
                    anchor: CGPoint(x: left.x - 4 * scale, y: left.y))
        case .prometaphase:
            callout("Kinetochores", at: p(0.30, 0.08),
                    anchor: CGPoint(x: chromosome(0, side: nil).x - 5 * scale, y: chromosome(0, side: nil).y))
            if opening < 0.5 {
                callout("Nuclear envelope", at: p(0.72, 0.09), anchor: p(0.77, 0.50))
            } else {
                let c = chromosome(1, side: nil)
                let start = pole(.right)
                callout("Spindle fibers", at: p(0.72, 0.09),
                        anchor: CGPoint(x: (start.x + c.x) / 2, y: (start.y + c.y) / 2))
            }
            let left = pole(.left)
            callout("Centrosome", at: CGPoint(x: left.x + 40 * scale, y: left.y + 42 * scale), anchor: left)
        case .metaphase:
            callout("Sister chromatids", at: p(0.26, 0.04), anchor: chromosome(1, side: nil))
            callout("Kinetochores", at: p(0.77, 0.04),
                    anchor: CGPoint(x: chromosome(0, side: nil).x + 5 * scale, y: chromosome(0, side: nil).y))
            let c = chromosome(3, side: nil), start = pole(.left)
            callout("Spindle fibers", at: p(0.50, 0.92),
                    anchor: CGPoint(x: (start.x + c.x) / 2, y: (start.y + c.y) / 2))
        case .anaphase:
            callout(split > 0.5 ? "Chromosomes" : "Sister chromatids", at: p(0.30, 0.08),
                    anchor: chromosome(0, side: session.separated ? .left : nil))
            let right = pole(.right)
            callout("Centrosome", at: CGPoint(x: right.x - 25 * scale, y: right.y - 42 * scale), anchor: right)
            let c = chromosome(3, side: .left), start = pole(.left)
            callout("Spindle fibers", at: p(0.50, 0.92),
                    anchor: CGPoint(x: (start.x + c.x) / 2, y: (start.y + c.y) / 2))
        case .telophase, .complete:
            let leftBuilt = motion.values[12] > 0.5
            let rightBuilt = motion.values[13] > 0.5
            callout(leftBuilt ? "Chromatin" : "Chromosomes", at: p(0.27, 0.08),
                    anchor: chromosome(0, side: .left))
            if leftBuilt || rightBuilt {
                let x: CGFloat = leftBuilt ? 0.28 : 0.72
                callout("Nuclear envelope", at: p(0.75, 0.09), anchor: p(x + 0.15, 0.50))
                callout("Nucleolus", at: p(0.50, 0.92), anchor: p(x, 0.50))
            }
        }
    }

    private func callout(_ title: String, at point: CGPoint, anchor: CGPoint) {
        let label = context.resolve(Text(verbatim: title)
            .font(.system(size: 12 * scale, weight: .semibold, design: .rounded))
            .foregroundColor(ink))
        let measured = label.measure(in: CGSize(width: size.width * 0.48, height: 48 * scale))
        let width = measured.width + 16 * scale
        let height = measured.height + 12 * scale
        let x = min(max(point.x, width / 2 + 3 * scale), size.width - width / 2 - 3 * scale)
        let box = CGRect(x: x - width / 2, y: point.y - height / 2, width: width, height: height)
        line([anchor, CGPoint(x: x, y: point.y)], color: ink.opacity(0.6), width: 1)
        ellipse(center: anchor, width: 5, height: 5, fill: .yellow, stroke: ink.opacity(0.8))
        let path = Path(roundedRect: box, cornerRadius: 8 * scale)
        context.fill(path, with: .color(Color(red: 1, green: 0.97, blue: 0.88)))
        context.stroke(path, with: .color(ink.opacity(0.5)), lineWidth: 0.8 * scale)
        context.draw(label, at: CGPoint(x: x, y: point.y))
    }

    private func identity(_ id: Int, at c: CGPoint, alpha: Double) {

        let point = CGPoint(x: c.x + 23 * scale, y: c.y - 15 * scale)

        ellipse(center: point, width: 13, height: 13, fill: .white.opacity(0.85 * alpha), stroke: .clear)

        text("\(id + 1)", at: point, font: 9, color: ink.opacity(alpha))

    }

    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: size.width * x, y: size.height * y) }

    private func ellipse(center: CGPoint, width: CGFloat, height: CGFloat, fill: Color, stroke: Color) {

        let rect = CGRect(x: center.x - width * scale / 2, y: center.y - height * scale / 2, width: width * scale, height: height * scale)

        context.fill(Path(ellipseIn: rect), with: .color(fill))

        context.stroke(Path(ellipseIn: rect), with: .color(stroke), lineWidth: scale)

    }

    private func line(_ points: [CGPoint], color: Color, width: CGFloat, dash: [CGFloat] = []) {

        guard let first = points.first else { return }

        var path = Path()

        path.move(to: first)

        for point in points.dropFirst() { path.addLine(to: point) }

        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width * scale, lineCap: .round, lineJoin: .round, dash: dash))

    }

    private func text(_ value: String, at point: CGPoint, font: CGFloat, color: Color) {

        context.draw(Text(value).font(.system(size: font * scale, weight: .bold, design: .rounded)).foregroundColor(color), at: point)

    }

}

