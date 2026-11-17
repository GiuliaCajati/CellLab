import SwiftUI

@MainActor struct DNACopyBoard: View {
    @Bindable var session: DNACopySession
    let width: CGFloat
    var motionPaused = false
    var onDraggingChanged: (Bool) -> Void = { _ in }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: DNACopyNucleotideDrag?
    @State private var dropHovered = false

    private var targets: [DNACopyTarget] {
        guard session.celebration == nil else { return [] }
        if session.stage == .origin { return (0..<3).map { .origin($0) } }
        if session.stage == .stabilize { return (0..<3).filter { !session.bindingSites.contains($0) }.map { .binding($0) } }
        return session.activeTarget.map { [$0] } ?? []
    }
    private var scale: CGFloat { width / 360 }
    private func screen(_ logical: CGPoint) -> CGPoint {
        DNACopyBoardLayout.screen(logical, width: width)
    }
    var body: some View {
        let state = DNACopyBoardState(session)
        ZStack(alignment: .topLeading) {
            // Only the drawing scales. Touch controls are placed independently
            // in actual view coordinates and retain a 56-point hit area.
            DNACopyMolecularCanvas(state: state, openFraction: session.unwound ? 1 : 0)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.4), value: session.unwound)
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("DNA strands")
                .accessibilityValue(session.stage.title)
                .accessibilityIdentifier("dna-game-drawing")

