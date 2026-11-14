// CellStructuresVectors.swift — editable vectors; no bitmap assets to import.
import SwiftUI
import UIKit

enum CSPalette {
    static let cream = Color(csHex: 0xFBF4EA)
    static let ink = Color(csHex: 0x184C46)
    static let teal = Color(csHex: 0x118782)
    static let muted = Color(csHex: 0x5E786F)
    static let paper = Color(csHex: 0xFFFDF8)
}
extension Color {
    init(csHex value: UInt32) {
        self.init(.sRGB, red: Double((value >> 16) & 255) / 255,
                  green: Double((value >> 8) & 255) / 255,
                  blue: Double(value & 255) / 255, opacity: 1)
    }
}
enum CSCommand {
    case move(CGFloat, CGFloat), line(CGFloat, CGFloat)
    case quad(CGFloat, CGFloat, CGFloat, CGFloat)
    case curve(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
    case close
}
struct CSMark {
    let shape: Path
    let fill: UInt32?
    let stroke: UInt32?
    let width: CGFloat
    static func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                        _ fill: UInt32?, _ stroke: UInt32?, _ width: CGFloat) -> CSMark {
        .init(shape: Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), fill: fill, stroke: stroke, width: width)
    }
    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat,
                     _ fill: UInt32?, _ stroke: UInt32?, _ width: CGFloat) -> CSMark {
        .init(shape: Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r), fill: fill, stroke: stroke, width: width)
    }
    static func path(_ commands: [CSCommand], _ fill: UInt32?, _ stroke: UInt32?, _ width: CGFloat) -> CSMark {
        var p = Path()
        for command in commands {
            switch command {
            case let .move(x, y): p.move(to: CGPoint(x: x, y: y))
            case let .line(x, y): p.addLine(to: CGPoint(x: x, y: y))
            case let .quad(x1, y1, x, y): p.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x1, y: y1))
            case let .curve(x1, y1, x2, y2, x, y): p.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x1, y: y1), control2: CGPoint(x: x2, y: y2))
            case .close: p.closeSubpath()
            }
        }
        return .init(shape: p, fill: fill, stroke: stroke, width: width)
    }
}

enum CSVector {
    static func draw(_ part: CSPart, in context: inout GraphicsContext, rect: CGRect, opacity: Double = 1) {
        if let frame = CSRasterArtwork.frames[part], UIImage(named: "CSAnimalOrganelles") != nil {
            var c = context
            c.opacity *= opacity
            let scale = min(rect.width / frame.width, rect.height / frame.height)
            let fitted = CGRect(x: rect.midX - frame.width * scale / 2,
                                y: rect.midY - frame.height * scale / 2,
                                width: frame.width * scale, height: frame.height * scale)
            c.clip(to: Path(fitted))
            let target = CGRect(x: fitted.minX - frame.minX * scale, y: fitted.minY - frame.minY * scale,
                                width: 1536 * scale, height: 1024 * scale)
            c.draw(c.resolve(Image("CSAnimalOrganelles").interpolation(.high)), in: target)
            return
        }
        var c = context
        c.opacity *= opacity
        c.translateBy(x: rect.minX, y: rect.minY)
        c.scaleBy(x: rect.width / 100, y: rect.height / 100)
        for mark in marks(part) {
            if let fill = mark.fill { c.fill(mark.shape, with: .color(Color(csHex: fill))) }
            if let stroke = mark.stroke {
                c.stroke(mark.shape, with: .color(Color(csHex: stroke)), style: StrokeStyle(lineWidth: mark.width, lineCap: .round, lineJoin: .round))
            }
        }
    }

