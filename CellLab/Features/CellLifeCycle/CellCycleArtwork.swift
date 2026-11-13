//
//  CellCycleArtwork.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/13/26.
//

// CellCycleArtwork.swift
// CellLab — palette, inline emphasis, illustration treatments, and exact wheel geometry.

import SwiftUI

enum CellCyclePalette {
    static let cream = Color(cellCycleHex: 0xFBF4EA)
    static let ink = Color(cellCycleHex: 0x184C46)
    static let edge = Color(cellCycleHex: 0x54796B)
    static let muted = Color(cellCycleHex: 0x5E786F)
    static let teal = Color(cellCycleHex: 0x118782)
    static let paper = Color(cellCycleHex: 0xFFFDF8)
}

extension CellCycleTint {
    var color: Color {
        switch self {
        case .sage: return Color(cellCycleHex: 0xD0E5C2)
        case .blue: return Color(cellCycleHex: 0xC8E7EF)
        case .lavender: return Color(cellCycleHex: 0xDECCE9)
        case .butter: return Color(cellCycleHex: 0xF7E49C)
        case .peach: return Color(cellCycleHex: 0xF3C9B5)
        }
    }
}

private extension Color {
    init(cellCycleHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

struct CellCycleRichText: View {
    let value: String

    init(_ value: String) { self.value = value }

    var body: some View {
        Text((try? AttributedString(
            markdown: value,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(value))
    }
}

struct CellCycleBullets: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("•")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(CellCyclePalette.teal)
                        .accessibilityHidden(true)
                    CellCycleRichText(item)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(CellCyclePalette.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// Shared by the filled sector, visible selection outline, and exact hit area.
// Angles increase clockwise in screen coordinates. Slices do not encode duration.
struct CellCycleSector: Shape {
    let startDegrees: Double
    let endDegrees: Double

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let center = CGPoint(x: width / 2, y: width / 2 + 12)
        let outer = width * 0.445
        let inner = width * 0.255
        let start = Angle.degrees(startDegrees + 1.2)
        let end = Angle.degrees(endDegrees - 1.2)
        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}

struct CellCycleWheel: View {
    @Binding var selection: CellCyclePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floating = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let center = CGPoint(x: width / 2, y: width / 2 + 12)

            ZStack(alignment: .topLeading) {
                // A single outward branch from G₁; G₀ is not a step in the circular sequence.
                Path { path in
                    path.move(to: CGPoint(x: width * 0.22, y: width * 0.20 + 12))
                    path.addCurve(
                        to: CGPoint(x: width * 0.105, y: width * 0.13 + 12),
                        control1: CGPoint(x: width * 0.10, y: width * 0.27),
                        control2: CGPoint(x: width * 0.04, y: width * 0.23)
                    )
                }
                .stroke(CellCyclePalette.edge, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                .accessibilityHidden(true)

                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(CellCyclePalette.edge)
                    .position(x: width * 0.105, y: width * 0.13 + 12)
                    .accessibilityHidden(true)

                ForEach(CellCyclePhase.circularCases) { phase in
                    sectorButton(phase, width: width, center: center)
                }

                // The central illustration is decorative; it does not claim to show the selected phase.
                VStack(spacing: 0) {
                    Image("CellCycleCell")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width * 0.43, height: width * 0.37)
                        .offset(y: reduceMotion ? 0 : (floating ? -2 : 2))
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                            value: floating
                        )
                    Text(centerLabel)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(CellCyclePalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: width * 0.38)
                }
                .position(center)
                .accessibilityHidden(true)
                .allowsHitTesting(false)

                Button { selection = .g0 } label: {
                    Text("G₀")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(CellCyclePalette.ink)
                        .frame(width: 48, height: 40)
                        .background(CellCycleTint.lavender.color, in: Capsule())
                        .overlay(Capsule().strokeBorder(
                            selection == .g0 ? CellCyclePalette.teal : CellCyclePalette.edge,
                            lineWidth: selection == .g0 ? 3 : 1.5
                        ))
                        .frame(minWidth: 48, minHeight: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: width * 0.105, y: width * 0.06 + 12)
                .accessibilityLabel(CellCyclePhase.g0.accessibilityName)
                .accessibilityValue(selection == .g0 ? "Selected" : "")
                .accessibilityHint("Shows G 0 details below. Branches from G 1.")
                .accessibilityIdentifier("cycle-phase-g0")
            }
            .frame(width: width, height: width + 24)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.bottom, 24)
        .onAppear { floating = true }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var centerLabel: String {
        switch selection {
        case .g1, .s, .g2: return "INTERPHASE"
        case .mitosis: return "MITOSIS"
        case .cytokinesis: return "CYTOKINESIS"
        case .g0: return "G₀ · NOT DIVIDING"
        }
    }

    private func sectorButton(_ phase: CellCyclePhase, width: CGFloat, center: CGPoint) -> some View {
        let content = phase.content
        let start = content.startDegrees ?? 0
        let end = content.endDegrees ?? 0
        let angle = (start + end) / 2 * .pi / 180
        let radius = width * 0.35
        let shape = CellCycleSector(startDegrees: start, endDegrees: end)
        let selected = selection == phase

        return Button { selection = phase } label: {
            ZStack(alignment: .topLeading) {
                shape.fill(content.tint.color.gradient)
                shape.stroke(
                    selected ? CellCyclePalette.teal : CellCyclePalette.edge,
                    style: StrokeStyle(lineWidth: selected ? 3.5 : 1.5, lineJoin: .round)
                )
                VStack(spacing: 3) {
                    Text(content.shortLabel)
                        .font(.system(
                            size: phase == .mitosis || phase == .cytokinesis ? 12 : 25,
                            weight: .heavy, design: .rounded
                        ))
                    if phase == .g1 || phase == .s || phase == .g2 {
                        Text(phase == .g1 ? "grow" : (phase == .s ? "copy" : "prep"))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees((start + end) / 2 + 90))
                    }
                }
                .foregroundStyle(CellCyclePalette.ink)
                .position(
                    x: center.x + radius * CGFloat(cos(angle)),
                    y: center.y + radius * CGFloat(sin(angle))
                )
                .allowsHitTesting(false)
            }
            .frame(width: width, height: width + 24)
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(phase.accessibilityName)
        .accessibilityValue(selected ? "Selected" : "")
        .accessibilityHint("Shows phase details below.")
        .accessibilityIdentifier("cycle-phase-\(phase.rawValue)")
    }
}

struct CellCyclePlayerArt: View {
    let player: CellCyclePlayer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24).fill(player.tint.color.opacity(0.55))

            Image(player.artwork)
                .resizable()
                .scaledToFit()
                .padding(player.illustration == .chromosome ? 10 : 20)
                .scaleEffect(player.illustration == .cyclins && breathing && !reduceMotion ? 1.025 : 1)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: breathing
                )

            if let badge = checkpointBadge {
                Label(badge, systemImage: "checkmark.shield.fill")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(CellCyclePalette.ink)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(CellCyclePalette.paper, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(12)
            }

            if player.illustration == .cyclins {
                ForEach(0..<3) { index in
                    Circle()
                        .fill([CellCycleTint.butter.color, CellCycleTint.peach.color, CellCycleTint.blue.color][index])
                        .frame(width: 18, height: 18)
                        .overlay(Circle().strokeBorder(CellCyclePalette.edge, lineWidth: 1.5))
                        .offset(x: CGFloat(index - 1) * 65, y: index == 1 ? -78 : 55)
                }
            }
        }
        .onAppear { breathing = true }
        .accessibilityHidden(true)
    }

    private var checkpointBadge: String? {
        switch player.illustration {
        case .g1Checkpoint: return "G₁ · p53"
        case .replicationCheckpoint: return "S → G₂"
        case .mCheckpoint: return "M checkpoint"
        default: return nil
        }
    }
}
