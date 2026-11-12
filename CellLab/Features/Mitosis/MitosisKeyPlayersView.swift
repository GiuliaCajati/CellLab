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

                    MitosisIllustration(name: player.name, color: player.color)
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
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            ZStack {
                switch name {

                case "Chromosomes & Sister Chromatids":
                    ZStack {
                        Capsule()
                            .fill(color.gradient)
                            .frame(width: 19, height: 83)
                            .rotationEffect(.degrees(40))

                        Capsule()
                            .fill(color.gradient)
                            .frame(width: 19, height: 83)
                            .rotationEffect(.degrees(-40))

                        Circle()
                            .fill(.yellow)
                            .frame(width: 15, height: 15)
                    }

                case "Centromere & Kinetochore":
                    ZStack {
                        Capsule()
                            .fill(color.gradient)
                            .frame(width: 17, height: 78)
                            .rotationEffect(.degrees(40))

                        Capsule()
                            .fill(color.gradient)
                            .frame(width: 17, height: 78)
                            .rotationEffect(.degrees(-40))

                        Circle()
                            .fill(.yellow)
                            .frame(width: 18, height: 18)

                        Circle()
                            .stroke(.orange, lineWidth: 2)
                            .frame(width: 30, height: 30)
                    }

                case "Centrosomes & Centrioles":
                    HStack(spacing: 28) {
                        centriolePair
                            .rotationEffect(.degrees(-35))

                        centriolePair
                            .rotationEffect(.degrees(35))
                    }

                case "Spindle Fibers":
                    ZStack {
                        ForEach(0..<7) { index in
                            Path { path in
                                path.move(to: CGPoint(x: 5, y: h / 2))
                                path.addQuadCurve(
                                    to: CGPoint(x: w - 5, y: h / 2),
                                    control: CGPoint(
                                        x: w / 2,
                                        y: CGFloat(index) * 12 + 8
                                    )
                                )
                            }
                            .stroke(
                                color.opacity(0.85),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                        }

                        Image(systemName: "xmark")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.blue)
                    }

                case "Nuclear Envelope & Nucleolus":
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.16))
                            .frame(width: 85, height: 85)

                        Circle()
                            .stroke(
                                color,
                                style: StrokeStyle(
                                    lineWidth: 3,
                                    dash: [5, 4]
                                )
                            )
                            .frame(width: 85, height: 85)

                        Circle()
                            .fill(color.gradient)
                            .frame(width: 28, height: 28)
                    }

                case "Chromatin & Histones":
                    VStack(spacing: 0) {
                        HStack(spacing: 3) {
                            ForEach(0..<5) { _ in
                                Circle()
                                    .fill(color.opacity(0.75))
                                    .frame(width: 17, height: 17)
                            }
                        }

                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 12))
                            path.addCurve(
                                to: CGPoint(x: w, y: 12),
                                control1: CGPoint(x: w * 0.3, y: -10),
                                control2: CGPoint(x: w * 0.7, y: 34)
                            )
                        }
                        .stroke(.blue, lineWidth: 3)
                        .frame(height: 25)
                    }

                default:
                    Image(systemName: "circle")
                        .font(.largeTitle)
                        .foregroundStyle(color)
                }
            }
            .frame(width: w, height: h)
        }
    }

    private var centriolePair: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { _ in
                Capsule()
                    .fill(color.gradient)
                    .frame(width: 9, height: 43)
            }
        }
    }
}