            if [.prime, .leading, .lagging, .replace].contains(session.stage) {
                floatingPool
            }
            ForEach(targets, id: \.self) { target in
                targetButton(target)
                    .frame(width: 56, height: 56)
                    .offset(x: screen(DNACopyBoardLayout.point(target)).x - 28,
                            y: screen(DNACopyBoardLayout.point(target)).y - 28)
                    .id(target)
                    .zIndex(3)
            }
            if let target = session.lastSuccessTarget, session.successSerial > 0 {
                DNACopySuccessRipple(reduceMotion: reduceMotion)
                    .id(session.successSerial)
                    .position(screen(DNACopyBoardLayout.point(target)))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .zIndex(4)
            }
            if let drag {
                DNACopyNucleotide(base: drag.base, selected: true)
                    .scaleEffect(scale * 1.08)
                    .position(drag.location)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .zIndex(5)
            }
        }
        .frame(width: width, height: width * 460 / 360)
        .coordinateSpace(name: "dna-copy-board")
        .contentShape(Rectangle())
        .dropDestination(for: String.self) { items, location in
            guard let payload = items.first,
                  let target = DNACopyBoardLayout.nearestTarget(to: location, targets: targets, width: width) else {
                session.missedDrop(); return false
            }
            return session.receive(payload, at: target)
        } isTargeted: { dropHovered = $0 }
        .onChange(of: session.stage) { _, _ in drag = nil; onDraggingChanged(false) }
        .onChange(of: session.celebration?.id) { _, value in if value != nil { drag = nil; onDraggingChanged(false) } }
        .onDisappear { onDraggingChanged(false) }
        .accessibilityElement(children: .contain)
    }

    private var floatingPool: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24,
                                paused: reduceMotion || motionPaused || session.celebration != nil || drag != nil || session.selectedBase != nil)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .topLeading) {
                ForEach(0..<(session.stage == .replace ? 4 : 8), id: \.self) { index in
                    let base = DNACopyBase.allCases[index % 4]
                    let anchor = screen(DNACopyBoardLayout.poolAnchor(index, stage: session.stage))
                    let visual = screen(DNACopyBoardLayout.pool(index, time: time, stage: session.stage))
                    Button { session.choose(base: base) } label: {
                        ZStack {
                            Color.clear
                            DNACopyNucleotide(base: base, selected: session.selectedBase == base)
                                .scaleEffect(scale)
                                .offset(x: visual.x - anchor.x, y: visual.y - anchor.y)
                                .opacity(drag?.source == index ? 0.3 : 1)
                                .allowsHitTesting(false)
                        }
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    // Immediate finger/mouse dragging, independent of the
                    // system's long-press drag recognizer on a Button.
                    .highPriorityGesture(DragGesture(minimumDistance: 8, coordinateSpace: .named("dna-copy-board"))
                        .onChanged { value in
                            guard session.celebration == nil else { return }
                            if drag == nil {
                                onDraggingChanged(true)
                                session.choose(base: base)
                                drag = DNACopyNucleotideDrag(base: base, source: index, location: value.location, target: session.activeTarget)
                            } else if drag?.source == index { drag?.location = value.location }
                        }
                        .onEnded { value in
                            let pending = drag
                            drag = nil
                            onDraggingChanged(false)
                            guard let pending, pending.source == index,
                                  let target = pending.target, target == session.activeTarget,
                                  DNACopyBoardLayout.nearestTarget(to: value.location, targets: targets, width: width) == target else {
                                session.missedDrop(); return
                            }
                            _ = session.receive(pending.base.payload, at: target)
                        })
                    .accessibilityLabel("\(base.rawValue) DNA nucleotide")
                    .accessibilityValue(session.selectedBase == base ? "Selected" : "")
                    .accessibilityHint("Drag to the growing end, or select then tap the target or Attach button")
                    .accessibilityIdentifier("dna-game-base-\(base.rawValue)-\(index)")
                    .disabled(session.celebration != nil)
                    .position(anchor)
                }
            }
            .frame(width: width, height: width * 460 / 360)
        }
        .frame(width: width, height: width * 460 / 360)
    }
    private func targetButton(_ target: DNACopyTarget) -> some View {
        Button { session.tap(target) } label: {
            ZStack {
                Color.clear
                RoundedRectangle(cornerRadius: 9)
                    .fill(.white.opacity(target == .mismatch ? 0 : 0.82))
                    .overlay(RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(target == .mismatch ? DNACopyStyle.error : DNACopyStyle.teal,
                                      style: StrokeStyle(lineWidth: 2.2, dash: dropHovered || drag != nil ? [] : [4, 3]))
                        .allowsHitTesting(false))
                    .frame(width: 30 * scale, height: 28 * scale)
                    .shadow(color: DNACopyStyle.teal.opacity(0.2), radius: dropHovered || drag != nil ? 8 : 3)
                if target != .mismatch {
                    Image(systemName: targetSymbol(target))
                        .font(.system(size: 14 * scale, weight: .bold))
                        .foregroundStyle(DNACopyStyle.teal)
                }
            }
            .frame(width: 56, height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(session.targetLabel)
        .accessibilityHint("Select a tool or nucleotide, then tap; the button below also applies your selection")
        .accessibilityIdentifier("dna-game-target")
        .accessibilitySortPriority(2)
    }
    private func targetSymbol(_ target: DNACopyTarget) -> String {
        switch target {
        case .origin: return "sparkle"
        case .primer: return "flag.fill"
        case .nick: return "link"
        case .mismatch: return "minus"
        default: return "plus"
        }
    }
}

private struct DNACopyNucleotideDrag {
    let base: DNACopyBase
    let source: Int
    var location: CGPoint
    let target: DNACopyTarget?
}

private struct DNACopySuccessRipple: View {
    let reduceMotion: Bool
    @State private var expanded = false
    var body: some View {
        ZStack {
            Circle().stroke(DNACopyStyle.teal, lineWidth: 2)
                .scaleEffect(expanded ? 1.5 : 0.65)
            ForEach(0..<5, id: \.self) { index in
                let angle = Double(index) * .pi * 2 / 5
                Image(systemName: "sparkle").font(.system(size: 10, weight: .bold))
                    .foregroundStyle(index.isMultiple(of: 2) ? DNACopyStyle.teal : DNACopyStyle.rna)
                    .offset(x: CGFloat(cos(angle)) * (expanded ? 34 : 15), y: CGFloat(sin(angle)) * (expanded ? 34 : 15))
            }
        }
        .frame(width: 44, height: 44)
        .opacity(expanded ? 0 : 1)
        .task {
            if reduceMotion { expanded = true }
            else { withAnimation(.easeOut(duration: 0.6)) { expanded = true } }
        }
    }
}

enum DNACopyBoardLayout {
    static func screen(_ point: CGPoint, width: CGFloat) -> CGPoint {
        CGPoint(x: point.x * width / 360, y: (point.y - 40) * width / 360)
    }
    static func nearestTarget(to location: CGPoint, targets: [DNACopyTarget], width: CGFloat) -> DNACopyTarget? {
        let distances = targets.map { target -> (DNACopyTarget, CGFloat) in
            let center = screen(point(target), width: width)
            let dx = location.x - center.x, dy = location.y - center.y
            return (target, (dx * dx + dy * dy).squareRoot())
        }
        guard let nearest = distances.min(by: { $0.1 < $1.1 }), nearest.1 <= 40 else { return nil }
        return nearest.0
    }
    static func rowY(_ row: Int) -> CGFloat { 172 + CGFloat(row) * 31 }
    static func newX(_ lane: DNACopyLane) -> CGFloat { lane == .leading ? 145 : 215 }
    static func point(_ target: DNACopyTarget) -> CGPoint {
        switch target {
        case let .origin(index): return CGPoint(x: 100 + index * 80, y: 270)
        case .helicase: return CGPoint(x: 180, y: 396)
        case let .binding(index): return [CGPoint(x: 80, y: 222), CGPoint(x: 280, y: 293), CGPoint(x: 80, y: 355)][index]
        case let .primer(lane, fragment):
            let start = lane == .leading ? 0 : fragment * 4
            return CGPoint(x: newX(lane), y: (rowY(DNACopySequence.row(lane: lane, index: start)) + rowY(DNACopySequence.row(lane: lane, index: start + 1))) / 2)
        case let .load(lane, fragment):
            let index = lane == .leading ? 1 : fragment * 4 + 1
            return CGPoint(x: newX(lane), y: rowY(DNACopySequence.row(lane: lane, index: index)) + (lane == .leading ? -15 : 15))
        case let .base(lane, index): return CGPoint(x: newX(lane), y: rowY(DNACopySequence.row(lane: lane, index: index)))
        case .mismatch: return point(.base(.leading, 4))
        case .remove: return CGPoint(x: 180, y: 295)
        case let .replacement(_, index): return CGPoint(x: 165 + index * 30, y: 295)
        case .nick: return CGPoint(x: 210, y: 314)
        }
    }
    static func poolAnchor(_ index: Int, stage: DNACopyStage) -> CGPoint {
        let points: [CGPoint] = stage == .replace ?
            [CGPoint(x: 65, y: 175), CGPoint(x: 75, y: 375), CGPoint(x: 295, y: 175), CGPoint(x: 285, y: 375)] :
            [CGPoint(x: 60, y: 175), CGPoint(x: 42, y: 249), CGPoint(x: 44, y: 323), CGPoint(x: 126, y: 95),
             CGPoint(x: 300, y: 175), CGPoint(x: 318, y: 249), CGPoint(x: 316, y: 323), CGPoint(x: 234, y: 95)]
        return points[index]
    }
    static func pool(_ index: Int, time: Double, stage: DNACopyStage = .leading) -> CGPoint {
        let origin = poolAnchor(index, stage: stage)
        let phase = Double(index) * 1.7
        return CGPoint(x: origin.x + sin(time * 0.65 + phase) * 2.5,
                       y: origin.y + cos(time * 0.5 + phase) * 3)
    }
}

// Read observable state while building the View, then paint an immutable snapshot.
private struct DNACopyBoardState {
    let stage: DNACopyStage
    let origin: Int?
    let bindingSites: Set<Int>
    let leadingPrimed: Bool
    let leading: [DNACopyBase?]
    let lagging: [DNACopyBase?]
    let leadingDNA: [DNACopyBase?]
    let laggingDNA: [DNACopyBase?]
    let laggingPrimed: Set<Int>
    let fragment: Int
    let mismatch: Bool
    let mismatchRemoved: Bool
    let focus: DNACopySite
    let removed: Set<DNACopySite>
    let replacements: [DNACopySite: [DNACopyBase?]]
    let sealed: Set<DNACopySite>
    let active: DNACopyTarget?
    @MainActor init(_ session: DNACopySession) {
        stage = session.stage; origin = session.origin; bindingSites = session.bindingSites
        leadingPrimed = session.leadingPrimed; leading = session.leading
        lagging = session.lagging; laggingPrimed = session.laggingPrimed
        leadingDNA = (0..<DNACopySequence.count).map { session.synthesizedBase(lane: .leading, index: $0) }
        laggingDNA = (0..<DNACopySequence.count).map { session.synthesizedBase(lane: .lagging, index: $0) }
        fragment = session.fragment; mismatch = session.correctingMismatch
        mismatchRemoved = session.mismatchRemoved
        focus = session.activeSite ?? .laggingTwo
        removed = session.removedPrimers; replacements = session.replacements
        sealed = session.sealed; active = session.activeTarget
    }
}

private struct DNACopyMolecularCanvas: View, Animatable {
    let state: DNACopyBoardState
    var openFraction: Double
    var animatableData: Double {
        get { openFraction }
        set { openFraction = newValue }
    }
    var body: some View {
        Canvas { context, size in
            var drawing = context
            drawing.scaleBy(x: size.width / 360, y: size.height / 460)
            DNACopyPainter(context: drawing, state: state, open: CGFloat(openFraction)).draw()
        }
    }
}

private struct DNACopyPainter {
    let context: GraphicsContext
    let state: DNACopyBoardState
    let open: CGFloat
    private let ink = DNACopyStyle.ink
    private let edge = DNACopyStyle.edge
    private let old = DNACopyStyle.parental
    private let new = DNACopyStyle.newDNA
    private let rna = DNACopyStyle.rna

    func draw() {
        let nucleus = Path(ellipseIn: CGRect(x: 8, y: 8, width: 344, height: 438))
        context.fill(nucleus, with: .linearGradient(Gradient(colors: [DNACopyStyle.peach.opacity(0.7), DNACopyStyle.lavender.opacity(0.8)]),
                                                   startPoint: CGPoint(x: 40, y: 50), endPoint: CGPoint(x: 310, y: 470)))
        context.stroke(nucleus, with: .color(edge), lineWidth: 1.8)
        context.stroke(Path(ellipseIn: CGRect(x: 14, y: 15, width: 332, height: 423)), with: .color(.white.opacity(0.65)), lineWidth: 2)
        text("NUCLEUS", 180, 432, 9, color: DNACopyStyle.muted)
        var molecular = context
        molecular.translateBy(x: 0, y: -40)
        let scene = DNACopyPainter(context: molecular, state: state, open: open)
        switch state.stage {
        case .origin: scene.origins()
        case .remove, .replace, .seal: scene.junction()
        case .complete: scene.result()
        default: scene.fork()
        }
    }
    private func line(_ a: CGPoint, _ b: CGPoint, _ color: Color, _ width: CGFloat = 2, dash: [CGFloat] = []) {
        var path = Path(); path.move(to: a); path.addLine(to: b)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
    }
    private func segment(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ color: Color, _ width: CGFloat = 2, dash: [CGFloat] = []) {
        line(CGPoint(x: x1, y: y1), CGPoint(x: x2, y: y2), color, width, dash: dash)
    }
    private func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 12,
                      color: Color = DNACopyStyle.ink, weight: Font.Weight = .bold) {
        context.draw(Text(value).font(.system(size: size, weight: weight, design: .rounded)).foregroundColor(color), at: CGPoint(x: x, y: y))
    }
    private func pill(_ value: String, _ x: CGFloat, _ y: CGFloat, _ fill: Color = DNACopyStyle.paper, _ size: CGFloat = 11) {
        let label = context.resolve(Text(value).font(.system(size: size, weight: .bold, design: .rounded)).foregroundColor(ink))
        let width = label.measure(in: CGSize(width: 320, height: 44)).width + 20
        let rect = Path(roundedRect: CGRect(x: x - width / 2, y: y - 12, width: width, height: 24), cornerRadius: 12)
        context.fill(rect, with: .color(fill)); context.draw(label, at: CGPoint(x: x, y: y))
    }
    private func circle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ fill: Color, _ border: Color = DNACopyStyle.edge) {
        let p = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        context.fill(p, with: .color(fill)); context.stroke(p, with: .color(border), lineWidth: 0.9)
    }
    private func sugar(_ x: CGFloat, _ y: CGFloat, _ color: Color) {
        var p = Path()
        for i in 0..<5 {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * 2 * .pi / 5
            let pt = CGPoint(x: x + cos(angle) * 4.2, y: y + sin(angle) * 4.2)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath(); context.fill(p, with: .color(color)); context.stroke(p, with: .color(ink), lineWidth: 0.8)
    }
    private func base(_ value: DNACopyBase?, _ x: CGFloat, _ y: CGFloat, isRNA: Bool = false,
                      error: Bool = false, size: CGFloat = 20) {
        let rect = Path(roundedRect: CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size), cornerRadius: 5)
        let fill = isRNA ? DNACopyStyle.butter : value.map(DNACopyStyle.base) ?? DNACopyStyle.paper.opacity(0.2)
        context.fill(rect, with: .color(error ? DNACopyStyle.error.opacity(0.18) : fill))
        context.stroke(rect, with: .color(error ? DNACopyStyle.error : edge.opacity(value == nil && !isRNA ? 0.3 : 1)),
                       style: StrokeStyle(lineWidth: error ? 2 : 0.9, dash: value == nil && !isRNA ? [2, 3] : []))
        if isRNA {
            segment(x - 5, y, x + 5, y, rna, 3)
        } else if let value { text(value.rawValue, x, y, min(12, size * 0.6), color: error ? DNACopyStyle.error : ink, weight: .heavy) }
    }
    private func arrow(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ color: Color) {
        segment(x1, y1, x2, y2, color, 2)
        let angle = atan2(y2 - y1, x2 - x1)
        for sign in [-1.0, 1.0] {
            segment(x2, y2, x2 - 7 * cos(angle + CGFloat(sign) * 0.55), y2 - 7 * sin(angle + CGFloat(sign) * 0.55), color, 2)
        }
    }
    private func icon(_ asset: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat) {
        context.draw(context.resolve(Image(asset)), in: CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size))
    }
    private func origins() {
        pill("One short chromosome section", 180, 118, DNACopyStyle.paper)
        segment(64, 245, 296, 245, old, 4); segment(64, 295, 296, 295, old, 4)
        for index in 0..<8 {
            let x = CGFloat(75 + index * 30)
            let value = DNACopySequence.parentalBase(atRow: index)
            sugar(x, 245, old); sugar(x, 295, old)
            segment(x, 245, x, 256, old); segment(x, 284, x, 295, old)
            base(value, x, 257); base(value.complement, x, 283)
            segment(x, 268, x, 272, edge, 1, dash: [1, 2])
        }
        text("5′", 55, 230, 13, color: old); text("3′", 305, 230, 13, color: old)
        text("3′", 55, 313, 13, color: old); text("5′", 305, 313, 13, color: old)
        pill("Origins of replication", 180, 368, DNACopyStyle.butter)
        for i in 0..<3 {
            let x = CGFloat(100 + i * 80)
            circle(x, 270, state.origin == i ? 15 : 9, DNACopyStyle.butter)
            segment(x, 286, x, 350, edge.opacity(0.6), 1, dash: [3, 4])
        }
        text("Many starting sites. One mission here.", 180, 430, 11, weight: .medium)
    }
    private func fork() {
        if state.stage == .unwind { unzip(); return }
        let fraction = min(max(open, 0), 1)
        let left = 168 - 74 * fraction, right = 192 + 74 * fraction
        for (start, end) in [(CGFloat(168), left), (CGFloat(192), right)] {
            var path = Path(); path.move(to: CGPoint(x: start, y: 63)); path.addLine(to: CGPoint(x: start, y: 102))
            path.addCurve(to: CGPoint(x: end, y: 163), control1: CGPoint(x: start, y: 130), control2: CGPoint(x: end, y: 132))
            path.addLine(to: CGPoint(x: end, y: 408))
            context.stroke(path, with: .color(old), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }
        for y in stride(from: CGFloat(72), through: 99, by: 12) {
            segment(169, y, 191, y, edge, 1, dash: [2, 2])
        }
        for row in 0..<8 {
            let y = DNACopyBoardLayout.rowY(row)
            let value = DNACopySequence.parentalBase(atRow: row)
            if fraction < 0.98 {
                segment(left, y, right, y, edge.opacity(Double(1 - fraction)), 1, dash: [2, 2])
            }
            if fraction > 0.75 {
                sugar(left, y, old); sugar(right, y, old)
                circle(left, y + 15.5, 2.7, DNACopyStyle.butter); circle(right, y + 15.5, 2.7, DNACopyStyle.butter)
                segment(left, y, left + 15, y, old, 1); segment(right, y, right - 15, y, old, 1)
                base(value, left + 15, y); base(value.complement, right - 15, y)
            }
        }
        if fraction < 0.98 {
            pill("Hydrogen bonds hold base pairs together", 180, 440, DNACopyStyle.paper, 10)
            text("5′", 157, 54, 12, color: old); text("3′", 203, 54, 12, color: old)
            text("3′", 155, 425, 12, color: old); text("5′", 205, 425, 12, color: old)
            return
        }
        icon("DNAHelicaseZipper", 180, 121, 51)
        text("FORK", 186, 152, 8, color: DNACopyStyle.muted)
        text("LEADING", 119, 139, 10); text("LAGGING", 243, 139, 10)
        text("5′", 97, 149, 12, color: old); text("3′", 263, 149, 12, color: old)
        text("3′", 95, 424, 12, color: old); text("5′", 265, 424, 12, color: old)
        for site in state.bindingSites {
            let point = DNACopyBoardLayout.point(.binding(site))
            segment(point.x, point.y, point.x < 180 ? 94 : 266, point.y, edge, 1)
            for offset in [-5.0, 4.0] { circle(point.x + offset, point.y, 6, DNACopyStyle.sage) }
            circle(point.x, point.y - 5, 5, DNACopyStyle.sage)
        }
        newStrand(.leading); newStrand(.lagging)
        if state.stage == .leading {
            arrow(77, 346, 77, 229, new)
            pill("Leading · continuous", 180, 454, DNACopyStyle.paper)
        } else if state.stage == .lagging {
            arrow(283, 229, 283, 346, new)
            pill("Lagging · short Okazaki fragments", 180, 454, DNACopyStyle.paper, 10)
        } else if state.stage == .prime {
            pill("RNA primer = starting block", 180, 454, DNACopyStyle.butter, 10)
        } else { pill("Separated DNA templates", 180, 454, DNACopyStyle.paper) }
        if state.stage == .leading || state.stage == .lagging { text("New DNA always grows 5′ → 3′", 180, 437, 10, color: DNACopyStyle.muted) }
    }

    private func unzip() {
        let geometry = DNAUnzipGeometry(progress: Double(open), openLeft: 94, openRight: 266,
                                        startY: 390, endY: 110, spread: 64)
        for left in [true, false] {
            var backbone = Path()
            for y in stride(from: CGFloat(63), through: 408, by: 2) {
                let point = CGPoint(x: geometry.strandX(left: left, at: y), y: y)
                if y == 63 { backbone.move(to: point) } else { backbone.addLine(to: point) }
            }
            context.stroke(backbone, with: .color(old), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }
        for row in 0..<8 {
            let y = DNACopyBoardLayout.rowY(row)
            let left = geometry.strandX(left: true, at: y)
            let right = geometry.strandX(left: false, at: y)
            let separated = geometry.separation(at: y)
            let size = 12 + separated * 8
            let value = DNACopySequence.parentalBase(atRow: row)
            sugar(left, y, old); sugar(right, y, old)
            segment(left, y, left + 15, y, old, 1)
            segment(right, y, right - 15, y, old, 1)
            base(value, left + 15, y, size: size)
            base(value.complement, right - 15, y, size: size)
            if separated < 0.35 {
                segment(left + 22, y, right - 22, y,
                        edge.opacity(Double(1 - separated / 0.35)), 1, dash: [2, 2])
            }
            circle(left, y + 15.5, 2.7, DNACopyStyle.butter)
            circle(right, y + 15.5, 2.7, DNACopyStyle.butter)
        }
        let actor = geometry.helicase
        icon("DNAHelicaseZipper", actor.x, actor.y, 80)
        text("5′", 145, 54, 12, color: old); text("3′", 215, 54, 12, color: old)
        text("3′", geometry.strandX(left: true, at: 408), 430, 12, color: old)
        text("5′", geometry.strandX(left: false, at: 408), 430, 12, color: old)
        pill("Helicase opens the base pairs", 180, 454, DNACopyStyle.paper, 10)
    }
    private func newStrand(_ lane: DNACopyLane) {
        let chainX: CGFloat = lane == .leading ? 160 : 200
        let baseX = DNACopyBoardLayout.newX(lane)
        let templateX: CGFloat = lane == .leading ? 109 : 251
        let values = lane == .leading ? state.leading : state.lagging
        let groups = lane == .leading ? 1 : 2
        for group in 0..<groups {
            let primed = lane == .leading ? state.leadingPrimed : state.laggingPrimed.contains(group)
            let range = lane == .leading ? Array(0..<8) : Array(group * 4..<group * 4 + 4)
            var previous: Int?
            var visible: [Int] = []
            for index in range {
                let isPrimer = lane == .leading ? index < 2 : index % 4 < 2
                let has = (isPrimer && primed) || values[index] != nil
                let y = DNACopyBoardLayout.rowY(DNACopySequence.row(lane: lane, index: index))
                if has {
                    visible.append(index)
                    let color = isPrimer ? rna : new
                    if let previous {
                        let lastY = DNACopyBoardLayout.rowY(DNACopySequence.row(lane: lane, index: previous))
                        segment(chainX, lastY, chainX, y, color, 3)
                    }
                    sugar(chainX, y, color); circle(chainX, y + (lane == .leading ? -15.5 : 15.5), 2.5, DNACopyStyle.butter)
                    segment(chainX, y, baseX, y, color, 1)
                    let error = lane == .leading && index == 4 && state.mismatch && !state.mismatchRemoved
                    base(values[index], baseX, y, isRNA: isPrimer, error: error)
                    segment(min(baseX, templateX) + 11, y, max(baseX, templateX) - 11, y, error ? DNACopyStyle.error : edge, 1, dash: [1, 2])
                    previous = index
                } else if (lane == .leading && state.leadingPrimed) || (lane == .lagging && state.stage == .lagging) {
                    base(nil, baseX, y)
                }
            }
            if let first = visible.first, let last = visible.last {
                let startY = DNACopyBoardLayout.rowY(DNACopySequence.row(lane: lane, index: first))
                let endY = DNACopyBoardLayout.rowY(DNACopySequence.row(lane: lane, index: last))
                // Only the active lagging fragment gets end labels while it grows.
                if lane == .leading || group == min(state.fragment, 1) {
                    text("5′", chainX + (lane == .leading ? 0 : 8), startY + (lane == .leading ? 23 : -25), 10, color: new)
                    let activeLane: DNACopyLane = state.stage == .lagging ? .lagging : .leading
                    if lane == activeLane {
                        text("3′", lane == .leading ? 183 : 177, endY + (lane == .leading ? -6 : 6), 10, color: new)
                    }
                }
            }
        }
    }
    private func junction() {
        let site = state.focus
        pill(site.title, 180, 111, DNACopyStyle.paper)
        text("INTERNAL PRIMER SITE · ZOOM", 180, 149, 10, color: DNACopyStyle.muted)
        let template = [DNACopyBase.g, .t, .a] + (0..<2).map { DNACopySequence.replacementTemplate(site: site, index: $0) } + [.g, .c, .t]
        let primerPresent = !state.removed.contains(site)
        let replacements = state.replacements[site] ?? [nil, nil]
        segment(65, 242, 295, 242, old, 3.5)
        segment(65, 314, 135, 314, new, 3.5); segment(225, 314, 295, 314, new, 3.5)
        if primerPresent {
            segment(165, 314, 195, 314, rna, 4); segment(195, 314, 225, 314, new, 3.5)
        } else {
            if replacements[0] != nil { segment(135, 314, 165, 314, new, 3.5) }
            if replacements[1] != nil { segment(165, 314, 195, 314, new, 3.5) }
            if state.sealed.contains(site) { segment(195, 314, 225, 314, new, 3.5) }
        }
        for index in 0..<8 {
            let x = CGFloat(75 + index * 30)
            sugar(x, 242, old); segment(x, 242, x, 253, old, 1); base(template[index], x, 259)
            if index < 3 || index > 4 {
                sugar(x, 314, new); segment(x, 305, x, 314, new, 1); base(template[index].complement, x, 295)
                segment(x, 270, x, 283, edge, 1, dash: [2, 3])
            } else if primerPresent {
                sugar(x, 314, rna); segment(x, 305, x, 314, rna, 1); base(nil, x, 295, isRNA: true)
                segment(x, 270, x, 283, edge, 1, dash: [2, 3])
            } else if let value = replacements[index - 3] {
                sugar(x, 314, new); segment(x, 305, x, 314, new, 1); base(value, x, 295)
                segment(x, 270, x, 283, edge, 1, dash: [2, 3])
            } else { base(nil, x, 295) }
        }
        text("3′", 64, 220, 13, color: old); text("5′", 296, 220, 13, color: old)
        text("5′", 64, 341, 13, color: new); text("3′", 296, 341, 13, color: new)
        text("Template DNA", 180, 201, 11, color: old)
        if state.stage == .remove { pill("Temporary RNA primer", 180, 369, DNACopyStyle.butter) }
        if state.stage == .replace {
            let next = replacements.firstIndex(where: { $0 == nil }) ?? 2
            text("3′ end", 136 + CGFloat(next) * 30, 342, 10, color: DNACopyStyle.teal)
            arrow(110, 374, 245, 374, new)
            text("DNA polymerase fills 5′ → 3′", 180, 410, 11)
            text("Extend from neighboring DNA", 180, 435, 10, color: DNACopyStyle.muted)
        } else if state.stage == .seal {
            if state.sealed.contains(site) {
                pill("Covalent bond sealed", 180, 366, DNACopyStyle.sage)
            } else {
                circle(210, 314, 12, DNACopyStyle.paper.opacity(0.2), DNACopyStyle.teal)
                pill("Nick in the backbone", 180, 366, DNACopyStyle.butter)
            }
            icon("DNALigaseGlue", 180, 422, 53)
        }
        text("Parental DNA stays intact", 180, 460, 10, color: DNACopyStyle.muted)
    }
    private func result() {
        pill("SEMICONSERVATIVE", 180, 123, DNACopyStyle.sage)
        for copy in 0..<2 {
            let center = CGFloat(copy == 0 ? 108 : 252)
            let leftColor = copy == 0 ? old : new, rightColor = copy == 0 ? new : old
            segment(center - 21, 205, center - 21, 369, leftColor, 4)
            segment(center + 21, 205, center + 21, 369, rightColor, 4)
            for i in 0..<DNACopySequence.count {
                let y = CGFloat(205 + i * 23)
                let b = DNACopySequence.parentalBase(atRow: i)
                sugar(center - 21, y, leftColor); sugar(center + 21, y, rightColor)
                if copy == 0 {
                    base(b, center - 10, y)
                    base(state.leadingDNA[DNACopySequence.index(lane: .leading, row: i)], center + 10, y)
                } else {
                    base(state.laggingDNA[DNACopySequence.index(lane: .lagging, row: i)], center - 10, y)
                    base(b.complement, center + 10, y)
                }
            }
            text("5′", center - 24, 188, 11, color: leftColor); text("3′", center + 24, 188, 11, color: rightColor)
            text("3′", center - 24, 389, 11, color: leftColor); text("5′", center + 24, 389, 11, color: rightColor)
            text("COPY \(copy + 1)", center, 419, 10)
        }
        text("One parental + one new", 180, 441, 11)
        text("strand in each copy", 180, 456, 11)
    }
}
