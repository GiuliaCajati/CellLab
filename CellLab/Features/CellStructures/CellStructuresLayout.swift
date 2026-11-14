// CellStructuresLayout.swift — one animal-cell coordinate system for artwork and taps.
import SwiftUI

struct CSPlacement: Identifiable, Sendable {
    let part: CSPart
    let rect: CGRect
    let index: Int
    var id: Int { index }
    init(_ part: CSPart, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ index: Int) {
        self.part = part; rect = CGRect(x: x, y: y, width: w, height: h); self.index = index
    }
    func containsArtwork(_ point: CGPoint) -> Bool {
        if [CSPart.nucleus, .nucleolus, .mitochondria, .lysosomes, .peroxisomes, .vesicles].contains(part) {
            return CSLayout.ellipseContains(point, rect: rect)
        }
        return rect.contains(point)
    }
}

enum CSLayout {
    static let referenceSize = CGSize(width: 400, height: 340)
    static let all: [CSPlacement] = [
        .init(.nucleus, 93, 108, 121, 112, 0),
        .init(.roughER, 191, 116, 96, 90, 1),
        .init(.smoothER, 241, 71, 77, 66, 2),
        .init(.golgi, 282, 170, 61, 76, 3),
        .init(.mitochondria, 69, 72, 75, 47, 4),
        .init(.mitochondria, 80, 232, 81, 51, 5),
        .init(.peroxisomes, 49, 159, 42, 42, 6),
        .init(.lysosomes, 230, 222, 45, 45, 7),
        .init(.centrosome, 209, 51, 49, 43, 8),
        .init(.ribosomes, 183, 242, 44, 37, 9),
        .init(.vesicles, 307, 247, 32, 32, 10),
        .init(.cytoskeleton, 52, 207, 53, 28, 11),
        .init(.microfilaments, 148, 284, 48, 15, 12),
        .init(.intermediateFilaments, 171, 77, 47, 19, 13),
        .init(.microtubules, 230, 280, 56, 17, 14),
        .init(.nucleolus, 132, 143, 35, 35, 15),
        .init(.cilia, 139, 12, 101, 54, 16),
        .init(.flagellum, 341, 131, 56, 69, 17)
    ]
    static func placements(_ kind: CSCellKind = .animal, selected: CSPart) -> [CSPlacement] {
        all.filter { ![CSPart.cilia, .flagellum].contains($0.part) || $0.part == selected }
    }
    static func ellipseContains(_ point: CGPoint, rect: CGRect) -> Bool {
        guard rect.width > 0, rect.height > 0 else { return false }
        let x = (point.x - rect.midX) / (rect.width / 2)
        let y = (point.y - rect.midY) / (rect.height / 2)
        return x * x + y * y <= 1
    }
    static func cellPath(_ kind: CSCellKind = .animal, inset: CGFloat = 0) -> Path {
        let base = Path { p in
            p.move(to: CGPoint(x: 57, y: 83))
            p.addCurve(to: CGPoint(x: 282, y: 49), control1: CGPoint(x: 99, y: 24), control2: CGPoint(x: 220, y: 30))
            p.addCurve(to: CGPoint(x: 372, y: 201), control1: CGPoint(x: 357, y: 60), control2: CGPoint(x: 377, y: 130))
            p.addCurve(to: CGPoint(x: 228, y: 313), control1: CGPoint(x: 370, y: 280), control2: CGPoint(x: 306, y: 318))
            p.addCurve(to: CGPoint(x: 29, y: 194), control1: CGPoint(x: 123, y: 333), control2: CGPoint(x: 12, y: 277))
            p.addCurve(to: CGPoint(x: 57, y: 83), control1: CGPoint(x: 24, y: 149), control2: CGPoint(x: 31, y: 115))
            p.closeSubpath()
        }
        let bounds = base.boundingRect
        let sx = max(0.05, (bounds.width - 2 * inset) / bounds.width)
        let sy = max(0.05, (bounds.height - 2 * inset) / bounds.height)
        return base.applying(CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY))
            .applying(CGAffineTransform(scaleX: sx, y: sy))
            .applying(CGAffineTransform(translationX: bounds.midX, y: bounds.midY))
    }

    /// Converts the actual touch-view size to the exact 400 × 340 artwork space.
    /// Actual organelle artwork wins before enlarged targets or cytoplasm.
    static func hitTest(_ point: CGPoint, in size: CGSize, selected: CSPart) -> CSPart? {
        guard size.width > 0, size.height > 0,
              CGRect(origin: .zero, size: size).contains(point) else { return nil }
        let p = CGPoint(x: point.x * 400 / size.width, y: point.y * 340 / size.height)
        let visible = placements(selected: selected)
        for placement in visible.reversed() where placement.containsArtwork(p) {
            return placement.part
        }
        let outer = cellPath()
        if outer.contains(p) && !cellPath(inset: 12).contains(p) { return .membrane }

        let minimum = CGSize(width: 44 * 400 / size.width, height: 44 * 340 / size.height)
        let nearby = visible.filter { placement in
            let r = placement.rect
            let expanded = CGRect(x: r.midX - max(r.width, minimum.width) / 2,
                                  y: r.midY - max(r.height, minimum.height) / 2,
                                  width: max(r.width, minimum.width), height: max(r.height, minimum.height))
            return ellipseContains(p, rect: expanded)
        }
        if let nearest = nearby.min(by: { a, b in
            hypot(p.x - a.rect.midX, p.y - a.rect.midY) < hypot(p.x - b.rect.midX, p.y - b.rect.midY)
        }) { return nearest.part }
        return outer.contains(p) ? .cytoplasm : nil
    }
}
