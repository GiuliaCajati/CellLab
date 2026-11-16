// RespirationDiagram.swift — precise schematic diagrams shared with the offline preview.
// Text, arrows, and molecular totals are authored together in Tools/Diagrams.cjs.
import SwiftUI
import UIKit

@MainActor struct RespirationScene: View, Equatable {
    let step: RespirationStep
    let progress: Double
    var background: Color = RespirationTheme.paper
    var illustrationID: String? = nil

    var body: some View {
        let timeline = RespirationTimelineStore.shared.timeline(for: step, illustrationID: illustrationID)
        Canvas { context, size in
            guard let timeline, !timeline.frames.isEmpty else { return }
            let p = min(max(progress.isFinite ? progress : 1, 0), 1)
            let index = Int((p * Double(timeline.frames.count - 1)).rounded())
            let inset = min(size.width / timeline.width, size.height / timeline.height) * 14
            let scale = max(0, min((size.width - inset * 2) / timeline.width,
                                   (size.height - inset * 2) / timeline.height))
            var drawing = context
            drawing.translateBy(x: (size.width - timeline.width * scale) / 2,
                                y: (size.height - timeline.height * scale) / 2)
            drawing.scaleBy(x: scale, y: scale)
            for command in timeline.frames[index] { command.draw(in: drawing) }
        }
        .background(background)
        .overlay {
            if timeline == nil {
                ContentUnavailableView("Diagram unavailable", systemImage: "photo")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(step.content.accessibility)
        .accessibilityIdentifier("respiration-diagram")
    }
}

private struct RespirationTimeline: Decodable, Sendable {
    let width, height: CGFloat
    let frames: [[RespirationDrawCommand]]
}

private final class RespirationTimelineBox {
    let value: RespirationTimeline
    init(_ value: RespirationTimeline) { self.value = value }
}

@MainActor private final class RespirationTimelineStore {
    static let shared = RespirationTimelineStore()
    private let cache = NSCache<NSString, RespirationTimelineBox>()

    private init() { cache.countLimit = 24 }

    func timeline(for step: RespirationStep, illustrationID: String?) -> RespirationTimeline? {
        let name = illustrationID.map { "Respiration_Player_" + $0 } ?? ("Respiration_" + step.rawValue)
        let key = name as NSString
        if let box = cache.object(forKey: key) { return box.value }
        guard let asset = NSDataAsset(name: name),
              let timeline = try? JSONDecoder().decode(RespirationTimeline.self, from: asset.data)
        else { return nil }
        cache.setObject(RespirationTimelineBox(timeline), forKey: key)
        return timeline
    }
}

private struct RespirationDrawCommand: Decodable, Sendable {
    let type: String
    let x, y: CGFloat
    let w, h, r, lineWidth, opacity, fontSize: CGFloat?
    let color, stroke, fill, text, align, asset: String?
    let weight: Int?
    let points: [[CGFloat]]?
    let dash: [CGFloat]?

    func draw(in source: GraphicsContext) {
        var context = source
        context.opacity *= Double(opacity ?? 1)
        let origin = CGPoint(x: x, y: y)
        let rect = CGRect(x: x, y: y, width: w ?? 0, height: h ?? 0)
        let ink = Self.color(color)
        switch type {
        case "text":
            let fontWeight: Font.Weight = (weight ?? 600) >= 800 ? .heavy :
                ((weight ?? 600) >= 700 ? .bold : ((weight ?? 600) >= 600 ? .semibold : .medium))
            let label = Text(text ?? "")
                .font(.system(size: fontSize ?? 12, weight: fontWeight, design: .rounded))
                .foregroundColor(ink)
            context.draw(context.resolve(label), at: origin,
                         anchor: align == "left" ? .leading : (align == "right" ? .trailing : .center))
        case "image":
            if let asset { context.draw(context.resolve(Image(asset)), in: rect) }
        case "round", "ellipse":
            let path = type == "ellipse" ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: r ?? 0)
            context.fill(path, with: .color(ink))
            if let stroke, stroke != "transparent" {
                context.stroke(path, with: .color(Self.color(stroke)), lineWidth: lineWidth ?? 1)
            }
        case "line", "path":
            var path = Path()
            path.move(to: origin)
            for point in points ?? [] where point.count >= 2 {
                path.addLine(to: CGPoint(x: point[0], y: point[1]))
            }
            if let fill {
                path.closeSubpath()
                context.fill(path, with: .color(Self.color(fill)))
            }
            context.stroke(path, with: .color(ink), style: StrokeStyle(
                lineWidth: lineWidth ?? 1.5, lineCap: .round, lineJoin: .round, dash: dash ?? []))
        default: break
        }
    }

    private static func color(_ hex: String?) -> Color {
        guard let hex, hex != "transparent",
              let value = UInt32(hex.replacingOccurrences(of: "#", with: ""), radix: 16)
        else { return .clear }
        return RespirationTheme.color(value)
    }
}
