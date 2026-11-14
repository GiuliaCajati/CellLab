// CellStructuresAtlas.swift — shaded artwork plus ONE coordinate-based UIKit tap surface.
import SwiftUI
import UIKit

struct CSAtlas: View {
    let kind: CSCellKind
    let selected: CSPart
    let time: Double
    let onSelect: (CSPart) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CSAtlasArt(selected: selected, time: time)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                CSAtlasTouchSurface(selected: selected, onSelect: onSelect)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(400.0 / 340, contentMode: .fit)
        .accessibilityIdentifier("structures-cell-image")
    }
}

struct CSAtlasTouchSurface: UIViewRepresentable {
    let selected: CSPart
    let onSelect: (CSPart) -> Void

    func makeUIView(context: Context) -> CSAtlasTouchView {
        let view = CSAtlasTouchView()
        view.configure(selected: selected, onSelect: onSelect)
        return view
    }
    func updateUIView(_ view: CSAtlasTouchView, context: Context) {
        view.configure(selected: selected, onSelect: onSelect)
    }
}

// A single tap recognizer avoids full-size transparent buttons obscuring one another.
// A drag belongs to the surrounding ScrollView; only completed taps select a part.
final class CSAtlasTouchView: UIView {
    private(set) var selected: CSPart = .nucleus
    private var onSelect: (CSPart) -> Void = { _ in }
    private var lastAccessibleSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = true
        isAccessibilityElement = false
        accessibilityIdentifier = "structures-cell-touch-surface"
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        recognizer.cancelsTouchesInView = false
        addGestureRecognizer(recognizer)
    }
    required init?(coder: NSCoder) { fatalError("Use the programmatic initializer.") }

    func configure(selected: CSPart, onSelect: @escaping (CSPart) -> Void) {
        let changed = self.selected != selected
        self.selected = selected
        self.onSelect = onSelect
        if changed || accessibilityElements == nil { rebuildAccessibility() }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != lastAccessibleSize { rebuildAccessibility() }
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        CSLayout.hitTest(point, in: bounds.size, selected: selected) != nil
    }
    @objc private func didTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended,
              let part = CSLayout.hitTest(recognizer.location(in: self), in: bounds.size, selected: selected) else { return }
        activate(part)
    }
    func activate(_ part: CSPart) { onSelect(part) }

    private func rebuildAccessibility() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        lastAccessibleSize = bounds.size
        let sx = bounds.width / 400, sy = bounds.height / 340
        var elements: [UIAccessibilityElement] = []
        for part in CSPart.allCases {
            let source: CGRect
            if let placement = CSLayout.all.first(where: { $0.part == part }) {
                source = placement.rect
            } else if part == .membrane {
                source = CGRect(x: 337, y: 142, width: 39, height: 60)
            } else {
                source = CGRect(x: 107, y: 256, width: 50, height: 43)
            }
            let element = CSAtlasAccessiblePart(accessibilityContainer: self)
            element.owner = self
            element.part = part
            element.accessibilityLabel = part.content.title
            element.accessibilityHint = "Double-tap to show its explanation under Parts of the cell."
            element.accessibilityValue = selected == part ? "Selected" : nil
            element.accessibilityTraits = selected == part ? [.button, .selected] : .button
            let width = max(44, source.width * sx), height = max(44, source.height * sy)
            element.accessibilityFrameInContainerSpace = CGRect(x: source.midX * sx - width / 2,
                                                                y: source.midY * sy - height / 2,
                                                                width: width, height: height)
            elements.append(element)
        }
        accessibilityElements = elements
    }
}

private final class CSAtlasAccessiblePart: UIAccessibilityElement {
    weak var owner: CSAtlasTouchView?
    var part: CSPart = .nucleus
    override func accessibilityActivate() -> Bool {
        guard let owner else { return false }
        owner.activate(part)
        return true
    }
}

