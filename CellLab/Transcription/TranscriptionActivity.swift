import Foundation

enum MoleculeType: String, Decodable { case DNA }
enum StrandRole: String, Decodable { case template }
enum StrandOrientation: String, Decodable { case threePrimeToFivePrime = "3′ → 5′" }

struct NucleotideRange: Decodable, Equatable {
    let lowerBound: Int
    let upperBound: Int

    var range: Range<Int> { lowerBound..<upperBound }
    var isValid: Bool { lowerBound >= 0 && upperBound >= lowerBound }
}

struct SequenceDefinition: Decodable, Identifiable {
    let id: String
    let moleculeType: MoleculeType
    let strandRole: StrandRole
    let storedOrientation: String
    let bases: String
    let provenance: String
    let description: String
    let coordinateConvention: String

    func validatedBases() throws -> [DNABase] {
        guard storedOrientation == StrandOrientation.threePrimeToFivePrime.rawValue else {
            throw TranscriptionDefinitionError.unsupportedOrientation(storedOrientation)
        }
        return try bases.map { symbol in
            guard let base = DNABase(rawValue: symbol) else {
                throw TranscriptionDefinitionError.invalidDNABase(symbol)
            }
            return base
        }
    }
}

struct TranscriptionActivityDefinition: Decodable, Identifiable {
    let id: String
    let contentVersion: String
    let sequenceID: String
    let alreadyTranscribedRange: NucleotideRange
    let playableRange: NucleotideRange
}

struct TranscriptionContent: Decodable {
    let sequences: [SequenceDefinition]
    let activities: [TranscriptionActivityDefinition]

    func validate() throws {
        guard Set(sequences.map(\.id)).count == sequences.count,
              Set(activities.map(\.id)).count == activities.count else {
            throw TranscriptionDefinitionError.duplicateID
        }
        for activity in activities {
            guard !activity.id.isEmpty, !activity.contentVersion.isEmpty else {
                throw TranscriptionDefinitionError.invalidRanges
            }
            guard let sequence = sequences.first(where: { $0.id == activity.sequenceID }) else {
                throw TranscriptionDefinitionError.missingSequence(activity.sequenceID)
            }
            guard !sequence.id.isEmpty else { throw TranscriptionDefinitionError.duplicateID }
            let bases = try sequence.validatedBases()
            let prior = activity.alreadyTranscribedRange
            let playable = activity.playableRange
            guard prior.isValid, playable.isValid,
                  prior.upperBound <= bases.count,
                  playable.upperBound <= bases.count,
                  playable.upperBound > playable.lowerBound,
                  prior.lowerBound == 0,
                  prior.upperBound == playable.lowerBound else {
                throw TranscriptionDefinitionError.invalidRanges
            }
            guard sequence.coordinateConvention == "zero-based, half-open, indexing the stored sequence" else {
                throw TranscriptionDefinitionError.unsupportedCoordinateConvention
            }
        }
    }

    func sequence(id: String) -> SequenceDefinition? { sequences.first { $0.id == id } }
    func activity(id: String) -> TranscriptionActivityDefinition? { activities.first { $0.id == id } }

    static func load(bundle: Bundle = .main) throws -> TranscriptionContent {
        guard let url = bundle.url(forResource: "transcription-activity", withExtension: "json") else {
            throw TranscriptionDefinitionError.missingResource
        }
        let content = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        try content.validate()
        return content
    }
}

enum TranscriptionDefinitionError: LocalizedError, Equatable {
    case missingResource
    case missingSequence(String)
    case invalidDNABase(Character)
    case unsupportedOrientation(String)
    case invalidRanges
    case unsupportedCoordinateConvention
    case duplicateID

    var errorDescription: String? {
        switch self {
        case .missingResource: "Missing transcription-activity.json"
        case .missingSequence(let id): "Activity references missing sequence \(id)"
        case .invalidDNABase(let symbol): "Invalid DNA symbol \(symbol)"
        case .unsupportedOrientation(let orientation): "Unsupported template orientation: \(orientation)"
        case .invalidRanges: "Activity ranges must be valid, adjacent, and within the stored sequence"
        case .unsupportedCoordinateConvention: "Unsupported coordinate convention"
        case .duplicateID: "Duplicate sequence or activity ID"
        }
    }
}
