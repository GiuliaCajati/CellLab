// DNAReplicationTheme.swift — isolated names coexist with the Cell Cycle/Mitosis screens.
import SwiftUI

enum DNAReplicationTheme {
    static let cream = color(0xFBF4EA)
    static let paper = color(0xFFFDF8)
    static let ink = color(0x184C46)
    static let edge = color(0x54796B)
    static let muted = color(0x5E786F)
    static let teal = color(0x118782)
    static let parental = color(0x6589A4)
    static let newDNA = color(0xCF7595)
    static let rna = color(0xE3B34C)
    static let error = color(0xB43F50)

    static func color(_ hex: UInt32) -> Color {
        Color(.sRGB, red: Double((hex >> 16) & 255) / 255,
              green: Double((hex >> 8) & 255) / 255,
              blue: Double(hex & 255) / 255, opacity: 1)
    }
}

enum DNAReplicationTint: Sendable {
    case sage, blue, lavender, butter, peach
    var color: Color {
        switch self {
        case .sage: return DNAReplicationTheme.color(0xD0E5C2)
        case .blue: return DNAReplicationTheme.color(0xC8E7EF)
        case .lavender: return DNAReplicationTheme.color(0xDECCE9)
        case .butter: return DNAReplicationTheme.color(0xF7E49C)
        case .peach: return DNAReplicationTheme.color(0xF3C9B5)
        }
    }
}

struct DNAReplicationRichText: View {
    let value: String
    init(_ value: String) { self.value = value }
    var body: some View {
        Text((try? AttributedString(markdown: value, options:
            .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(value))
    }
}

struct DNAReplicationBullets: View {
    let items: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    Text("•").foregroundStyle(DNAReplicationTheme.teal).accessibilityHidden(true)
                    DNAReplicationRichText(item)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(.body, design: .rounded))
                .lineSpacing(3)
                .foregroundStyle(DNAReplicationTheme.ink)
            }
        }
    }
}

struct DNAReplicationLegend: View {
    var body: some View {
        ViewThatFits {
            HStack(spacing: 15) { entries }
            VStack(alignment: .leading, spacing: 6) { entries }
        }
        .font(.system(.caption, design: .rounded, weight: .medium))
        .foregroundStyle(DNAReplicationTheme.muted)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var entries: some View {
        entry("Parental", DNAReplicationTheme.parental)
        entry("New DNA", DNAReplicationTheme.newDNA)
        entry("RNA primer", DNAReplicationTheme.rna)
    }
    private func entry(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Capsule().fill(color).frame(width: 15, height: 4).accessibilityHidden(true)
            Text(title)
        }
    }
}
