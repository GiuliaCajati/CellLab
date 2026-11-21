// RespirationTheme.swift — isolated names coexist with the Cell Cycle/Mitosis screens.
import SwiftUI

enum RespirationTheme {
    static let cream = color(0xFBF4EA)
    static let paper = color(0xFFFDF8)
    static let card = color(0xFAE6CE)
    static let ink = color(0x184C46)
    static let edge = color(0x54796B)
    static let muted = color(0x5E786F)
    static let teal = color(0x118782)

    static func color(_ hex: UInt32) -> Color {
        Color(.sRGB, red: Double((hex >> 16) & 255) / 255,
              green: Double((hex >> 8) & 255) / 255,
              blue: Double(hex & 255) / 255, opacity: 1)
    }
}

enum RespirationTint: Sendable {
    case sage, blue, lavender, butter, peach
    var color: Color {
        switch self {
        case .sage: return RespirationTheme.color(0xD0E5C2)
        case .blue: return RespirationTheme.color(0xC8E7EF)
        case .lavender: return RespirationTheme.color(0xDECCE9)
        case .butter: return RespirationTheme.color(0xF8EBC3)
        case .peach: return RespirationTheme.color(0xF3C9B5)
        }
    }
}

struct RespirationCarouselControls: View {
    let titles: [String]
    let index: Int
    var identifierPrefix = "respiration"
    let onSelect: (Int) -> Void

    private var visibleIndices: [Int] {
        let start = min(max(0, index - 3), max(0, titles.count - 7))
        return Array(start..<min(titles.count, start + 7))
    }

    var body: some View {
        HStack(spacing: 8) {
            Button { onSelect(max(0, index - 1)) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
                    .background(RespirationTheme.paper.opacity(0.8), in: Circle())
            }
            .disabled(index == 0)
            .opacity(index == 0 ? 0.3 : 1)
            .accessibilityLabel("Previous card")
            .accessibilityIdentifier(identifierPrefix + "-previous")
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                ForEach(visibleIndices, id: \.self) { item in
                    Button { onSelect(item) } label: {
                        Capsule()
                            .fill(item == index ? RespirationTheme.teal : RespirationTheme.edge.opacity(0.2))
                            .frame(width: item == index ? 20 : 5, height: 5)
                            .frame(width: 22, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(titles[item])
                    .accessibilityValue(item == index ? "Selected" : "")
                }
            }
            Spacer(minLength: 0)
            Button { onSelect(min(titles.count - 1, index + 1)) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
                    .background(RespirationTheme.paper.opacity(0.8), in: Circle())
            }
            .disabled(index == titles.count - 1)
            .opacity(index == titles.count - 1 ? 0.3 : 1)
            .accessibilityLabel("Next card")
            .accessibilityIdentifier(identifierPrefix + "-next")
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold))
        .foregroundStyle(RespirationTheme.ink)
        .buttonStyle(.plain)
    }
}

struct RespirationRichText: View {
    let value: String
    init(_ value: String) { self.value = value }
    var body: some View {
        Text((try? AttributedString(markdown: value, options:
            .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(value))
    }
}

struct RespirationBullets: View {
    let items: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    Text("•").foregroundStyle(RespirationTheme.teal).accessibilityHidden(true)
                    RespirationRichText(item)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(.body, design: .rounded))
                .lineSpacing(3)
                .foregroundStyle(RespirationTheme.ink)
            }
        }
    }
}

struct RespirationEquationView: View {
    var showsNarration = false
    var body: some View {
        VStack(spacing: 6) {
            Text("The overall reaction")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(RespirationTheme.teal)
                .padding(.bottom, 4)
            if showsNarration {
                NarrationSpeakerButton(cueID: "reference.equation", title: "the overall reaction")
            }
            Text("C₆H₁₂O₆ + 6 O₂")
            Text("↓").foregroundStyle(RespirationTheme.teal)
            Text("6 CO₂ + 6 H₂O + ATP")
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold))
        .foregroundStyle(RespirationTheme.ink)
        .padding(16).frame(maxWidth: .infinity)
        .background(RespirationTint.sage.color.opacity(0.75), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("One glucose plus six oxygen yields six carbon dioxide plus six water, with energy captured in ATP.")
        .accessibilityIdentifier("respiration-equation")
    }
}

extension RespirationStep {
    var tint: Color {
        switch self {
        case .overview, .transport: RespirationTint.blue.color
        case .glycolysis, .efficiency: RespirationTint.sage.color
        case .transition, .fermentation: RespirationTint.peach.color
        case .krebs, .accounting: RespirationTint.butter.color
        case .chemiosmosis, .anaerobic: RespirationTint.lavender.color
        }
    }
    var accent: Color {
        switch self {
        case .overview, .transport: RespirationTheme.color(0x285C72)
        case .glycolysis, .efficiency: RespirationTheme.color(0x2F6550)
        case .transition, .fermentation: RespirationTheme.color(0x934B37)
        case .krebs, .accounting: RespirationTheme.color(0x816017)
        case .chemiosmosis, .anaerobic: RespirationTheme.color(0x6F4A7C)
        }
    }
}

extension RespirationTheme {
    static func tint(_ name: String) -> Color {
        switch name {
        case "blue": return RespirationTint.blue.color
        case "lavender": return RespirationTint.lavender.color
        case "butter": return RespirationTint.butter.color
        case "peach": return RespirationTint.peach.color
        default: return RespirationTint.sage.color
        }
    }
}
