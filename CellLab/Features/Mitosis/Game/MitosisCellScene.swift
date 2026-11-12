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
    @State private var dragPositions: [Int: CGPoint] = [:]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MitosisCellDrawing(session: session, motion: CellMotion(session: session), dragged: dragPositions)
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
    let session: MitosisSession
    var motion: CellMotion
    let dragged: [Int: CGPoint]
    var animatableData: CellMotion {
        get { motion }
        set { motion = newValue }
    }

    @MainActor var body: some View {
        Canvas { context, size in
            CellPainter(context: context, size: size, session: session, motion: motion, dragged: dragged).draw()
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
    }

    private func membrane() {
        let rect = CGRect(x: size.width * (0.06 - 0.025 * split), y: size.height * 0.06,
                          width: size.width * (0.88 + 0.05 * split), height: size.height * 0.88)
        let path = Path(ellipseIn: rect)
        var shadow = context
        shadow.addFilter(.shadow(color: teal.opacity(0.17), radius: 9 * scale, x: 0, y: 7 * scale))
        shadow.fill(path, with: .color(.white))
        context.fill(path, with: .radialGradient(Gradient(colors: [Color(red: 0.94, green: 1, blue: 0.93), Color(red: 0.68, green: 0.89, blue: 0.81)]), center: p(0.38, 0.34), startRadius: 0, endRadius: size.width * 0.58))
        context.stroke(path, with: .color(teal.opacity(0.85)), lineWidth: 3 * scale)
        context.stroke(Path(ellipseIn: rect.insetBy(dx: 5 * scale, dy: 5 * scale)), with: .color(.white.opacity(0.65)), lineWidth: 2 * scale)
    }

    private func originalNucleus() {
        guard session.stage.rawValue <= MitosisSession.Stage.prometaphase.rawValue else { return }
        let path = Path(ellipseIn: CGRect(x: size.width * 0.23, y: size.height * 0.14, width: size.width * 0.54, height: size.height * 0.72))
        context.fill(path, with: .color(purple.opacity(0.11 * (1 - opening))))
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
                    line([pole(side), end], color: teal.opacity(opacity), width: selected ? 2.2 : 1.5)
                    line([CGPoint(x: pole(side).x, y: pole(side).y - 2 * scale), CGPoint(x: end.x, y: end.y - 1.5 * scale)], color: .white.opacity(0.55 * fade), width: 0.7)
                } else {
                    line([pole(side), p(side == .left ? 0.21 : 0.79, MitosisLayout.ys[id])], color: teal.opacity(0.3 * growth * fade), width: 1.2)
                }
            }
        }
        if session.envelopeOpen {
            for y in [CGFloat(0.18), CGFloat(0.82)] {
                line([pole(.left), p(0.59, y)], color: teal.opacity(0.22 * fade), width: 1.2)
                line([pole(.right), p(0.41, y)], color: teal.opacity(0.22 * fade), width: 1.2)
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
            context.fill(path, with: .linearGradient(Gradient(colors: [purple.opacity(0.08 * progress), purple.opacity(0.19 * progress)]), startPoint: p(x - 0.1, 0.2), endPoint: p(x + 0.1, 0.8)))
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
                line([CGPoint(x: center.x - 4 * scale, y: center.y), CGPoint(x: center.x + 4 * scale, y: center.y)], color: colors[id].opacity(compact), width: 5)
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
        let sign: CGFloat = side == .left ? -1 : 1
        let arm = sign * 14 * (1 - 2 * split) * scale
        let waist = sign * 4 * scale
        var path = Path()
        path.move(to: CGPoint(x: c.x + arm, y: c.y - 16 * scale))
        path.addQuadCurve(to: CGPoint(x: c.x + waist, y: c.y), control: CGPoint(x: c.x + arm, y: c.y - 6 * scale))
        path.addQuadCurve(to: CGPoint(x: c.x + arm, y: c.y + 16 * scale), control: CGPoint(x: c.x + arm, y: c.y + 6 * scale))
        context.stroke(path, with: .color(ink.opacity(0.22 * alpha)), style: StrokeStyle(lineWidth: 10 * scale, lineCap: .round))
        context.stroke(path, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: 8 * scale, lineCap: .round))
        var highlight = context
        highlight.translateBy(x: -1.2 * scale, y: -0.5 * scale)
        highlight.stroke(path, with: .color(.white.opacity(0.32 * alpha)), style: StrokeStyle(lineWidth: 1.6 * scale, lineCap: .round))
        // A small face on the upper arm, away from centromere and kinetochore.
        // Both sisters share the same expression; these are character details only.
        let face = CGPoint(x: c.x + arm, y: c.y - 12 * scale)
        for dx in [CGFloat(-1.8), CGFloat(1.8)] {
            let eye = CGPoint(x: face.x + dx * scale, y: face.y)
            ellipse(center: eye, width: 2.7, height: 3.5, fill: .white.opacity(alpha), stroke: .clear)
            ellipse(center: CGPoint(x: eye.x + sign * 0.35 * scale, y: eye.y + 0.35 * scale),
                    width: 1.4, height: 2.1, fill: ink.opacity(alpha), stroke: .clear)
        }
        var smile = Path()
        smile.move(to: CGPoint(x: face.x - 1.5 * scale, y: face.y + 4 * scale))
        smile.addQuadCurve(to: CGPoint(x: face.x + 1.5 * scale, y: face.y + 4 * scale),
                           control: CGPoint(x: face.x, y: face.y + 5.7 * scale))
        context.stroke(smile, with: .color(ink.opacity(0.8 * alpha)), style: StrokeStyle(lineWidth: 0.8 * scale, lineCap: .round))
    }

    private func thread(_ c: CGPoint, color: Color, alpha: Double, small: Bool) {
        guard alpha > 0 else { return }
        let w: CGFloat = (small ? 17 : 25) * scale
        var path = Path()
        path.move(to: CGPoint(x: c.x - w, y: c.y - 6 * scale))
        path.addCurve(to: CGPoint(x: c.x + w, y: c.y - 4 * scale), control1: CGPoint(x: c.x - w / 2, y: c.y - 24 * scale), control2: CGPoint(x: c.x, y: c.y + 17 * scale))
        path.addCurve(to: CGPoint(x: c.x - w, y: c.y + 9 * scale), control1: CGPoint(x: c.x + w, y: c.y + 22 * scale), control2: CGPoint(x: c.x - w / 2, y: c.y - 5 * scale))
        context.stroke(path, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: 3.2 * scale, lineCap: .round))
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
            ellipse(center: center, width: 30, height: 30, fill: .orange.opacity(0.12 * fade), stroke: .clear)
            // Two barrel-like centrioles, one rotated, within each centrosome.
            for angle in [0.0, Double.pi / 2] {
                var local = context
                local.translateBy(x: center.x + (angle == 0 ? -4 : 5) * scale, y: center.y)
                local.rotate(by: .radians(angle))
                let rect = CGRect(x: -3 * scale, y: -9 * scale, width: 6 * scale, height: 18 * scale)
                local.fill(Path(roundedRect: rect, cornerRadius: 2 * scale), with: .color(Color.orange.opacity(fade)))
                let stripe = Path(CGRect(x: -scale, y: -7 * scale, width: scale, height: 14 * scale))
                local.fill(stripe, with: .color(.white.opacity(0.65 * fade)))
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

