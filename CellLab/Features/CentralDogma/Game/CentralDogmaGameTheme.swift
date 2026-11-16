import SwiftUI

enum CentralDogmaGameTheme {
    static let cream = color(0xFBF4EA), paper = color(0xFFFDF8), ink = color(0x184C46)
    static let teal = color(0x118782), edge = color(0x54796B), muted = color(0x5E786F)
    static let blue = color(0xC8E7EF), sage = color(0xD0E5C2), lavender = color(0xDECCE9)
    static let butter = color(0xF8EBC3), pink = color(0xF3C9D9), peach = color(0xF3C9B5)
    static func color(_ value: UInt32) -> Color {
        Color(.sRGB, red: Double((value >> 16) & 255) / 255,
              green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
    }
    static func nucleotide(_ value: String) -> Color {
        switch value { case "A": return blue; case "U": return peach; case "C": return sage; default: return lavender }
    }
}

struct CentralDogmaGameRichText: View {
    let value: String
    var body: some View {
        Text((try? AttributedString(markdown: value, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(value))
    }
}
struct CentralDogmaGamePrimaryStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.headline, design: .rounded))
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 16)
            .background(CentralDogmaGameTheme.sage, in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
extension View {
    func centralDogmaGamePanel(_ color: Color = CentralDogmaGameTheme.paper) -> some View {
        self.padding(16).frame(maxWidth: .infinity)
            .background(color, in: RoundedRectangle(cornerRadius: 25))
            .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(CentralDogmaGameTheme.edge.opacity(0.2), lineWidth: 1))
    }
}
