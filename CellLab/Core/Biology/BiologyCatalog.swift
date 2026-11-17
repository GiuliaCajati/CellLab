import Foundation

nonisolated struct BiologyCatalog: Decodable, Sendable {
    let contentVersion: String
    let entries: [Entry]
    let sources: [Source]

    struct Entry: Decodable, Identifiable, Sendable {
        let id: String
        let title: String
        let kind: Kind
        let context: String
        let summary: String
        let explanation: String
        let playfulAside: String?
        let deeperDetail: String
        let simplification: String
        let reviewStatus: ReviewStatus
        let sourceIDs: [String]
        let evidence: [Evidence]
        let links: [Link]
    }

    enum Kind: String, Decodable, Sendable { case process, structure, complex }
    enum ReviewStatus: String, Decodable, Sendable { case draft, sourceChecked, expertReviewed }
    enum EvidenceStatus: String, Decodable, Sendable { case pending, sourceChecked }

    struct Evidence: Decodable, Identifiable, Sendable {
        let claimID: String
        let statement: String
        let sourceIDs: [String]
        let status: EvidenceStatus
        var id: String { claimID }
    }

    struct Link: Decodable, Hashable, Sendable {
        let label: String
        let targetID: String
    }

    struct Source: Decodable, Identifiable, Sendable {
        let id: String
        let title: String
        let note: String?
        let provider: String?
        let url: URL?
        let accession: String?
        let licenseIdentifier: String?
        let licenseURL: URL?
        let accessedOn: String?
        let verificationNote: String?
        let credits: String?

    }

    func entry(id: String) -> Entry? { entries.first { $0.id == id } }
    func source(id: String) -> Source? { sources.first { $0.id == id } }

    func sources(for entry: Entry) -> [Source] {
        sources.filter { entry.sourceIDs.contains($0.id) }
    }

    func evidence(for source: Source, in entry: Entry) -> [Evidence] {
        entry.evidence.filter { $0.sourceIDs.contains(source.id) }
    }

    static func load(bundle: Bundle = .main) throws -> BiologyCatalog {
        guard let url = bundle.url(forResource: "biology-catalog", withExtension: "json") else {
            throw CatalogError.invalid("Missing biology-catalog.json")
        }
        let data = try Data(contentsOf: url)
        let catalog = try JSONDecoder().decode(Self.self, from: data)
        try catalog.validate()
        return catalog
    }

    func validate() throws {
        let entryIDs = Set(entries.map(\.id))
        let sourceIDs = Set(sources.map(\.id))
        guard !contentVersion.isEmpty else { throw CatalogError.invalid("Missing content version") }
        guard entryIDs.count == entries.count, sourceIDs.count == sources.count else {
            throw CatalogError.invalid("Duplicate catalog IDs")
        }
        guard !entryIDs.contains(""), !sourceIDs.contains("") else {
            throw CatalogError.invalid("Empty catalog ID")
        }

        for source in sources {
            if let url = source.url { try Self.validateHTTPS(url, label: "source \(source.id)") }
            if let url = source.licenseURL { try Self.validateHTTPS(url, label: "license for \(source.id)") }
        }

        for entry in entries {
            guard !entry.title.isEmpty, !entry.context.isEmpty, !entry.sourceIDs.isEmpty else {
                throw CatalogError.invalid("Missing required information: \(entry.id)")
            }
            for link in entry.links where !entryIDs.contains(link.targetID) {
                throw CatalogError.invalid("Broken link from \(entry.id) to \(link.targetID)")
            }
            for sourceID in entry.sourceIDs where !sourceIDs.contains(sourceID) {
                throw CatalogError.invalid("Unknown source \(sourceID) in \(entry.id)")
            }
            for claim in entry.evidence {
                guard !claim.claimID.isEmpty, !claim.statement.isEmpty else {
                    throw CatalogError.invalid("Incomplete evidence in \(entry.id)")
                }
                for sourceID in claim.sourceIDs where !sourceIDs.contains(sourceID) {
                    throw CatalogError.invalid("Unknown source \(sourceID) for claim \(claim.claimID)")
                }
                if claim.status == .sourceChecked && claim.sourceIDs.isEmpty {
                    throw CatalogError.invalid("Source-checked claim has no source: \(claim.claimID)")
                }
            }
        }
    }

    static func validateHTTPS(_ url: URL, label: String) throws {
        guard url.scheme?.lowercased() == "https", url.host != nil else {
            throw CatalogError.invalid("Invalid HTTPS URL for \(label)")
        }
    }
}

enum CatalogError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}
