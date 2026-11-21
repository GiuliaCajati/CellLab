// DNATechnologyKeyPlayersView.swift — searchable, illustrated definitions.
import SwiftUI

struct DNATechnologyKeyPlayersView: View {
    var initialTermID: String? = nil
    let onTopic: (DTTopic) -> Void
    @State private var query = ""
    @StateObject private var narration = LessonNarrator.dnaTechnology(initialPhaseID:"term.geneticCode")
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    private var terms: [DTTerm] {
        DTTerm.all.filter { query.isEmpty || ($0.name + " " + $0.definition).localizedCaseInsensitiveContains(query) }
    }
    var body: some View {
        NavigationStack {
            Group {
                if let id=initialTermID, let term=DTTerm.find(id) {
                    DTTermDetail(term:term,onTopic:onTopic)
                } else {
                    VStack(spacing:8) {
                        LessonGuide(narrator:narration,
                                    title:narration.isPlaying ? "Stop" : "Hear tools overview",
                                    cueID:"tools.overview",
                                    action:{ narration.toggleStandalone("tools.overview") },
                                    controlID:"dna-tools-listen",layoutTitle:"Hear tools overview")
                            .foregroundStyle(DTPalette.ink)
                            .padding(.horizontal,20).padding(.top,8)
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
                                            .accessibilityIdentifier("dna-tool-\(term.id)")
                                            .listRowBackground(DTPalette.paper)
                                        }
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .searchable(text:$query,prompt:"Find a tool or concept")
                        .overlay { if terms.isEmpty { ContentUnavailableView.search(text:query) } }
                        .onDisappear { narration.stop() }
                    }
                }
            }
            .background(DTPalette.cream.ignoresSafeArea())
            .navigationTitle(initialTermID == nil ? "Meet the tools" : "Key player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.confirmationAction) {
                Button("Done") { narration.stop(); dismiss() }.accessibilityIdentifier("dna-tools-done")
            } }
            .tint(DTPalette.teal)
        }
        .environmentObject(narration)
        .onChange(of:query) { _,_ in narration.stop() }
        .onChange(of:scenePhase) { _,value in if value != .active { narration.stop() } }
        .onDisappear { narration.stop() }
        .alert("Audio unavailable",isPresented:Binding(
            get:{ narration.errorMessage != nil },set:{ if !$0 { narration.errorMessage=nil } }
        )) { Button("OK",role:.cancel) { narration.errorMessage=nil } }
        message: { Text(narration.errorMessage ?? "Please try again.") }
    }
}

private struct DTTermDetail: View {
    @EnvironmentObject private var narration: LessonNarrator
    let term: DTTerm
    let onTopic: (DTTopic) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                LessonGuide(narrator:narration,
                            title:narration.isPlaying ? "Stop" : "Hear definition",
                            cueID:term.narrationID,
                            action:{ narration.toggleStandalone(term.narrationID) },
                            controlID:"dna-term-listen",layoutTitle:"Hear definition")
                    .foregroundStyle(DTPalette.ink)
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
                Button { narration.stop(); onTopic(term.topic) } label: {
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
                .accessibilityIdentifier("dna-explore-term-topic")
            }
            .padding(22).frame(maxWidth:620).frame(maxWidth:.infinity)
            .accessibilityElement(children:.contain)
            .accessibilityIdentifier("dna-term-detail-\(term.id)")
        }
        .foregroundStyle(DTPalette.ink)
        .onAppear { narration.stop() }
        .onDisappear { narration.stop() }
    }
}
