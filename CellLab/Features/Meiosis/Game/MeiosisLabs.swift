import SwiftUI

/// Optional source-specified modes. These sheets leave the main meiosis session intact.
struct MeiosisDiversityLab: View {
    let session: MeiosisSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mode: Mode = .fertilization
    @State private var sperm: Int?
    @State private var egg: Int?
    @State private var fused = false
    @State private var spermStep = 0
    @State private var eggStep = 0
    @State private var plantStep = 0
    private let accent = Color(red: 0.15, green: 0.48, blue: 0.43)
    private enum Mode: String, CaseIterable, Identifiable {
        case fertilization = "Fusion", sperm = "Sperm", egg = "Egg", plants = "Plants"
        var id: Self { self }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Mode", selection: $mode) { ForEach(Mode.allCases) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented)
                switch mode {
                case .fertilization: fertilization
                case .sperm: spermatogenesis
                case .egg: oogenesis
                case .plants: plants
                }
            }
            .padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .background(Color.labCream.ignoresSafeArea()).tint(accent)
        .navigationTitle("Diversity & packaging").navigationBarTitleDisplayMode(.inline)
    }

    private var fertilization: some View {
        VStack(alignment: .leading, spacing: 18) {
            labTitle("One of each. A new combination.", "Random fertilization")
            Text("Human independent assortment gives 8,388,608 chromosome combinations per sperm or egg. Select one of each from these sample choices.")
            Text("SPERM").font(.caption.bold()).foregroundStyle(.secondary)
            gameteChoices(selected: sperm, kind: "sperm") { sperm = $0; fused = false }
            Text("EGG").font(.caption.bold()).foregroundStyle(.secondary)
            gameteChoices(selected: egg, kind: "egg") { egg = $0; fused = false }
            Text("Four sample choices are shown; they represent a much larger set of possibilities.")
                .font(.caption).foregroundStyle(.secondary)
            Button("Fuse gametes", systemImage: "arrow.triangle.merge") {
                withAnimation(reduceMotion ? nil : .spring(response: 0.55)) { fused = true }
            }
            .buttonStyle(.borderedProminent).disabled(sperm == nil || egg == nil || fused)
            if fused {
                HStack(spacing: 18) {
                    MeiosisLabCell(ploidy: "2n", caption: "Zygote", diameter: 96)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diploid again").font(.system(.title3, design: .serif, weight: .bold))
                        Text("Human gametes: 23 + 23 → 46 chromosomes.")
                        Text("Sperm sample \((sperm ?? 0) + 1) + egg sample \((egg ?? 0) + 1)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .transition(.scale.combined(with: .opacity)).labPanel()
            }
            if session.stage == .complete {
                Text("Your illustrated gametes: " + (0..<4).map { session.gameteAlleles($0) }.joined(separator: "; "))
                    .font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("8,388,608 × 8,388,608").font(.system(.headline, design: .rounded))
                Text("70,368,744,177,664").font(.system(.title2, design: .rounded, weight: .bold)).minimumScaleFactor(0.7).lineLimit(1)
                Text("More than 70 trillion chromosome combinations per couple, before counting the extra diversity from crossing over.").font(.subheadline)
            }
            .labPanel()
        }
    }
    private func gameteChoices(selected: Int?, kind: String, choose: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Button { choose(index) } label: {
                    VStack(spacing: 6) {
                        MeiosisLabCell(ploidy: "n", caption: "\(index + 1)", diameter: 54, sperm: kind == "sperm")
                        Image(systemName: selected == index ? "checkmark.circle.fill" : "circle")
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(accent.opacity(selected == index ? 0.15 : 0.04), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected == index ? accent : .clear, lineWidth: 2))
                }
                .buttonStyle(.plain).accessibilityLabel("Sample \(kind) \(index + 1), haploid")
                .accessibilityAddTraits(selected == index ? .isSelected : [])
            }
        }
    }
    private var spermatogenesis: some View {
        VStack(alignment: .leading, spacing: 18) {
            labTitle("Four equal packages.", "Spermatogenesis · testes")
            Text(["Begin with a diploid spermatogonium.", "The lineage produces a primary spermatocyte, prepared for meiosis.",
                  "Meiosis I produces two equal haploid secondary spermatocytes.", "Meiosis II produces four equal haploid spermatids.",
                  "Spermatids mature into four motile sperm."][spermStep])
            let count = spermStep < 2 ? 1 : spermStep == 2 ? 2 : 4
            let name = ["Spermatogonium", "Primary spermatocyte", "Secondary spermatocyte", "Spermatid", "Sperm"][spermStep]
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 115))], spacing: 18) {
                ForEach(0..<count, id: \.self) { _ in
                    MeiosisLabCell(ploidy: spermStep < 2 ? "2n" : "n", caption: name, diameter: 82, sperm: spermStep == 4)
                }
            }
            .id(spermStep).transition(.scale.combined(with: .opacity)).labPanel()
            stepControls(step: $spermStep, maximum: 4,
                         next: ["Mitosis & preparation", "Meiosis I", "Meiosis II", "Mature sperm", "Complete"][spermStep])
            Text("Diploid spermatogonium → primary spermatocyte → two secondary spermatocytes → four spermatids → four sperm.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }
    private var oogenesis: some View {
        VStack(alignment: .leading, spacing: 18) {
            labTitle("One large package.", "Oogenesis · ovaries")
            Text(["Begin with a diploid oogonium.", "The lineage produces a primary oocyte, prepared for meiosis.",
                  "Unequal cytokinesis makes one large secondary oocyte and one small polar body.",
                  "Fertilization allows meiosis II to finish: one large ovum and another polar body. The ovum keeps most cytoplasm and organelles."][eggStep])
            HStack(alignment: .center, spacing: 16) {
                MeiosisLabCell(ploidy: eggStep < 2 ? "2n" : "n",
                               caption: ["Oogonium", "Primary oocyte", "Secondary oocyte", "Ovum"][eggStep], diameter: 130)
                if eggStep >= 2 {
                    VStack(spacing: 16) {
                        MeiosisLabCell(ploidy: "n", caption: "Polar body", diameter: 44)
                        if eggStep == 3 { MeiosisLabCell(ploidy: "n", caption: "New polar body", diameter: 44) }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity).labPanel()
            stepControls(step: $eggStep, maximum: 3,
                         next: ["Mitosis & preparation", "Meiosis I · unequal split", "Fertilize & finish meiosis II", "Complete"][eggStep])
            if eggStep == 3 {
                Text("The ovum is shown before fusion of egg and sperm nuclei. Nuclear fusion produces the diploid zygote.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Text("The secondary oocyte completes meiosis II only if fertilized. Cell sizes are schematic; the first polar body is shown without an additional division.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private var plants: some View {
        VStack(alignment: .leading, spacing: 18) {
            labTitle("Spores first. Gametes later.", "Plant alternation of generations")
            Text(["Start with a diploid sporophyte. Its germ cells undergo meiosis.", "Meiosis produces haploid spores.",
                  "Spores undergo mitosis to grow into multicellular haploid gametophytes.",
                  "The haploid gametophyte produces haploid gametes by mitosis."][plantStep])
            VStack(spacing: 20) {
                Image(systemName: plantStep == 2 ? "leaf.fill" : "leaf")
                    .font(.system(size: 38)).foregroundStyle(accent)
                if plantStep == 0 {
                    MeiosisLabCell(ploidy: "2n", caption: "Sporophyte", diameter: 100)
                } else if plantStep == 1 {
                    HStack { ForEach(0..<4, id: \.self) { _ in MeiosisLabCell(ploidy: "n", caption: "Spore", diameter: 54) } }
                } else if plantStep == 2 {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { _ in MeiosisLabCell(ploidy: "n", caption: "", diameter: 42) }
                        }
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { _ in MeiosisLabCell(ploidy: "n", caption: "", diameter: 42) }
                        }
                        Text("Multicellular gametophyte").font(.subheadline.bold()).padding(.top, 8)
                    }
                } else {
                    HStack(spacing: 24) {
                        MeiosisLabCell(ploidy: "n", caption: "Gamete", diameter: 70)
                        MeiosisLabCell(ploidy: "n", caption: "Gamete", diameter: 70)
                    }
                }
            }
            .id(plantStep).frame(maxWidth: .infinity).labPanel()
            stepControls(step: $plantStep, maximum: 3,
                         next: ["Meiosis → spores", "Mitosis → gametophyte", "Mitosis → gametes", "Complete"][plantStep])
            Text("In this plant life cycle, meiosis makes spores. Gametophytes make gametes by mitosis.")
                .font(.system(.headline, design: .rounded)).labPanel()
        }
    }
    private func stepControls(step: Binding<Int>, maximum: Int, next: String) -> some View {
        HStack {
            Button("Reset", systemImage: "arrow.counterclockwise") { animate { step.wrappedValue = 0 } }
                .buttonStyle(.bordered)
            Spacer()
            if step.wrappedValue < maximum {
                Button(next, systemImage: "arrow.right") { animate { step.wrappedValue += 1 } }.buttonStyle(.borderedProminent)
            } else { Label("Complete", systemImage: "checkmark.circle.fill").font(.headline) }
        }
    }
    private func animate(_ change: () -> Void) { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.6), change) }
}

struct MeiosisErrorLab: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mode: Mode = .nondisjunction
    @State private var division = 1
    @State private var ranError = false
    @State private var structural: Structural = .deletion
    @State private var appliedChange = false
    @State private var hybridAttempted = false
    @State private var sets = 3
    private let accent = Color(red: 0.63, green: 0.25, blue: 0.40)
    private enum Mode: String, CaseIterable, Identifiable {
        case nondisjunction = "Division", structure = "Structure", polyploidy = "Sets", hybrid = "Hybrid"
        var id: Self { self }
    }
    private enum Structural: String, CaseIterable, Identifiable {
        case deletion = "Deletion", duplication = "Duplication", inversion = "Inversion", translocation = "Translocation"
        var id: Self { self }
        var explanation: String {
            switch self {
            case .deletion: "A chromosome segment is lost."
            case .duplication: "A chromosome segment is repeated."
            case .inversion: "A segment flips and is reinserted backwards."
            case .translocation: "Segments exchange between nonhomologous chromosomes."
            }
        }
        var result: String {
            switch self {
            case .deletion: "ABDEFG"
            case .duplication: "ABCCDEFG"
            case .inversion: "ABEDCFG"
            case .translocation: "ABCxyz"
            }
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Error challenge", selection: $mode) { ForEach(Mode.allCases) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented)
                switch mode {
                case .nondisjunction: nondisjunction
                case .structure: structuralChanges
                case .polyploidy: polyploidy
                case .hybrid: hybrid
                }
            }
            .padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .background(Color.labCream.ignoresSafeArea()).tint(accent)
        .navigationTitle("Division error lab").navigationBarTitleDisplayMode(.inline)
    }
    private var nondisjunction: some View {
        VStack(alignment: .leading, spacing: 18) {
            labTitle("A missed separation.", "Nondisjunction")
            Picker("Anaphase error", selection: $division) {
                Text("Meiosis I").tag(1); Text("Meiosis II").tag(2)
            }
            .pickerStyle(.segmented).onChange(of: division) { _, _ in ranError = false }
            Text(division == 1 ? "One homologous pair fails to separate in anaphase I." : "One sister-chromatid pair fails to separate in one of the two cells during anaphase II.")
            Button(ranError ? "Reset challenge" : "Run division error", systemImage: ranError ? "arrow.counterclockwise" : "arrow.triangle.branch") {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.7)) { ranError.toggle() }
            }
            .buttonStyle(.borderedProminent)
            let counts = ranError ? (division == 1 ? [3, 3, 1, 1] : [2, 2, 3, 1]) : [2, 2, 2, 2]
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<4, id: \.self) { index in errorProduct(index, count: counts[index]) }
            }
            .labPanel()
            Text("Diagram: n = 2. The n + 1 / n − 1 outcomes apply to any chromosome count.")
                .font(.caption).foregroundStyle(.secondary)
            if ranError {
                Text(division == 1 ? "100% abnormal: two n + 1 and two n − 1 gametes." : "50% normal (n), 25% n + 1, 25% n − 1.")
                    .font(.system(.headline, design: .rounded)).labPanel()
            }
            Text("Incorrect spindle attachment or separation can produce aneuploid gametes. Fertilization involving an abnormal gamete can produce aneuploidy.").font(.subheadline)
            VStack(alignment: .leading, spacing: 10) {
                Text("Examples of aneuploidy").font(.headline)
                Text("Trisomy 21 · Down syndrome\n47,XXX\n47,XXY · Klinefelter syndrome\n47,XYY · Jacobs syndrome\n45,X · Turner syndrome (often written XO)")
                    .lineSpacing(7)
                Text("45,Y (YO) is nonviable: an X chromosome is essential for survival.").font(.subheadline)
            }
            .labPanel()
        }
    }
    private func errorProduct(_ index: Int, count: Int) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Image("CellLabCellShell").resizable().frame(width: 100, height: 84)
                HStack(spacing: 7) {
                    ForEach(0..<count, id: \.self) { chromosome in
                        Capsule().fill(chromosome == count - 1 ? Color.labBlue : Color.labPurple)
                            .frame(width: 8, height: chromosome == count - 1 ? 25 : 34)
                            .overlay(Capsule().stroke(Color.labInk.opacity(0.7), lineWidth: 1))
                    }
                }
            }
            Text(count == 2 ? "n · normal" : count == 3 ? "n + 1 · extra" : "n − 1 · missing")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(count == 2 ? Color.labTeal : accent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gamete \(index + 1): \(count == 2 ? "normal" : count == 3 ? "one extra chromosome" : "one missing chromosome")")
    }
    private var structuralChanges: some View {
        VStack(alignment: .leading, spacing: 18) {
            labTitle("A segment goes off script.", "Structural chromosome changes")
            Picker("Structural change", selection: $structural) {
                ForEach(Structural.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.menu).onChange(of: structural) { _, _ in appliedChange = false }
            Text(structural.explanation)
            VStack(alignment: .leading, spacing: 16) {
                Text(appliedChange ? "AFTER" : "BEFORE").font(.caption.bold()).foregroundStyle(.secondary)
                segments(appliedChange ? structural.result : "ABCDEFG", color: .labPurple)
                if structural == .translocation {
                    segments(appliedChange ? "uvwDEFG" : "uvwxyz", color: .labBlue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).labPanel()
            Button(appliedChange ? "Reset segments" : "Apply \(structural.rawValue.lowercased())", systemImage: "arrow.left.arrow.right") {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.6)) { appliedChange.toggle() }
            }
            .buttonStyle(.borderedProminent)
            Text("Letters are illustrative chromosome-segment markers. Misaligned exchanges can cause loss or repetition of segments.").font(.caption).foregroundStyle(.secondary)
            if structural == .translocation {
                Text("A translocation involving chromosomes 9 and 22 can cause chronic myelogenous leukemia (CML). The letter blocks above are a generic illustration.")
                    .font(.subheadline).labPanel()
            }
        }
    }
    private func segments(_ value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            ForEach(Array(value.enumerated()), id: \.offset) { _, letter in
                Text(String(letter)).font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .foregroundStyle(.white)
                    .background((letter.isLowercase ? Color.labBlue : color), in: RoundedRectangle(cornerRadius: 7))
            }
        }
        .accessibilityElement(children: .ignore).accessibilityLabel(value.map(String.init).joined(separator: ", "))
    }
    private var polyploidy: some View {
        VStack(alignment: .leading, spacing: 18) {
            labTitle("An entire extra set.", "Polyploidy")
            Text("Polyploidy means extra full chromosome sets. Failure to separate complete sets can contribute to polyploidy.")
            Picker("Full chromosome sets", selection: $sets) {
                Text("3n").tag(3); Text("4n").tag(4); Text("6n").tag(6)
            }
            .pickerStyle(.segmented)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 16) {
                ForEach(0..<sets, id: \.self) { index in
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Capsule().fill(Color.labPurple).frame(width: 10, height: 44)
                            Capsule().fill(Color.labBlue).frame(width: 10, height: 30)
                        }
                        Text("Set \(index + 1)").font(.caption.bold())
                    }
                    .padding(12).background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .labPanel()
            Text(sets == 3 ? "3n · Triploidy can occur in human embryos." : sets == 4 ? "4n · Tetraploid wheat has four full chromosome sets." : "6n · Hexaploid wheat has six full chromosome sets.")
                .font(.system(.headline, design: .rounded))
            Text("Each illustrated set contains two chromosome types. Aneuploidy changes individual chromosome numbers; polyploidy changes whole sets.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private var hybrid: some View {
        VStack(alignment: .leading, spacing: 18) {
            labTitle("Can every chromosome find a match?", "Hybrid pairing challenge")
            HStack(spacing: 18) {
                VStack(spacing: 6) { Text("31").font(.system(size: 44, weight: .bold, design: .rounded)); Text("Donkey") }
                    .foregroundStyle(Color.labPurple)
                Text("+").font(.title)
                VStack(spacing: 6) { Text("32").font(.system(size: 44, weight: .bold, design: .rounded)); Text("Horse") }
                    .foregroundStyle(Color.labBlue)
            }
            .frame(maxWidth: .infinity).labPanel()
            Text("Mule · 63 chromosomes").font(.headline)
            Button(hybridAttempted ? "Reset pairing" : "Attempt synapsis", systemImage: hybridAttempted ? "arrow.counterclockwise" : "link") {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.5)) { hybridAttempted.toggle() }
            }
            .buttonStyle(.borderedProminent)
            if hybridAttempted {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Pairing halted", systemImage: "exclamationmark.triangle").font(.headline)
                    Text("Unpaired chromosomes and structural mismatches interfere with proper homolog pairing. This challenge cannot proceed through normal synapsis.")
                }
                .labPanel().transition(.scale.combined(with: .opacity))
            }
            Text("The challenge illustrates the mule example in the supplied specification. It does not treat every hybrid as infertile.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct MeiosisLabCell: View {
    let ploidy: String
    let caption: String
    var diameter: CGFloat = 72
    var sperm = false
    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                if sperm {
                    Path { path in
                        path.move(to: CGPoint(x: diameter * 0.48, y: diameter * 0.45))
                        path.addCurve(to: CGPoint(x: diameter * 0.9, y: diameter * 0.94),
                                      control1: CGPoint(x: diameter * 1.15, y: diameter * 0.55),
                                      control2: CGPoint(x: diameter * 0.40, y: diameter * 0.90))
                    }
                    .stroke(Color.labTeal, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                Image("CellLabCellShell").resizable()
                    .frame(width: sperm ? diameter * 0.64 : diameter, height: sperm ? diameter * 0.64 : diameter)
                    .offset(x: sperm ? -diameter * 0.15 : 0, y: sperm ? -diameter * 0.15 : 0)
                Text(ploidy).font(.system(size: diameter * 0.25, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.labPurple)
                    .offset(x: sperm ? -diameter * 0.15 : 0, y: sperm ? -diameter * 0.15 : 0)
            }
            .frame(width: diameter, height: diameter)
            if !caption.isEmpty { Text(caption).font(.system(.caption, design: .rounded, weight: .semibold)).multilineTextAlignment(.center) }
        }
        .accessibilityElement(children: .combine)
    }
}
private func labTitle(_ title: String, _ subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(subtitle.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
        Text(title).font(.system(.title2, design: .serif, weight: .bold))
    }
}
private extension View {
    func labPanel() -> some View {
        self.padding(18).background(Color.labPanel, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.labTeal.opacity(0.2), lineWidth: 1))
    }
}
private extension Color {
    static let labPurple = Color(red: 0.45, green: 0.29, blue: 0.72)
    static let labBlue = Color(red: 0.15, green: 0.54, blue: 0.70)
    static let labInk = Color(red: 0.12, green: 0.23, blue: 0.25)
    static let labTeal = Color(red: 0.12, green: 0.47, blue: 0.41)
    static let labCream = Color(uiColor: .systemGroupedBackground)
    static let labPanel = Color(uiColor: .secondarySystemGroupedBackground)
}
