import SwiftUI

/// The lesson card and key-player page share one definition and one recording.
struct MeiHomologsCard: View {
    private let term = MeiTerm.all[4]
    private var paragraphs: [String] { term.definition.components(separatedBy: "\n\n") }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("What is a homologous pair?")
                    .font(.system(.headline, design: .rounded))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                NarrationSpeakerButton(cueID: "player.term-4", title: "homologous chromosomes")
            }
            Text(paragraphs[0])
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Text("Example: your two copies of chromosome 9")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
            MeiHomologPairArt()
                .aspectRatio(340.0 / 190.0, contentMode: .fit)
            Text("Same gene. Same position. Versions can differ.")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            DisclosureGroup("Genes, alleles, and traits") {
                Text(paragraphs.dropFirst().joined(separator: "\n\n"))
                    .font(.body)
                    .foregroundStyle(MeiPalette.ink.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
        }
        .padding(18)
        .foregroundStyle(MeiPalette.ink)
        .background(MeiPalette.lilac, in: RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26).stroke(MeiPalette.ink.opacity(0.7), lineWidth: 1.5)
        }
    }
}

/// A schematic gene address, aligned on the two unreplicated homologs.
struct MeiHomologPairArt: View {
    var body: some View {
        Canvas { context, size in
            MeiDrawing.fit(&context, size: size, width: 340, height: 190)
            func label(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat = 13) {
                context.draw(Text(text).font(.system(size: size, weight: .semibold, design: .rounded))
                    .foregroundStyle(MeiPalette.ink), at: CGPoint(x: x, y: y))
            }
            var guide = Path()
            guide.move(to: CGPoint(x: 85, y: 116))
            guide.addLine(to: CGPoint(x: 255, y: 116))
            context.stroke(guide, with: .color(MeiPalette.ink.opacity(0.4)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            for parent in 0..<2 {
                let x: CGFloat = parent == 0 ? 85 : 255
                let color = parent == 0 ? MeiPalette.rose : MeiPalette.blue
                let chromosome = Path(roundedRect: CGRect(x: x - 18, y: 40, width: 36, height: 108), cornerRadius: 18)
                context.fill(chromosome, with: .color(color.opacity(0.35)))
                context.stroke(chromosome, with: .color(MeiPalette.ink), lineWidth: 2)
                let allele = Path(ellipseIn: CGRect(x: x - 14, y: 102, width: 28, height: 28))
                context.fill(allele, with: .color(.white))
                context.stroke(allele, with: .color(color), lineWidth: 3)
                label(parent == 0 ? "From mom" : "From dad", x: x, y: 20)
                label(parent == 0 ? "A" : "B", x: x, y: 116)
                label(parent == 0 ? "A allele" : "B allele", x: x, y: 166)
            }
            label("ABO gene", x: 170, y: 94)
            label("same position", x: 170, y: 136, size: 11)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A homologous pair of chromosome 9s: one from mom with an A allele, one from dad with a B allele. The ABO gene is marked at the same position on both chromosomes.")
    }
}
