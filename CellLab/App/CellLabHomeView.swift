//
//  CellLabHomeView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//
import SwiftUI

// MARK: - Theme

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum Theme {
    static let background = Color(hex: 0xFCF5EC)
    static let ink = Color(hex: 0x0F3D3A)
    static let teal = Color(hex: 0x0F7F7A)
    static let gold = Color(hex: 0xE8A93A)

    static let mitosis = Color(hex: 0xFDDE92)
    static let meiosis = Color(hex: 0xE6D3E8)
    static let cycle = Color(hex: 0xD1E9CD)
    static let structures = Color(hex: 0xFBD1CE)
    static let respiration = Color(hex: 0xFDDDC3)
    static let dna = Color(hex: 0xCAE1ED)
}

// MARK: - Header

struct Sparkles: View {
    var mirrored = false

    var body: some View {
        ZStack(alignment: .trailing) {
            ForEach([-38.0, 0.0, 38.0], id: \.self) { angle in
                Capsule()
                    .fill(Theme.gold)
                    .frame(width: 15, height: 3.5)
                    .rotationEffect(.degrees(angle), anchor: .trailing)
            }
        }
        .frame(width: 30, height: 44, alignment: .trailing)
        .scaleEffect(x: mirrored ? -1 : 1)
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                Sparkles().modifier(HomeArtworkFloat(distance: 1, tilt: 5))
                Text("CellLab")
                    .font(.system(size: 62, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.7).lineLimit(1)
                NavigationLink(value: DailyFactRoute.settings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.teal.opacity(0.8))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(HomePressStyle())
                .accessibilityLabel("Settings")
                .accessibilityIdentifier("celllab-settings")
            }

            ZStack {
                Ellipse().fill(Theme.cycle.opacity(0.45))
                    .frame(width: 260, height: 70).offset(y: 4)
                Circle().stroke(Theme.teal.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 13, height: 13).offset(x: -132, y: -32)
                    .modifier(HomeArtworkFloat(distance: 4, tilt: 0, phase: 1))
                Circle().fill(Theme.gold.opacity(0.55))
                    .frame(width: 8, height: 8).offset(x: 116, y: -44)
                    .modifier(HomeArtworkFloat(distance: 5, tilt: 0, phase: 3))
                Circle().stroke(Theme.teal.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 19, height: 19).offset(x: 135, y: 18)
                    .modifier(HomeArtworkFloat(distance: 3, tilt: 0, phase: 2))
                Image("art_shelf")
                    .resizable().scaledToFit().frame(maxWidth: 340)
                    .modifier(HomeArtworkFloat(distance: 2, tilt: 0.5))
            }
            .accessibilityHidden(true)
        }
        .padding(.top, 2)
    }
}

struct SectionTitle: View {
    var text: String

    var body: some View {
        HStack(spacing: 14) {
            Capsule().fill(Theme.gold).frame(width: 24, height: 3)
            Text(text)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
            Capsule().fill(Theme.gold).frame(width: 24, height: 3)
        }
    }
}

// MARK: - Cards

enum CardAction {
    case open(String)
    case comingSoon
}

struct ActionPill: View {
    var action: CardAction

    var body: some View {
        switch action {
        case .open(let label):
            HStack(spacing: 5) {
                Text(label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                Capsule()
                    .fill(LinearGradient(colors: [Theme.teal, Color(hex: 0x07615E)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Theme.ink.opacity(0.8), radius: 0, y: 3)
            }
            .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.2))
            .overlay(Capsule().inset(by: 3).stroke(.white.opacity(0.18), lineWidth: 1))
        case .comingSoon:
            Text("Coming soon")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.55))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Capsule().fill(Theme.ink.opacity(0.08)))
        }
    }
}

struct ModuleCard: View {
    let title: String
    let subtitle: String
    let fill: Color
    let image: String
    let action: CardAction

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Ellipse().fill(.white.opacity(0.38))
                    .frame(height: 68).padding(.horizontal, 6).offset(y: 16)
                Image(image)
                    .resizable().scaledToFit()
                    .frame(maxWidth: 150).frame(height: 100)
                    .modifier(HomeArtworkFloat(distance: 3, tilt: 1.3, phase: Double(image.count)))
            }
            .frame(height: 100).padding(.top, 20)
            .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 21, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.8)
                .frame(height: 50)
            Text(subtitle)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .multilineTextAlignment(.center).lineLimit(2)
                .frame(height: 32, alignment: .top)
            Spacer(minLength: 0)
            ActionPill(action: action)
        }
        .padding(10)
        .frame(maxWidth: .infinity).frame(height: 290)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [fill.opacity(0.7), fill], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Theme.ink.opacity(0.16), radius: 0, y: 3)
        }
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.ink.opacity(0.7), lineWidth: 1.4))
    }
}

