import SwiftUI

// Separate names allow this game to coexist with the lesson and its theme.
enum DNACopyStyle {
    static let cream = color(0xFBF4EA), paper = color(0xFFFDF8)
    static let ink = color(0x184C46), edge = color(0x54796B), muted = color(0x5E786F)
    static let teal = color(0x118782), sage = color(0xD0E5C2), butter = color(0xF7E49C)
    static let blue = color(0xC8E7EF), lavender = color(0xDECCE9), peach = color(0xF3C9B5)
    static let parental = color(0x6589A4), newDNA = color(0xCF7595), rna = color(0xE3B34C)
    static let error = color(0xB43F50)
    static func color(_ hex: UInt32) -> Color {
        Color(.sRGB, red: Double((hex >> 16) & 255) / 255,
              green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
    static func base(_ base: DNACopyBase) -> Color {
        switch base { case .a: return peach; case .t: return blue; case .c: return lavender; case .g: return sage }
    }
}

struct DNACopyToolImage: View {
    let tool: DNACopyTool
    var body: some View {
        Group {
            if let asset = tool.asset {
                Image(asset).resizable().scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 15).fill(tool == .binding ? DNACopyStyle.sage : DNACopyStyle.lavender)
                    Image(systemName: tool.symbol)
                        .resizable().scaledToFit().padding(12)
                        .foregroundStyle(DNACopyStyle.ink)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct DNACopyNucleotide: View {
    let base: DNACopyBase
    var selected = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(DNACopyStyle.base(base).gradient)
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(selected ? DNACopyStyle.teal : DNACopyStyle.edge, lineWidth: selected ? 3 : 1.3).allowsHitTesting(false))
            Text(base.rawValue).font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(DNACopyStyle.ink)
            Circle().fill(.white.opacity(0.65)).frame(width: 8, height: 5).offset(x: -11, y: -13)
        }
        .frame(width: 44, height: 44)
        .shadow(color: DNACopyStyle.ink.opacity(0.1), radius: 4, y: 3)
        .accessibilityLabel("\(base.rawValue) DNA nucleotide")
    }
}

struct DNACopyLegend: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { entries }
            VStack(alignment: .leading, spacing: 5) { entries }
        }
        .font(.system(.caption, design: .rounded, weight: .medium))
        .foregroundStyle(DNACopyStyle.muted)
    }
    @ViewBuilder private var entries: some View {
        item("Parental", DNACopyStyle.parental)
        item("New DNA", DNACopyStyle.newDNA)
        item("RNA primer", DNACopyStyle.rna)
    }
    private func item(_ name: String, _ color: Color) -> some View {
        HStack(spacing: 5) { Capsule().fill(color).frame(width: 14, height: 5); Text(name) }
    }
}
