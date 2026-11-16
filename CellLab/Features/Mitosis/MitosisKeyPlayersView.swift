//
//  MitosisKeyPlayersView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/12/26.
//

import SwiftUI

struct MitosisKeyPlayersView: View {
    @EnvironmentObject private var narration: LessonNarrator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPlayer: String? = MitosisKeyPlayer.all.first?.id
    private let players = MitosisKeyPlayer.all

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(players) { player in
                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                                selectedPlayer = player.id
                            }
                        } label: {
                            Text(player.name)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .padding(.horizontal, 12)
                                .frame(minHeight: 44)
                                .background(player.color.opacity(selectedPlayer == player.id ? 0.2 : 0.07), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedPlayer == player.id ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(players) { player in
                        MitosisPlayerCard(player: player, isSelected: selectedPlayer == player.id)
                            .containerRelativeFrame(.horizontal)
                            .id(player.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedPlayer)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 2) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                            selectedPlayer = player.id
                        }
                    } label: {
                        Capsule()
                            .fill(selectedPlayer == player.id
                                  ? player.color
                                  : Color.secondary.opacity(0.25))
                            .frame(width: selectedPlayer == player.id ? 22 : 7, height: 7)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(player.name), \(index + 1) of \(players.count)")
                    .accessibilityAddTraits(selectedPlayer == player.id ? [.isSelected] : [])
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .onChange(of: selectedPlayer) { _, _ in narration.stop() }
    }
}

private struct MitosisPlayerCard: View {
    let player: MitosisKeyPlayer
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MitosisIllustration(name: player.name)
                .padding(14)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(player.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

            HStack {
                Text(player.name)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if isSelected {
                    Spacer(minLength: 4)
                    NarrationSpeakerButton(cueID: player.narrationID, title: player.name)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(player.bulletPoints.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("•")
                            .font(.body.weight(.bold))
                            .foregroundStyle(player.color)
                            .accessibilityHidden(true)
                        Text(point)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 26)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(player.color.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct MitosisKeyPlayer: Identifiable {
    let name: String
    let definition: String
    let symbol: String
    let color: Color
    var id: String { name }
    var narrationID: String {
        "player." + name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    // Preserve the original wording and punctuation; display each sentence as a bullet.
    var bulletPoints: [String] {
        let sentences = definition.components(separatedBy: ". ")
        return sentences.enumerated().map { index, sentence in
            index < sentences.count - 1 ? sentence + "." : sentence
        }
    }

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
