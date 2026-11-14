// DNATechnologyKeyPlayersView.swift — searchable, illustrated definitions.
import SwiftUI

struct DNATechnologyKeyPlayersView: View {
    var initialTermID: String? = nil
    let onTopic: (DTTopic) -> Void
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss
    private var terms: [DTTerm] {
        DTTerm.all.filter { query.isEmpty || ($0.name + " " + $0.definition).localizedCaseInsensitiveContains(query) }
    }
    var body: some View {
        NavigationStack {
            Group {
                if let id=initialTermID, let term=DTTerm.find(id) {
                    DTTermDetail(term:term,onTopic:onTopic)
                } else {
                    List {
                        ForEach(DTTopic.allCases) { topic in
                            let matches=terms.filter { $0.topic == topic }
                            if !matches.isEmpty {
                                Section(topic.article.title) {
                                    ForEach(matches) { term in
                                        NavigationLink {
                                            DTTermDetail(term:term,onTopic:onTopic)
                                        } label: {
                                            HStack(spacing:12) {
                                                DTAssetArt(name:term.asset).frame(width:53,height:53)
                                                VStack(alignment:.leading,spacing:4) {
                                                    Text(term.name).font(.system(.subheadline,design:.rounded,weight:.semibold))
                                                    Text(term.definition).font(.system(.caption,design:.rounded))
                                                        .foregroundStyle(DTPalette.muted).lineLimit(2)
                                                }
                                            }
                                            .padding(.vertical,3).foregroundStyle(DTPalette.ink)
                                        }
                                        .listRowBackground(DTPalette.paper)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .searchable(text:$query,prompt:"Find a tool or concept")
                    .overlay { if terms.isEmpty { ContentUnavailableView.search(text:query) } }
                }
            }
            .background(DTPalette.cream.ignoresSafeArea())
            .navigationTitle(initialTermID == nil ? "Meet the tools" : "Key player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } }
            .tint(DTPalette.teal)
        }
    }
}

private struct DTTermDetail: View {
    let term: DTTerm
    let onTopic: (DTTopic) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                DTAssetArt(name:term.asset)
                    .frame(height:215).frame(maxWidth:.infinity)
                    .padding(16)
                    .background(Color(dtHex:term.topic.article.hex).opacity(0.55),in:RoundedRectangle(cornerRadius:27))
                Text(term.name)
                    .font(.system(.largeTitle,design:.serif,weight:.bold))
                    .fixedSize(horizontal:false,vertical:true)
                    .accessibilityAddTraits(.isHeader)
                Text(term.definition)
                    .font(.system(.body,design:.rounded)).lineSpacing(4)
                    .fixedSize(horizontal:false,vertical:true)
                Button { onTopic(term.topic) } label: {
                    HStack {
                        Text("Explore \(term.topic.article.title)")
                        Spacer(minLength:6)
                        Image(systemName:"arrow.up.right")
                    }
                    .font(.system(.subheadline,design:.rounded,weight:.semibold))
                    .padding(17).frame(maxWidth:.infinity,minHeight:58)
                    .background(Color(dtHex:term.topic.article.hex),in:RoundedRectangle(cornerRadius:20))
                }
                .buttonStyle(.plain)
            }
            .padding(22).frame(maxWidth:620).frame(maxWidth:.infinity)
        }
        .foregroundStyle(DTPalette.ink)
    }
}
