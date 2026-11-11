import Foundation
import Testing
@testable import CellLab

struct CellLabTests {
    @Test func appBundledBiologyCatalogLoadsAndValidates() throws {
        let catalog = try BiologyCatalog.load()
        #expect(catalog.entry(id: "process.human-nuclear-transcription")?.title == "Transcription")
        #expect(catalog.sources(for: catalog.entry(id: "process.human-nuclear-transcription")!).contains { $0.id == "reactome-pol-ii" })
    }

    @Test func appBundledTranscriptionActivityLoadsAndValidates() throws {
        let content = try TranscriptionContent.load()
        let sequence = try #require(content.sequence(id: "sequence.synthetic.transcription-01"))
        let activity = try #require(content.activity(id: "activity.transcription.elongation-01"))
        let session = try TranscriptionSession(sequence: sequence, activity: activity)
        #expect(sequence.bases == "TACGCTAGCA")
        #expect(sequence.provenance == "synthetic")
        #expect(session.rnaString == "AUG")
        #expect(activity.alreadyTranscribedRange.range == 0..<3)
        #expect(activity.playableRange.range == 3..<10)
    }

    @Test func catalogRejectsMissingSourceReference() throws {
        let catalog = try decodeCatalog(sourceIDs: ["missing-source"])
        #expect(throws: CatalogError.self) { try catalog.validate() }
    }

    @Test(arguments: ["http://example.org/source", "not a URL"])
    func catalogRejectsInvalidSourceURLs(_ value: String) throws {
        #expect(throws: (any Error).self) {
            let catalog = try decodeCatalog(sourceIDs: ["source"], sourceURL: value)
            try catalog.validate()
        }
    }

    @Test(arguments: [
        ("A", RNAPrecursor.UTP, RNABase.uracil),
        ("T", RNAPrecursor.ATP, RNABase.adenine),
        ("C", RNAPrecursor.GTP, RNABase.guanine),
        ("G", RNAPrecursor.CTP, RNABase.cytosine)
    ])
    func allFourDNAComplementChoices(_ symbol: String, _ precursor: RNAPrecursor, _ output: RNABase) throws {
        let pair = try fixture(bases: symbol, initialCount: 0)
        var session = try TranscriptionSession(sequence: pair.sequence, activity: pair.activity)
        #expect(session.accept(precursor) == [.nucleotideIncorporated(position: 0, base: output, precursor: precursor), .excerptCompleted])
        #expect(session.rnaString == String(output.rawValue))
    }

    @Test func fixtureStartsWithAUGAndCompletesWithExpectedRNA() throws {
        var session = try bundledSession()
        #expect(session.rnaString == "AUG")
        let inputs: [RNAPrecursor] = [.CTP, .GTP, .ATP, .UTP, .CTP, .GTP, .UTP]
        for precursor in inputs { _ = session.accept(precursor) }
        #expect(session.rnaString == "AUGCGAUCGU")
        #expect(session.isExcerptComplete)
    }

    @Test func incorrectChoiceLeavesSequenceAndPositionUnchanged() throws {
        var session = try bundledSession()
        let beforeRNA = session.rnaString
        let beforePosition = session.templatePosition
        #expect(session.accept(.ATP).isEmpty)
        #expect(session.rnaString == beforeRNA)
        #expect(session.templatePosition == beforePosition)
    }

    @Test func invalidDNASymbolIsRejected() throws {
        let sequence = try fixture(bases: "N", initialCount: 0).sequence
        #expect(throws: TranscriptionDefinitionError.self) { try sequence.validatedBases() }
    }

    @Test func unsupportedOrientationIsRejected() throws {
        var sequence = try fixture(bases: "A", initialCount: 0).sequence
        sequence = SequenceDefinition(id: sequence.id, moleculeType: sequence.moleculeType, strandRole: sequence.strandRole, storedOrientation: "5′ → 3′", bases: sequence.bases, provenance: sequence.provenance, description: sequence.description, coordinateConvention: sequence.coordinateConvention)
        #expect(throws: TranscriptionDefinitionError.unsupportedOrientation("5′ → 3′")) { try sequence.validatedBases() }
    }

    @Test func invalidRangesAreRejected() throws {
        let sequence = try fixture(bases: "AC", initialCount: 1).sequence
        let invalidActivity = TranscriptionActivityDefinition(id: "bad-range", contentVersion: "0.1.0", sequenceID: sequence.id, alreadyTranscribedRange: .init(lowerBound: 0, upperBound: 1), playableRange: .init(lowerBound: 3, upperBound: 8))
        #expect(throws: TranscriptionDefinitionError.invalidRanges) { try TranscriptionSession(sequence: sequence, activity: invalidActivity) }
    }

    @Test func sevenAcceptedAdditionsEmitOneCompletionAndLaterInputsDoNothing() throws {
        var session = try bundledSession()
        let inputs: [RNAPrecursor] = [.CTP, .GTP, .ATP, .UTP, .CTP, .GTP, .UTP]
        var completionCount = 0
        var incorporationCount = 0
        for precursor in inputs {
            for event in session.accept(precursor) {
                if event == .excerptCompleted { completionCount += 1 }
                if case .nucleotideIncorporated = event { incorporationCount += 1 }
            }
        }
        #expect(incorporationCount == 7)
        #expect(completionCount == 1)
        #expect(session.accept(.UTP).isEmpty)
        #expect(completionCount == 1)
        #expect(incorporationCount == 7)
        #expect(session.rnaString == "AUGCGAUCGU")
    }

    private func bundledSession() throws -> TranscriptionSession {
        let content = try TranscriptionContent.load()
        return try TranscriptionSession(
            sequence: #require(content.sequence(id: "sequence.synthetic.transcription-01")),
            activity: #require(content.activity(id: "activity.transcription.elongation-01"))
        )
    }

    private func fixture(bases: String, initialCount: Int) throws -> (sequence: SequenceDefinition, activity: TranscriptionActivityDefinition) {
        let sequence = SequenceDefinition(id: "fixture-sequence", moleculeType: .DNA, strandRole: .template, storedOrientation: "3′ → 5′", bases: bases, provenance: "synthetic", description: "Invalid-input test fixture.", coordinateConvention: "zero-based, half-open, indexing the stored sequence")
        let activity = TranscriptionActivityDefinition(id: "fixture-activity", contentVersion: "0.1.0", sequenceID: sequence.id, alreadyTranscribedRange: .init(lowerBound: 0, upperBound: initialCount), playableRange: .init(lowerBound: initialCount, upperBound: bases.count))
        return (sequence, activity)
    }

    private func decodeCatalog(sourceIDs: [String], sourceURL: String? = nil) throws -> BiologyCatalog {
        let urlField = sourceURL.map { "\"url\":\"\($0)\"," } ?? ""
        let sourceList = sourceIDs.map { "\"\($0)\"" }.joined(separator: ",")
        let json = """
        {"contentVersion":"test","entries":[{"id":"entry","title":"Entry","kind":"process","context":"test","summary":"summary","explanation":"explanation","deeperDetail":"detail","simplification":"limit","reviewStatus":"draft","sourceIDs":[\(sourceList)],"evidence":[],"links":[]}],"sources":[{"id":"source","title":"Source",\(urlField)"provider":"Test"}]}
        """
        return try JSONDecoder().decode(BiologyCatalog.self, from: Data(json.utf8))
    }
}
