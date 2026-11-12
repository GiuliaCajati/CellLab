//
//  MitosisKeyPlayersView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//
import SwiftUI


struct MitosisKeyPlayersView: View {
    @State private var expandedPlayer: String?

    private let players = MitosisKeyPlayer.all

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            VStack(alignment: .leading, spacing: 5) {
                Text("Meet the division crew")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("Explore the structures that make cell division possible.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(players) { player in
                    MitosisPlayerCard(
                        player: player,
                        isExpanded: expandedPlayer == player.id
                    ) {
                        withAnimation(.spring(response: 0.35)) {
                            expandedPlayer =
                                expandedPlayer == player.id ? nil : player.id
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct MitosisPlayerCard: View {
    let player: MitosisKeyPlayer
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(player.color.opacity(0.10))

                    MitosisIllustration(name: player.name)
                        .padding(12)
                }
                .frame(height: 115)

                Text(player.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(isExpanded ? "Close details" : "Explore concept")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(player.color)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(player.color)
                }

                if isExpanded {
                    Divider()

                    Text(player.definition)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(player.color.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct MitosisKeyPlayer: Identifiable {
    let name: String
    let definition: String
    let symbol: String
    let color: Color

    var id: String { name }

    static let all: [MitosisKeyPlayer] = [
        .init(
            name: "Chromosomes & Sister Chromatids",
            definition: "After DNA replication, one chromosome has two identical sister chromatids joined at the centromere. In anaphase, they separate; each is now an individual chromosome. Two chromatids do not mean two chromosomes while they remain joined.",
            symbol: "arrow.left.and.right",
            color: .blue
        ),
        .init(
            name: "Centromere & Kinetochore",
            definition: "The centromere is the chromosome region where sister chromatids are joined. Kinetochores are protein complexes assembled at this region; spindle microtubules attach there to move the chromosomes.",
            symbol: "point.3.connected.trianglepath.dotted",
            color: .orange
        ),
        .init(
            name: "Centrosomes & Centrioles",
            definition: "Centrosomes organize the spindle in animal cells. Each contains a pair of barrel-shaped centrioles. The two centrosomes move toward opposite poles as the spindle forms.",
            symbol: "sun.max",
            color: .green
        ),
        .init(
            name: "Spindle Fibers",
            definition: "These microtubules form the mitotic spindle. Kinetochore microtubules move chromosomes and shorten during anaphase. Other spindle microtubules help push the cell's poles apart.",
            symbol: "arrow.left.and.right",
            color: .red
        ),
        .init(
            name: "Nuclear Envelope & Nucleolus",
            definition: "The nuclear envelope surrounds the nucleus. It breaks down during prometaphase so spindle fibers can reach chromosomes, then re-forms around each chromosome set in telophase. The nucleolus disappears during prophase and reappears as the new nuclei form.",
            symbol: "circle.hexagongrid",
            color: .purple
        ),
        .init(
            name: "Chromatin & Histones",
            definition: "Chromatin is DNA together with its associated proteins. DNA wraps around histone proteins to form nucleosomes—beads on a string. Chromatin condenses into compact chromosomes for division and loosens again during telophase.",
            symbol: "waveform.path",
            color: .cyan
        )
    ]
}





private struct MitosisIllustration: View {
    let name: String

    private var assetName: String {
        switch name {
        case "Chromosomes & Sister Chromatids":
            "ChromosomesSisterChromatids"
        case "Centromere & Kinetochore":
            "CentromereKinetochore"
        case "Centrosomes & Centrioles":
            "CentrosomesCentrioles"
        case "Spindle Fibers":
            "SpindleFibers"
        case "Nuclear Envelope & Nucleolus":
            "NuclearEnvelopeNucleolus"
        case "Chromatin & Histones":
            "ChromatinHistones"
        default:
            "ChromosomesSisterChromatids"
        }
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .accessibilityLabel(name)
    }
}




