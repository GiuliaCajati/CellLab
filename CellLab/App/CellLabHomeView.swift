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
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Sparkles()
                Text("CellLab")
                    .font(.system(size: 64, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Sparkles(mirrored: true)
            }


            Image("art_shelf")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 340)
                .accessibilityHidden(true)
        }
    }
}

struct SectionTitle: View {
    var text: String

    var body: some View {
        HStack(spacing: 14) {
            Capsule().fill(Theme.gold).frame(width: 24, height: 3)
            Text(text)
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
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
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Capsule().fill(Theme.teal))
        case .comingSoon:
            Text("Coming soon")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.55))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Capsule().fill(Theme.ink.opacity(0.08)))
        }
    }
}

/// Every topic uses this card, so all six are the same size.
///
///
///
struct LongModuleCard: View {
let title: String
let subtitle: String
let fill: Color
let image: String
let action: CardAction

var body: some View {
    HStack(spacing: 3) {
        Image(image)
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 112)
            .accessibilityHidden(true)
        VStack {
            Text(title)
                .font(.system(size: 21, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 54)

            Text(subtitle)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 38, alignment: .top)

            Spacer(minLength: 0)

            ActionPill(action: action)
        }
    }
    .padding(8)
    .frame(maxWidth: .infinity)
//    .frame(height: 300)
    .background(RoundedRectangle(cornerRadius: 22).fill(fill))
    .overlay(
        RoundedRectangle(cornerRadius: 22)
            .stroke(Theme.ink.opacity(0.8), lineWidth: 1.5)
    )
}
}

struct ModuleCard: View {
    let title: String
    let subtitle: String
    let fill: Color
    let image: String
    let action: CardAction

    var body: some View {
        VStack(spacing: 6) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 112)
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 21, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 54)

            Text(subtitle)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 38, alignment: .top)

            Spacer(minLength: 0)

            ActionPill(action: action)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(RoundedRectangle(cornerRadius: 22).fill(fill))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Theme.ink.opacity(0.8), lineWidth: 1.5)
        )
    }
}

// MARK: - Home

struct CellLabHomeView: View {
    let catalog: BiologyCatalog

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HeaderView()
                    SectionTitle(text: "Explore the lab")
                    
                    NavigationLink {
                        CellLifeCycleView()
                    } label: {
                        LongModuleCard(
                            title: "Cell Life Cycle",
                            subtitle: "Grow. Copy. Divide.",
                            fill: Theme.cycle,
                            image: "art_cycle",
                            action: .open("Living the life \u{2192}")                        )
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(columns: columns, spacing: 14) {
                        NavigationLink {
                            MitosisView(catalog: catalog)
                        } label: {
                            ModuleCard(
                                title: "Mitosis",
                                subtitle: "One becomes two.",
                                fill: Theme.mitosis,
                                image: "art_mitosis",
                                action: .open("Let\u{2019}s split \u{2192}")
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            MeiosisView(catalog: catalog)
                        } label: {
                            ModuleCard(
                                title: "Meiosis",
                                subtitle: "Mix things up.",
                                fill: Theme.meiosis,
                                image: "art_meiosis",
                                action: .open("Let\u{2019}s mix \u{2192}")
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            DNAReplicationView()
                        } label: {
                            ModuleCard(
                                title: "S Phase",
                                subtitle: "DNA replication",
                                fill: Theme.dna,
                                image: "art_s_phase",
                                action: .open("Let\u{2019}s Synthesize \u{2192}")
                            )
                        }.buttonStyle(.plain)
                        

                        
                        ModuleCard(
                            title: "Central Dogma",
                            subtitle: "Transcription. Translation.",
                            fill: Theme.mitosis,
                            image: "art_dogma",
                            action: .comingSoon //.open("Peptide assembly line.")
                        )
                        
                        NavigationLink {
                            CellStructuresView()
                        } label: {
                            ModuleCard(
                                title: "Cell Structures",
                                subtitle: "Meet the tiny team.",
                                fill: Theme.structures,
                                image: "art_structures",
                                action: .open("Let\u{2019}s Explore \u{2192}")
                            )
                        }.buttonStyle(.plain)


                        ModuleCard(
                            title: "Cellular Respiration",
                            subtitle: "ATP, made here.",
                            fill: Theme.respiration,
                            image: "art_respiration",
                            action: .comingSoon
                        )
                    }
                    
                    LongModuleCard(
                        title: "DNA Technology",
                        subtitle: "Small tools. Big possibilities.",
                        fill: Theme.dna,
                        image: "art_dna",
                        action: .comingSoon
                    )

                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