// MARK: - Home

extension CellLabHomeModule {
    var fill: Color {
        switch self {
        case .structures: Theme.structures
        case .cycle: Theme.cycle
        case .mitosis, .dogma: Theme.mitosis
        case .meiosis: Theme.meiosis
        case .sphase, .technology: Theme.dna
        case .respiration: Theme.respiration
        }
    }
}

struct CellLabHomeView: View {
    let catalog: BiologyCatalog
    @StateObject private var narrator = LessonNarrator.home()
    @State private var selectedModule: CellLabHomeModule?
    @State private var guideHeight: CGFloat = 60

    private var moduleRows: [[CellLabHomeModule]] {
        let modules = CellLabHomeModule.allCases
        return stride(from: 0, to: modules.count, by: 2).map { Array(modules.dropFirst($0).prefix(2)) }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    HeaderView()
                    SectionTitle(text: "Explore the lab")
                    HStack(spacing: 16) {
                        Label("Listen", systemImage: "speaker.wave.2.fill")
                        Label("Game", systemImage: "gamecontroller.fill")
                    }
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.teal)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                    LazyVStack(spacing: 12) {
                        ForEach(moduleRows.indices, id: \.self) { index in
                            VStack(spacing: 10) {
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach(moduleRows[index]) { module in
                                        moduleCard(module)
                                    }
                                }
                                if let selectedModule, moduleRows[index].contains(selectedModule) {
                                    HomeLessonPreview(module: selectedModule) {
                                        narrator.stop()
                                        self.selectedModule = nil
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                // Let the final cards scroll clear of the floating guide.
                .padding(.bottom, guideHeight + 8)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            HomeAxolotlTab(narrator: narrator) {
                if narrator.isPlaying {
                    narrator.stop()
                } else {
                    selectedModule = nil
                    narrator.playStandalone("home.overview")
                }
            }
            .frame(maxWidth: 320, alignment: .trailing)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 2)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { guideHeight = $0 }
        }
        .onDisappear { narrator.stop() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func moduleCard(_ module: CellLabHomeModule) -> some View {
        let speaking = narrator.isPlaying && narrator.currentCueID == module.cueID
        return ZStack(alignment: .topLeading) {
            NavigationLink {
                destination(for: module)
            } label: {
                ModuleCard(title: module.title, subtitle: module.subtitle, fill: module.fill,
                           image: module.image, action: .open("Explore"))
            }
            .buttonStyle(HomePressStyle())
            .accessibilityLabel("\(module.title), \(module.subtitle), Explore lesson")
            .accessibilityValue(module.hasGame ? "Game included" : "Lesson")
            .accessibilityHint(module.hasGame ? "Open the lesson to explore or play its game" : "Open the lesson to explore")
            .accessibilityIdentifier("home-lesson-\(module.id)")

            Button {
                selectedModule = module
                narrator.toggleStandalone(module.cueID)
            } label: {
                Image(systemName: speaking ? "stop.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle().fill(Theme.background)
                            .shadow(color: Theme.ink.opacity(0.18), radius: 0, y: 2)
                    }
                    .overlay(Circle().stroke(Theme.ink.opacity(0.3), lineWidth: 1.2))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(HomePressStyle())
            .padding(8)
            .accessibilityLabel(speaking ? "Stop \(module.title) preview" : "Hear about \(module.title)")
            .accessibilityValue(speaking ? "Speaking" : "Quiet")
            .accessibilityIdentifier("home-preview-\(module.id)")

            if module.hasGame {
                HStack {
                    Spacer(minLength: 0)
                    NavigationLink { HomeGameDestination(module: module) } label: {
                        HomeGameBadge()
                    }
                    .buttonStyle(HomePressStyle())
                    .accessibilityLabel("Play \(module.title) game")
                    .accessibilityHint("Open the game directly")
                    .accessibilityIdentifier("home-play-\(module.id)")
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func destination(for module: CellLabHomeModule) -> some View {
        switch module {
        case .structures: CellStructuresView()
        case .cycle: CellLifeCycleView()
        case .mitosis: MitosisView(catalog: catalog)
        case .meiosis: MeiosisView(catalog: catalog)
        case .sphase: DNAReplicationView()
        case .dogma: CentralDogmaView()
        case .respiration: CellularRespirationView()
        case .technology: DNATechnologyView()
        }
    }
}