private struct CSAtlasArt: View {
    let selected: CSPart
    let time: Double

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 400, y: size.height / 340)
            let outer = CSLayout.cellPath()
            var shadow = context
            shadow.addFilter(.shadow(color: CSPalette.ink.opacity(0.13), radius: 6, x: 0, y: 4))
            shadow.fill(outer, with: .color(Color(csHex: 0xB5D1B3)))
            context.fill(outer, with: .linearGradient(
                Gradient(colors: [Color(csHex: 0xCEE2BE), Color(csHex: 0x91BDA8)]),
                startPoint: CGPoint(x: 40, y: 40), endPoint: CGPoint(x: 330, y: 320)))
            context.stroke(outer, with: .color(CSPalette.ink.opacity(0.9)), lineWidth: 2.5)
            let inner = CSLayout.cellPath(inset: 8)
            context.fill(inner, with: .radialGradient(
                Gradient(colors: [Color(csHex: 0xF4F4DF), Color(csHex: 0xE5EDD5), Color(csHex: 0xCBDDC2)]),
                center: CGPoint(x: 142, y: 108), startRadius: 12, endRadius: 290))
            context.stroke(inner, with: .color(Color.white.opacity(0.7)), lineWidth: 2)
            context.stroke(CSLayout.cellPath(inset: 11), with: .color(CSPalette.teal.opacity(0.22)), lineWidth: 1)

            if selected == .membrane || selected == .cytoplasm {
                context.stroke(outer, with: .color(CSPalette.teal),
                               style: StrokeStyle(lineWidth: 3.5, dash: selected == .cytoplasm ? [4, 5] : []))
            }
            var fluid = context
            fluid.clip(to: CSLayout.cellPath(inset: 13))
            for i in 0..<34 {
                let x = CGFloat(43 + (i * 73) % 312) + CGFloat(sin(time * 0.3 + Double(i))) * 1.5
                let y = CGFloat(60 + (i * i * 47) % 235) + CGFloat(cos(time * 0.3 + Double(i))) * 1.5
                CSActiveDrawing.dot(&fluid, x, y, 1.4, CSPalette.teal.opacity(0.17), outline: false)
            }
            for placement in CSLayout.placements(selected: selected) {
                if selected == placement.part {
                    let halo = Path(ellipseIn: placement.rect.insetBy(dx: -5, dy: -5))
                    context.fill(halo, with: .color(CSPalette.paper.opacity(0.66)))
                    context.stroke(halo, with: .color(CSPalette.teal), style: StrokeStyle(lineWidth: 1.7, dash: [3, 3]))
                    CSActiveDrawing.draw(placement.part, kind: .animal, time: time, context: &context, rect: placement.rect)
                } else {
                    CSVector.draw(placement.part, in: &context, rect: placement.rect)
                }
            }
            if [CSPart.vesicles, .golgi, .roughER].contains(selected) { cargoRoute(&context) }
            if selected == .membrane {
                let p = CGFloat(time.truncatingRemainder(dividingBy: 6) / 6)
                CSActiveDrawing.dot(&context, 386 - p * 48, 177, 4, Color(csHex: 0xC8E7EF))
            }
        }
    }
    private func cargoRoute(_ c: inout GraphicsContext) {
        let route = [CGPoint(x: 263, y: 162), CGPoint(x: 318, y: 209), CGPoint(x: 363, y: 226)]
        CSActiveDrawing.line(&c, route, color: CSPalette.teal.opacity(0.65), width: 1.5, dash: [3, 4])
        let progress = CGFloat(time.truncatingRemainder(dividingBy: 6) / 6) * 2
        let index = min(1, Int(progress)), q = progress - CGFloat(min(1, Int(progress)))
        let a = route[index], b = route[index + 1]
        let point = CGPoint(x: a.x + (b.x - a.x) * q, y: a.y + (b.y - a.y) * q)
        CSActiveDrawing.dot(&c, point.x, point.y, 8, Color(csHex: 0xC8E7EF))
        CSActiveDrawing.dot(&c, point.x, point.y, 3, Color(csHex: 0xF3C9B5))
    }
}
