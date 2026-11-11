import Foundation

enum DNABase: Character, CaseIterable {
    case adenine = "A"
    case thymine = "T"
    case cytosine = "C"
    case guanine = "G"

    var acceptedPrecursor: RNAPrecursor {
        switch self {
        case .adenine: .UTP
        case .thymine: .ATP
        case .cytosine: .GTP
        case .guanine: .CTP
        }
    }

    var complementaryRNA: RNABase { acceptedPrecursor.base }
}

enum RNABase: Character, CaseIterable, CustomStringConvertible {
    case adenine = "A"
    case uracil = "U"
    case cytosine = "C"
    case guanine = "G"
    var description: String { String(rawValue) }
}

enum RNAPrecursor: String, CaseIterable {
    case ATP, UTP, CTP, GTP

    var base: RNABase {
        switch self {
        case .ATP: .adenine
        case .UTP: .uracil
        case .CTP: .cytosine
        case .GTP: .guanine
        }
    }
}

nonisolated enum TranscriptionActivityEvent: Equatable {
    case nucleotideIncorporated(position: Int, base: RNABase, precursor: RNAPrecursor)
    case excerptCompleted
}

struct TranscriptionSession {
    let sequence: SequenceDefinition
    let activity: TranscriptionActivityDefinition
    private let template: [DNABase]
    private(set) var rna: [RNABase]
    private(set) var templatePosition: Int
    private(set) var isExcerptComplete = false

    var rnaString: String { String(rna.map(\.rawValue)) }

    init(sequence: SequenceDefinition, activity: TranscriptionActivityDefinition) throws {
        guard activity.sequenceID == sequence.id else {
            throw TranscriptionDefinitionError.missingSequence(activity.sequenceID)
        }
        let templateBases = try sequence.validatedBases()
        let prefix = activity.alreadyTranscribedRange
        let playable = activity.playableRange
        guard prefix.isValid, playable.isValid,
              prefix.upperBound <= templateBases.count,
              playable.upperBound <= templateBases.count,
              playable.upperBound > playable.lowerBound,
              prefix.lowerBound == 0,
              prefix.upperBound == playable.lowerBound else {
            throw TranscriptionDefinitionError.invalidRanges
        }
        guard sequence.coordinateConvention == "zero-based, half-open, indexing the stored sequence" else {
            throw TranscriptionDefinitionError.unsupportedCoordinateConvention
        }
        self.sequence = sequence
        self.activity = activity
        self.template = templateBases
        self.rna = templateBases[prefix.range].map(\.complementaryRNA)
        self.templatePosition = playable.lowerBound
    }

    mutating func accept(_ precursor: RNAPrecursor) -> [TranscriptionActivityEvent] {
        guard !isExcerptComplete, templatePosition < activity.playableRange.upperBound else { return [] }
        let expectedBase = template[templatePosition]
        guard precursor == expectedBase.acceptedPrecursor else { return [] }

        let position = templatePosition
        let base = precursor.base
        rna.append(base)
        templatePosition += 1
        var events: [TranscriptionActivityEvent] = [
            .nucleotideIncorporated(position: position, base: base, precursor: precursor)
        ]
        if templatePosition == activity.playableRange.upperBound {
            isExcerptComplete = true
            events.append(.excerptCompleted)
        }
        return events
    }
}
