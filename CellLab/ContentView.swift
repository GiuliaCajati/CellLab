//
//  ContentView.swift
//  CellLab
//
//  Created by Giulia Cajati on 11/11/26.
//

import SwiftUI

private enum LearningArea: String, CaseIterable, Identifiable {
    case geneExpression
    case cellDivision
    case cellularRespiration
    case photosynthesis
    case partsOfTheCell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .geneExpression: "Gene Expression"
        case .cellDivision: "Cell Division"
        case .cellularRespiration: "Cellular Respiration"
        case .photosynthesis: "Photosynthesis"
        case .partsOfTheCell: "Parts of the Cell"
        }
    }

    var symbol: String {
        switch self {
        case .geneExpression: "text.book.closed"
        case .cellDivision: "square.split.2x2"
        case .cellularRespiration: "bolt"
        case .photosynthesis: "leaf"
        case .partsOfTheCell: "magnifyingglass"
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Little cells. Big discoveries.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .listRowBackground(Color.clear)
                }

                Section("Explore") {
                    ForEach(LearningArea.allCases) { area in
                        if area == .geneExpression {
                            NavigationLink {
                                GeneExpressionView()
                            } label: {
                                Label(area.title, systemImage: area.symbol)
                                    .padding(.vertical, 8)
                            }
                        } else {
                            HStack {
                                Label(area.title, systemImage: area.symbol)

                                Spacer()

                                Text("Coming soon")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .navigationTitle("CellLab")
            .tint(.teal)
        }
    }
}

private struct GeneExpressionView: View {
    var body: some View {
        List {
            Section("First activity") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcription")
                        .font(.headline)

                    Text("Human nuclear transcription")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("In development")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Gene Expression")
    }
}

