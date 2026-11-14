// CentralDogmaTheme.swift — isolated names coexist with the Cell Cycle/Mitosis screens.
import SwiftUI

enum CentralDogmaTheme {
    static let cream = color(0xFBF4EA)
    static let paper = color(0xFFFDF8)
    static let ink = color(0x184C46)
    static let edge = color(0x54796B)
    static let muted = color(0x5E786F)
    static let teal = color(0x118782)
    static let parental = color(0x6589A4)
    static let newDNA = color(0xCF7595)
    static let rna = color(0xD39D2F)
    static let error = color(0xB43F50)

    static func color(_ hex: UInt32) -> Color {
        Color(.sRGB, red: Double((hex >> 16) & 255) / 255,
              green: Double((hex >> 8) & 255) / 255,
              blue: Double(hex & 255) / 255, opacity: 1)
    }
}

enum CentralDogmaTint: Sendable {
    case sage, blue, lavender, butter, peach
    var color: Color {
        switch self {
        case .sage: return CentralDogmaTheme.color(0xD0E5C2)
        case .blue: return CentralDogmaTheme.color(0xC8E7EF)
        case .lavender: return CentralDogmaTheme.color(0xDECCE9)
        case .butter: return CentralDogmaTheme.color(0xF8EBC3)
        case .peach: return CentralDogmaTheme.color(0xF3C9B5)
        }
    }
}

struct CentralDogmaCarouselControls: View {
    let titles: [String]
    let index: Int
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
                    .background(CentralDogmaTheme.paper.opacity(0.8), in: Circle())
            }
            .disabled(index == 0)
            .opacity(index == 0 ? 0.3 : 1)
            .accessibilityLabel("Previous card")
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                ForEach(visibleIndices, id: \.self) { item in
                    Button { onSelect(item) } label: {
                        Capsule()
                            .fill(item == index ? CentralDogmaTheme.teal : CentralDogmaTheme.edge.opacity(0.2))
                            .frame(width: item == index ? 20 : 5, height: 5)
                            .frame(width: 22, height: 44)
                    }
                    .accessibilityLabel(titles[item])
                    .accessibilityValue(item == index ? "Selected" : "")
                }
            }
            Spacer(minLength: 0)
            Button { onSelect(min(titles.count - 1, index + 1)) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
                    .background(CentralDogmaTheme.paper.opacity(0.8), in: Circle())
            }
            .disabled(index == titles.count - 1)
            .opacity(index == titles.count - 1 ? 0.3 : 1)
            .accessibilityLabel("Next card")
        }
        .font(.system(.subheadline, design: .rounded, weight: .semibold))
        .foregroundStyle(CentralDogmaTheme.ink)
        .buttonStyle(.plain)
    }
}

struct CentralDogmaRichText: View {
    let value: String
    init(_ value: String) { self.value = value }
    var body: some View {
        Text((try? AttributedString(markdown: value, options:
            .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(value))
    }
}

struct CentralDogmaBullets: View {
    let items: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    Text("•").foregroundStyle(CentralDogmaTheme.teal).accessibilityHidden(true)
                    CentralDogmaRichText(item)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(.body, design: .rounded))
                .lineSpacing(3)
                .foregroundStyle(CentralDogmaTheme.ink)
            }
        }
    }
}

struct CentralDogmaLegend: View {
    var body: some View {
        HStack(spacing: 18) {
            entry("DNA", CentralDogmaTheme.parental)
            entry("RNA", CentralDogmaTheme.rna)
            entry("Protein", CentralDogmaTheme.newDNA)
        }
        .font(.system(.caption, design: .rounded, weight: .medium))
        .foregroundStyle(CentralDogmaTheme.muted)
        .accessibilityElement(children: .combine)
    }
    private func entry(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Capsule().fill(color).frame(width: 15, height: 4)
                .accessibilityHidden(true)
            Text(label)
        }
    }
}

extension CentralDogmaTheme {
    static func tint(_ name: String) -> Color {
        switch name {
        case "blue": return CentralDogmaTint.blue.color
        case "lavender": return CentralDogmaTint.lavender.color
        case "butter": return CentralDogmaTint.butter.color
        case "peach": return CentralDogmaTint.peach.color
        default: return CentralDogmaTint.sage.color
        }
    }
}