    static func marks(_ part: CSPart) -> [CSMark] {
        switch part {
        case .nucleus:
            return [
                .ellipse(5, 5, 90, 90, 0xDECCE9, 0x184C46, 2.3),
                .ellipse(10, 10, 80, 80, 0xEDE0F4, 0x184C46, 1.2),
                .ellipse(91.0, 47.0, 6, 6, 0xFFFDF8, 0x118782, 1.4),
                .ellipse(74.4336, 81.4006, 6, 6, 0xFFFDF8, 0x118782, 1.4),
                .ellipse(37.2091, 89.8968, 6, 6, 0xFFFDF8, 0x118782, 1.4),
                .ellipse(7.3574, 66.0909, 6, 6, 0xFFFDF8, 0x118782, 1.4),
                .ellipse(7.3574, 27.9091, 6, 6, 0xFFFDF8, 0x118782, 1.4),
                .ellipse(37.2091, 4.1032, 6, 6, 0xFFFDF8, 0x118782, 1.4),
                .ellipse(74.4336, 12.5994, 6, 6, 0xFFFDF8, 0x118782, 1.4),
                .path([.move(23, 30), .curve(37, 16, 47, 46, 60, 30), .curve(70, 21, 80, 26, 76, 36)], nil, 0x9D7AAF, 2.8),
                .path([.move(23, 48), .curve(37, 34, 47, 64, 60, 48), .curve(70, 39, 80, 44, 76, 54)], nil, 0x9D7AAF, 2.8),
                .path([.move(23, 66), .curve(37, 52, 47, 82, 60, 66), .curve(70, 57, 80, 62, 76, 72)], nil, 0x9D7AAF, 2.8),
                .path([.move(24, 18), .quad(41, 8, 54, 13)], nil, 0xFFFFFF, 4),
            ]
        case .nucleolus:
            return [
                .ellipse(8, 8, 84, 84, 0xB18ABA, 0x184C46, 2),
                .ellipse(20, 20, 20, 14, 0xDAC7E6, nil, 1.7),
                .ellipse(33, 58, 10, 8, 0xDECCE9, 0x7F6592, 1),
                .ellipse(56, 43, 10, 8, 0xDECCE9, 0x7F6592, 1),
                .ellipse(58, 65, 10, 8, 0xDECCE9, 0x7F6592, 1),
                .ellipse(37, 34, 10, 8, 0xDECCE9, 0x7F6592, 1),
            ]
        case .ribosomes:
            return [
                .ellipse(15, 18, 70, 47, 0xF7E49C, 0x184C46, 2.7),
                .ellipse(23, 60, 54, 24, 0xE3C86F, 0x184C46, 2.4),
                .path([.move(5, 60), .curve(28, 48, 56, 73, 94, 55)], nil, 0xAA7DB0, 3),
                .ellipse(31, 29, 21, 9, 0xFFF8D1, nil, 1.7),
            ]
        case .roughER:
            return [
                .path([.move(7, 23), .curve(23, 6, 55, 27, 78, 15), .quad(98, 9, 91, 25), .curve(64, 41, 34, 19, 11, 33), .quad(0, 35, 7, 23)], 0xC8E7EF, 0x118782, 1.5),
                .ellipse(15, 16.0, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(36, 18.7279, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(57, 13.7296, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(78, 15.1618, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .path([.move(7, 42), .curve(23, 25, 55, 46, 78, 34), .quad(98, 28, 91, 44), .curve(64, 60, 34, 38, 11, 52), .quad(0, 54, 7, 42)], 0xC8E7EF, 0x118782, 1.5),
                .ellipse(15, 35.0, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(36, 37.7279, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(57, 32.7296, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(78, 34.1618, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .path([.move(7, 61), .curve(23, 44, 55, 65, 78, 53), .quad(98, 47, 91, 63), .curve(64, 79, 34, 57, 11, 71), .quad(0, 73, 7, 61)], 0xC8E7EF, 0x118782, 1.5),
                .ellipse(15, 54.0, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(36, 56.7279, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(57, 51.7296, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(78, 53.1618, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .path([.move(7, 80), .curve(23, 63, 55, 84, 78, 72), .quad(98, 66, 91, 82), .curve(64, 98, 34, 76, 11, 90), .quad(0, 92, 7, 80)], 0xC8E7EF, 0x118782, 1.5),
                .ellipse(15, 73.0, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(36, 75.7279, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(57, 70.7296, 5, 5, 0xF7E49C, 0x184C46, 0.9),
                .ellipse(78, 72.1618, 5, 5, 0xF7E49C, 0x184C46, 0.9),
            ]
        case .smoothER:
            return [
                .path([.move(8, 26), .curve(38, -9, 45, 49, 70, 22), .quad(86, 8, 93, 24)], nil, 0x184C46, 11),
                .path([.move(8, 26), .curve(38, -9, 45, 49, 70, 22), .quad(86, 8, 93, 24)], nil, 0xF3C9B5, 7),
                .path([.move(8, 50), .curve(38, 15, 45, 73, 70, 46), .quad(86, 32, 93, 48)], nil, 0x184C46, 11),
                .path([.move(8, 50), .curve(38, 15, 45, 73, 70, 46), .quad(86, 32, 93, 48)], nil, 0xF3C9B5, 7),
                .path([.move(8, 74), .curve(38, 39, 45, 97, 70, 70), .quad(86, 56, 93, 72)], nil, 0x184C46, 11),
                .path([.move(8, 74), .curve(38, 39, 45, 97, 70, 70), .quad(86, 56, 93, 72)], nil, 0xF3C9B5, 7),
                .path([.move(29, 12), .curve(10, 37, 65, 37, 38, 90)], nil, 0x184C46, 10),
                .path([.move(29, 12), .curve(10, 37, 65, 37, 38, 90)], nil, 0xF3C9B5, 6),
            ]
        case .golgi:
            return [
                .path([.move(12, 17), .quad(49, 39, 91, 15), .quad(98, 21, 89, 26), .quad(51, 47, 10, 26), .quad(5, 20, 12, 17)], 0xF1BEAA, 0x184C46, 1.6),
                .path([.move(15, 32), .quad(49, 54, 87, 30), .quad(94, 36, 85, 41), .quad(51, 62, 13, 41), .quad(8, 35, 15, 32)], 0xF1BEAA, 0x184C46, 1.6),
                .path([.move(18, 47), .quad(49, 69, 83, 45), .quad(90, 51, 81, 56), .quad(51, 77, 16, 56), .quad(11, 50, 18, 47)], 0xF1BEAA, 0x184C46, 1.6),
                .path([.move(21, 62), .quad(49, 84, 79, 60), .quad(86, 66, 77, 71), .quad(51, 92, 19, 71), .quad(14, 65, 21, 62)], 0xF1BEAA, 0x184C46, 1.6),
                .path([.move(24, 77), .quad(49, 99, 75, 75), .quad(82, 81, 73, 86), .quad(51, 107, 22, 86), .quad(17, 80, 24, 77)], 0xF1BEAA, 0x184C46, 1.6),
                .ellipse(4, 8, 12, 12, 0xF3C9B5, 0x184C46, 1.7),
                .ellipse(79, 80, 13, 13, 0xF3C9B5, 0x184C46, 1.7),
                .ellipse(84, 4, 8, 8, 0xF7E49C, 0x184C46, 1.7),
            ]
        case .vesicles:
            return [
                .ellipse(11, 11, 78, 78, 0xC8E7EF, 0x184C46, 2.8),
                .ellipse(18, 18, 64, 64, 0xE8F4F6, 0x118782, 1),
                .ellipse(30, 34, 12, 12, 0xF3C9B5, 0x184C46, 1),
                .ellipse(52, 28, 12, 12, 0xF3C9B5, 0x184C46, 1),
                .ellipse(40, 55, 12, 12, 0xF3C9B5, 0x184C46, 1),
                .ellipse(62, 53, 12, 12, 0xF3C9B5, 0x184C46, 1),
                .path([.move(25, 28), .quad(41, 14, 56, 21)], nil, 0xFFFFFF, 4),
            ]
        case .lysosomes:
            return [
                .ellipse(9, 9, 82, 82, 0xDECCE9, 0x184C46, 2.6),
                .rect(29, 33, 16, 16, 4, 0xBB95C7, 0x184C46, 1),
                .rect(56, 29, 12, 12, 4, 0xBB95C7, 0x184C46, 1),
                .rect(53, 57, 20, 20, 4, 0xBB95C7, 0x184C46, 1),
                .rect(26, 61, 9, 9, 4, 0xBB95C7, 0x184C46, 1),
                .ellipse(42, 20, 4, 4, 0xF7E49C, nil, 1.7),
                .ellipse(76, 49, 4, 4, 0xF7E49C, nil, 1.7),
                .ellipse(19, 48, 4, 4, 0xF7E49C, nil, 1.7),
                .ellipse(35, 78, 4, 4, 0xF7E49C, nil, 1.7),
            ]
        case .peroxisomes:
            return [
                .ellipse(10, 10, 80, 80, 0xD0E5C2, 0x184C46, 2.6),
                .path([.move(50, 26), .line(70, 44), .line(61, 69), .line(36, 72), .line(25, 46), .close], 0xF7E49C, 0x184C46, 1.6),
                .path([.move(50, 26), .line(50, 68)], nil, 0x9CA577, 1.4),
                .path([.move(25, 46), .line(70, 44)], nil, 0x9CA577, 1.4),
                .ellipse(24, 24, 5, 5, 0x7EA57C, nil, 1.7),
                .ellipse(71, 62, 5, 5, 0x7EA57C, nil, 1.7),
                .ellipse(30, 77, 5, 5, 0x7EA57C, nil, 1.7),
                .ellipse(70, 29, 5, 5, 0x7EA57C, nil, 1.7),
            ]
        case .mitochondria:
            return [
                .path([.move(12, 40), .curve(20, 11, 72, 7, 88, 34), .curve(107, 69, 70, 92, 36, 83), .curve(12, 80, -2, 64, 12, 40), .close], 0xF3C9B5, 0x184C46, 2.6),
                .path([.move(20, 43), .curve(30, 27, 39, 28, 34, 44), .curve(22, 65, 46, 74, 48, 54), .curve(47, 19, 68, 22, 62, 43), .curve(49, 66, 72, 76, 75, 53), .quad(83, 36, 83, 53)], nil, 0xB77466, 4.6),
                .path([.move(19, 34), .quad(44, 11, 72, 27)], nil, 0xFDE9DD, 3),
            ]
        case .centrosome:
            return [
                .path([.move(75.0, 50.0), .line(96.0, 50.0)], nil, 0xADC69A, 1.4),
                .path([.move(69.1511, 66.0697), .line(85.238, 79.5682)], nil, 0xADC69A, 1.4),
                .path([.move(54.3412, 74.6202), .line(57.9878, 95.3012)], nil, 0xADC69A, 1.4),
                .path([.move(37.5, 71.6506), .line(27.0, 89.8372)], nil, 0xADC69A, 1.4),
                .path([.move(26.5077, 58.5505), .line(6.7741, 65.7329)], nil, 0xADC69A, 1.4),
                .path([.move(26.5077, 41.4495), .line(6.7741, 34.2671)], nil, 0xADC69A, 1.4),
                .path([.move(37.5, 28.3494), .line(27.0, 10.1628)], nil, 0xADC69A, 1.4),
                .path([.move(54.3412, 25.3798), .line(57.9878, 4.6988)], nil, 0xADC69A, 1.4),
                .path([.move(69.1511, 33.9303), .line(85.238, 20.4318)], nil, 0xADC69A, 1.4),
                .rect(20, 36, 41, 20, 7, 0xF7E49C, 0x184C46, 2),
                .rect(57, 28, 20, 44, 7, 0xE3C86F, 0x184C46, 2),
                .path([.move(26, 41), .line(56, 41)], nil, 0xB09340, 1.5),
                .path([.move(26, 46), .line(56, 46)], nil, 0xB09340, 1.5),
                .path([.move(26, 51), .line(56, 51)], nil, 0xB09340, 1.5),
                .path([.move(62, 34), .line(62, 66)], nil, 0xB09340, 1.5),
                .path([.move(67, 34), .line(67, 66)], nil, 0xB09340, 1.5),
                .path([.move(72, 34), .line(72, 66)], nil, 0xB09340, 1.5),
            ]
        case .cytoskeleton:
            return [
                .path([.move(10, 15), .curve(35, 4, 62, 38, 92, 15)], nil, 0x81B1A3, 4),
                .path([.move(10, 37), .curve(35, 26, 62, 46, 92, 37)], nil, 0x9B82B3, 4),
                .path([.move(10, 59), .curve(35, 48, 62, 54, 92, 59)], nil, 0xD9AA84, 4),
                .path([.move(10, 81), .curve(35, 70, 62, 62, 92, 81)], nil, 0x81B1A3, 4),
                .path([.move(31, 5), .quad(48, 45, 22, 95)], nil, 0x118782, 3),
            ]
        case .microtubules:
            return [
                .rect(8, 34, 84, 32, 15, 0xC8E7EF, 0x184C46, 2),
                .path([.move(17, 42), .line(86, 42)], nil, 0x118782, 1.2),
                .path([.move(17, 50), .line(86, 50)], nil, 0x118782, 1.2),
                .path([.move(17, 58), .line(86, 58)], nil, 0x118782, 1.2),
                .path([.move(21, 35), .line(21, 65)], nil, 0x649DA7, 0.9),
                .path([.move(33, 35), .line(33, 65)], nil, 0x649DA7, 0.9),
                .path([.move(45, 35), .line(45, 65)], nil, 0x649DA7, 0.9),
                .path([.move(57, 35), .line(57, 65)], nil, 0x649DA7, 0.9),
                .path([.move(69, 35), .line(69, 65)], nil, 0x649DA7, 0.9),
                .path([.move(81, 35), .line(81, 65)], nil, 0x649DA7, 0.9),
                .ellipse(7, 34, 17, 32, 0x7DAAB2, 0x184C46, 1.6),
                .ellipse(11, 40, 9, 20, 0xFFFDF8, 0x184C46, 1),
            ]
        case .microfilaments:
            return [
                .ellipse(7, 32.0, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(7, 48.0, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(15, 38.4562, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(15, 41.5438, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(23, 40.9962, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(23, 39.0038, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(31, 38.0792, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(31, 41.9208, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(39, 31.4746, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(39, 48.5254, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(47, 25.1888, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(47, 54.8112, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(55, 23.0345, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(55, 56.9655, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(63, 26.3186, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(63, 53.6814, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(71, 33.0489, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(71, 46.9511, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(79, 39.143, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(79, 40.857, 9, 9, 0xD5A18A, 0x184C46, 1),
                .ellipse(87, 40.9042, 9, 9, 0xF3C9B5, 0x184C46, 1),
                .ellipse(87, 39.0958, 9, 9, 0xD5A18A, 0x184C46, 1),
            ]
        case .intermediateFilaments:
            return [
                .path([.move(7, 35), .curve(29, 10, 60, 80, 94, 33)], nil, 0xB093BC, 5),
                .path([.move(7, 44), .curve(29, 19, 60, 72, 94, 41)], nil, 0xC1ABC9, 5),
                .path([.move(7, 53), .curve(29, 28, 60, 64, 94, 49)], nil, 0xA384B1, 5),
                .path([.move(7, 62), .curve(29, 37, 60, 56, 94, 57)], nil, 0xD4C0DC, 5),
            ]
        case .cilia:
            return [
                .path([.move(5, 83), .quad(50, 73, 95, 83)], nil, 0x118782, 6),
                .path([.move(12, 79), .curve(22, 58, 0, 35, 19, 13)], nil, 0x184C46, 5),
                .path([.move(12, 79), .curve(22, 58, 0, 35, 19, 13)], nil, 0xC8E7EF, 2.8),
                .path([.move(28, 79), .curve(38, 58, 16, 35, 35, 13)], nil, 0x184C46, 5),
                .path([.move(28, 79), .curve(38, 58, 16, 35, 35, 13)], nil, 0xC8E7EF, 2.8),
                .path([.move(44, 79), .curve(54, 58, 32, 35, 51, 13)], nil, 0x184C46, 5),
                .path([.move(44, 79), .curve(54, 58, 32, 35, 51, 13)], nil, 0xC8E7EF, 2.8),
                .path([.move(60, 79), .curve(70, 58, 48, 35, 67, 13)], nil, 0x184C46, 5),
                .path([.move(60, 79), .curve(70, 58, 48, 35, 67, 13)], nil, 0xC8E7EF, 2.8),
                .path([.move(76, 79), .curve(86, 58, 64, 35, 83, 13)], nil, 0x184C46, 5),
                .path([.move(76, 79), .curve(86, 58, 64, 35, 83, 13)], nil, 0xC8E7EF, 2.8),
            ]
        case .flagellum:
            return [
                .path([.move(4, 50), .curve(23, 0, 34, 97, 53, 48), .curve(68, 0, 82, 94, 97, 49)], nil, 0x184C46, 7),
                .path([.move(4, 50), .curve(23, 0, 34, 97, 53, 48), .curve(68, 0, 82, 94, 97, 49)], nil, 0xC8E7EF, 4),
            ]
        case .membrane:
            return [
                .path([.move(6, 30), .line(5, 43)], nil, 0x9BB58A, 2),
                .path([.move(10, 30), .line(11, 43)], nil, 0x9BB58A, 2),
                .ellipse(4, 26, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(6, 70), .line(5, 57)], nil, 0x9BB58A, 2),
                .path([.move(10, 70), .line(11, 57)], nil, 0x9BB58A, 2),
                .ellipse(4, 66, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(17, 30), .line(16, 43)], nil, 0x9BB58A, 2),
                .path([.move(21, 30), .line(22, 43)], nil, 0x9BB58A, 2),
                .ellipse(15, 26, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(17, 70), .line(16, 57)], nil, 0x9BB58A, 2),
                .path([.move(21, 70), .line(22, 57)], nil, 0x9BB58A, 2),
                .ellipse(15, 66, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(28, 30), .line(27, 43)], nil, 0x9BB58A, 2),
                .path([.move(32, 30), .line(33, 43)], nil, 0x9BB58A, 2),
                .ellipse(26, 26, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(28, 70), .line(27, 57)], nil, 0x9BB58A, 2),
                .path([.move(32, 70), .line(33, 57)], nil, 0x9BB58A, 2),
                .ellipse(26, 66, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(39, 30), .line(38, 43)], nil, 0x9BB58A, 2),
                .path([.move(43, 30), .line(44, 43)], nil, 0x9BB58A, 2),
                .ellipse(37, 26, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(39, 70), .line(38, 57)], nil, 0x9BB58A, 2),
                .path([.move(43, 70), .line(44, 57)], nil, 0x9BB58A, 2),
                .ellipse(37, 66, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(50, 30), .line(49, 43)], nil, 0x9BB58A, 2),
                .path([.move(54, 30), .line(55, 43)], nil, 0x9BB58A, 2),
                .ellipse(48, 26, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(50, 70), .line(49, 57)], nil, 0x9BB58A, 2),
                .path([.move(54, 70), .line(55, 57)], nil, 0x9BB58A, 2),
                .ellipse(48, 66, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(61, 30), .line(60, 43)], nil, 0x9BB58A, 2),
                .path([.move(65, 30), .line(66, 43)], nil, 0x9BB58A, 2),
                .ellipse(59, 26, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(61, 70), .line(60, 57)], nil, 0x9BB58A, 2),
                .path([.move(65, 70), .line(66, 57)], nil, 0x9BB58A, 2),
                .ellipse(59, 66, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(72, 30), .line(71, 43)], nil, 0x9BB58A, 2),
                .path([.move(76, 30), .line(77, 43)], nil, 0x9BB58A, 2),
                .ellipse(70, 26, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(72, 70), .line(71, 57)], nil, 0x9BB58A, 2),
                .path([.move(76, 70), .line(77, 57)], nil, 0x9BB58A, 2),
                .ellipse(70, 66, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(83, 30), .line(82, 43)], nil, 0x9BB58A, 2),
                .path([.move(87, 30), .line(88, 43)], nil, 0x9BB58A, 2),
                .ellipse(81, 26, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(83, 70), .line(82, 57)], nil, 0x9BB58A, 2),
                .path([.move(87, 70), .line(88, 57)], nil, 0x9BB58A, 2),
                .ellipse(81, 66, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(94, 30), .line(93, 43)], nil, 0x9BB58A, 2),
                .path([.move(98, 30), .line(99, 43)], nil, 0x9BB58A, 2),
                .ellipse(92, 26, 8, 8, 0xD0E5C2, 0x118782, 1),
                .path([.move(94, 70), .line(93, 57)], nil, 0x9BB58A, 2),
                .path([.move(98, 70), .line(99, 57)], nil, 0x9BB58A, 2),
                .ellipse(92, 66, 8, 8, 0xD0E5C2, 0x118782, 1),
                .rect(42, 24, 17, 52, 6, 0xF3C9B5, 0x184C46, 1.5),
                .rect(48, 25, 5, 50, 2, 0xFFFDF8, 0x118782, 0.7),
            ]
        case .cytoplasm:
            return [
                .ellipse(6, 9, 88, 82, 0xE5F0DF, 0x118782, 2),
                .ellipse(22, 26, 31, 31, 0xDECCE9, 0x184C46, 1.4),
                .ellipse(65, 31, 6, 6, 0xC8E7EF, 0x184C46, 1),
                .ellipse(61, 57, 6, 6, 0xC8E7EF, 0x184C46, 1),
                .ellipse(34, 70, 6, 6, 0xC8E7EF, 0x184C46, 1),
                .ellipse(76, 67, 6, 6, 0xC8E7EF, 0x184C46, 1),
            ]
        }
    }
}

// Regions of the supplied high-resolution atlas; no generated image is flattened into the cell.
// The image and the hit map use the same destination rectangles in CSLayout.
enum CSRasterArtwork {
    static let frames: [CSPart: CGRect] = [
        .nucleus: CGRect(x: 31, y: 17, width: 335, height: 324),
        .nucleolus: CGRect(x: 426, y: 28, width: 297, height: 289),
        .mitochondria: CGRect(x: 768, y: 44, width: 365, height: 264),
        .roughER: CGRect(x: 1152, y: 42, width: 363, height: 261),
        .smoothER: CGRect(x: 16, y: 363, width: 361, height: 295),
        .golgi: CGRect(x: 393, y: 362, width: 374, height: 293),
        .lysosomes: CGRect(x: 800, y: 357, width: 310, height: 305),
        .peroxisomes: CGRect(x: 1179, y: 359, width: 311, height: 302),
        .ribosomes: CGRect(x: 11, y: 685, width: 362, height: 310),
        .vesicles: CGRect(x: 420, y: 699, width: 300, height: 297),
        .centrosome: CGRect(x: 788, y: 707, width: 340, height: 288),
        .membrane: CGRect(x: 1136, y: 717, width: 390, height: 235)
    ]
}
