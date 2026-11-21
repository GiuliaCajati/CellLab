// DNATechnologyView.swift — add to CellLab's existing NavigationStack.
import SwiftUI

private enum DTRoute: Identifiable {
    case tools, term(String)
    var id: String { switch self { case .tools: "tools"; case .term(let id): "term-" + id } }
}

struct DNATechnologyView: View {
    @State private var topic: DTTopic = .pcr
    @State private var stageIndex = 0
    @State private var cycles = 20
    @State private var route: DTRoute?
    @State private var playing = true
    @State private var clock = DTMotionClock()
    @State private var startedAt = 0.0
    @State private var showDetails = false
    @StateObject private var narration = LessonNarrator.dnaTechnology()
    @State private var hasStartedOverview = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var article: DTArticle { topic.article }
    private var stage: DTStage { article.stages[min(stageIndex,article.stages.count-1)] }
    private var sceneID: String { topic.rawValue + "-" + stage.id }
    private var shouldAnimate: Bool { playing && !reduceMotion && scenePhase == .active && route?.id == nil }
    private var topicIndex: Int { DTTopic.allCases.firstIndex(of:topic) ?? 0 }
    private var selectedCueID: String { topic.narrationID(for: stage) }

    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                header
                overviewGuide
                topicRail
                lesson
                Button { route = .tools } label: {
                    HStack(spacing:12) {
                        Image(systemName:"books.vertical")
                        Text("Meet the tools & key terms")
                        Spacer(minLength:0)
                        Image(systemName:"chevron.right").font(.caption.bold())
                    }
                    .font(.system(.subheadline,design:.rounded,weight:.semibold))
                    .padding(19)
                    .frame(maxWidth:.infinity,minHeight:62)
                    .background(Color(dtHex:0xD0E5C2),in:RoundedRectangle(cornerRadius:23))
                    .overlay(RoundedRectangle(cornerRadius:23).strokeBorder(DTPalette.ink.opacity(0.65),lineWidth:1.3))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("dna-open-tools")
                sources
            }
            .padding(.horizontal,20).padding(.top,12).padding(.bottom,28)
            .frame(maxWidth:650).frame(maxWidth:.infinity)
        }
        .background(DTPalette.cream.ignoresSafeArea())
        .foregroundStyle(DTPalette.ink).tint(DTPalette.teal)
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .onAppear { clock.setRunning(shouldAnimate) }
        .onDisappear { clock.setRunning(false); narration.stop() }
        .onChange(of:shouldAnimate) { _,value in clock.setRunning(value) }
        .onChange(of:selectedCueID) { _,id in
            if narration.mode == .quiet,narration.isPlaying { narration.stop() }
            narration.selectPhase(id)
        }
        .onChange(of:route?.id) { _,_ in narration.stop() }
        .onChange(of:scenePhase) { _,value in if value != .active { narration.stop() } }
        .onChange(of:narration.currentCueID) { _,_ in syncNarrationMotion() }
        .onChange(of:narration.isPlaying) { _,_ in syncNarrationMotion() }
        .environmentObject(narration)
        .sheet(item:$route) { item in
            switch item {
            case .tools:
                DNATechnologyKeyPlayersView { value in select(value); route=nil }
            case .term(let id):
                DNATechnologyKeyPlayersView(initialTermID:id) { value in select(value); route=nil }
            }
        }
        .alert("Audio unavailable",isPresented:Binding(
            get:{ narration.errorMessage != nil },set:{ if !$0 { narration.errorMessage=nil } }
        )) { Button("OK",role:.cancel) { narration.errorMessage=nil } }
        message: { Text(narration.errorMessage ?? "Please try again.") }
    }

    private var overviewGuide: some View {
        let title = narration.isPlaying ? "Stop" : !hasStartedOverview ? "Hear overview"
            : "\(narration.completedCues.contains(selectedCueID) ? "Replay" : "Hear") \(stage.title)"
        return LessonGuide(narrator:narration,title:title,
                           cueID:narration.isPlaying ? (narration.currentCueID ?? narration.overviewCueID)
                               : (hasStartedOverview ? selectedCueID : narration.overviewCueID),
                           action:{
                               if narration.isPlaying || narration.isScheduled { narration.stop() }
                               else if !hasStartedOverview { playOverview() }
                               else { narration.toggleLesson() }
                           },
                           showsStopBetweenClips:narration.mode == .lesson,
                           replayOverview:playOverview,
                           controlID:"dna-listen",layoutTitle:"Hear overview")
            .foregroundStyle(DTPalette.ink)
    }

    private var header: some View {
        VStack(alignment:.leading,spacing:7) {
            Text("DNA Technology")
                .font(.system(.largeTitle,design:.serif,weight:.bold))
                .accessibilityAddTraits(.isHeader)
            HStack(spacing:10) {
                VStack(alignment:.leading,spacing:8) {
                    Text("Read. Copy. Edit.")
                        .font(.system(.title3,design:.rounded,weight:.bold))
                    Text("Small tools. Big biological possibilities.")
                        .font(.system(.subheadline,design:.rounded))
                        .foregroundStyle(DTPalette.muted)
                        .fixedSize(horizontal:false,vertical:true)
                }
                .frame(maxWidth:.infinity,alignment:.leading)
                DTAssetArt(name:"hero").frame(width:132,height:128)
            }
        }
    }

    private var topicRail: some View {
        ScrollViewReader { proxy in
            VStack(alignment:.leading,spacing:10) {
                HStack {
                    Text("Explore the lab").font(.system(.headline,design:.rounded))
                    Spacer()
                    Text("\(topicIndex+1) / \(DTTopic.allCases.count)")
                        .font(.system(.caption,design:.rounded,weight:.semibold))
                        .foregroundStyle(DTPalette.muted)
                }
                ScrollView(.horizontal,showsIndicators:false) {
                    HStack(spacing:10) {
                        ForEach(DTTopic.allCases) { value in
                            Button { select(value) } label: {
                                VStack(spacing:3) {
                                    DTAssetArt(name:value.rawValue).frame(width:86,height:78)
                                    Text(value.article.short)
                                        .font(.system(.caption,design:.rounded,weight:.semibold))
                                        .fixedSize(horizontal:false,vertical:true)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(9).frame(width:108).frame(minHeight:118)
                                .background(Color(dtHex:value.article.hex).opacity(topic == value ? 0.82 : 0.42),in:RoundedRectangle(cornerRadius:21))
                                .overlay(RoundedRectangle(cornerRadius:21).strokeBorder(topic == value ? DTPalette.teal : DTPalette.ink.opacity(0.28),lineWidth:topic == value ? 2 : 1))
                            }
                            .buttonStyle(.plain).id(value)
                            .accessibilityLabel(value.article.title)
                            .accessibilityValue(topic == value ? "Selected" : "")
                            .accessibilityIdentifier("dna-topic-\(value.rawValue)")
                        }
                    }.padding(.vertical,2)
                }
            }
            .onAppear { proxy.scrollTo(topic,anchor:.center) }
            .onChange(of:topic) { _,value in
                withAnimation(reduceMotion ? nil : .easeInOut(duration:0.2)) { proxy.scrollTo(value,anchor:.center) }
            }
        }
    }

    private var lesson: some View {
        VStack(alignment:.leading,spacing:15) {
            HStack(alignment:.top) {
                Text(article.eyebrow)
                    .font(.system(.caption2,design:.rounded,weight:.bold)).tracking(1)
                    .foregroundStyle(DTPalette.muted)
                    .fixedSize(horizontal:false,vertical:true)
                Spacer(minLength:8)
                Button { playing.toggle() } label: {
                    Image(systemName:playing && !reduceMotion ? "pause.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(width:44,height:44).background(DTPalette.paper.opacity(0.7),in:Circle())
                }
                .buttonStyle(.plain).disabled(reduceMotion)
                .accessibilityLabel(reduceMotion ? "Motion reduced by system setting" : playing ? "Pause diagrams" : "Play diagrams")
                .accessibilityIdentifier("dna-motion")
            }
            DTAssetArt(name:topic.rawValue).frame(height:164).frame(maxWidth:.infinity)
            HStack(alignment:.top,spacing:10) {
                Text(article.title)
                    .font(.system(.title,design:.serif,weight:.bold))
                    .fixedSize(horizontal:false,vertical:true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("dna-topic-title")
                    .frame(maxWidth:.infinity,alignment:.leading)
                NarrationSpeakerButton(cueID:selectedCueID,title:stage.title)
            }
            Text(article.summary)
                .font(.system(.subheadline,design:.rounded))
                .lineSpacing(3).fixedSize(horizontal:false,vertical:true)
            stagePicker
            VStack(spacing:8) {
                TimelineView(.animation(minimumInterval:1.0/20,paused:!shouldAnimate)) { timeline in
                    let time=reduceMotion ? 2 : max(0,clock.time(at:timeline.date)-startedAt)
                    DTDiagramView(sceneID:sceneID,time:time)
                }
                .aspectRatio(360.0/240,contentMode:.fit)
                Text(stage.heading)
                    .font(.system(.headline,design:.rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal,12)
                    .accessibilityIdentifier("dna-stage-heading")
                Text(stage.summary)
                    .font(.system(.subheadline,design:.rounded))
                    .lineSpacing(2).multilineTextAlignment(.center)
                    .fixedSize(horizontal:false,vertical:true)
                    .padding(.horizontal,14).padding(.bottom,17)
            }
            .frame(maxWidth:.infinity)
            .background(DTPalette.paper.opacity(0.8),in:RoundedRectangle(cornerRadius:21))
            if topic == .pcr { pcrCounter }
            DisclosureGroup("A little more biology",isExpanded:$showDetails) {
                DTBulletList(items:stage.bullets).padding(.top,10)
                if let scene=DTScene.all[sceneID] {
                    Text(scene.note).font(.system(.caption,design:.rounded))
                        .foregroundStyle(DTPalette.muted)
                        .fixedSize(horizontal:false,vertical:true).padding(.top,9)
                }
            }
            .font(.system(.subheadline,design:.rounded,weight:.semibold))
            .tint(DTPalette.ink)
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:7) {
                    ForEach(stage.terms,id:\.self) { id in
                        if let term=DTTerm.find(id) {
                            Button { route = .term(id) } label: {
                                HStack(spacing:4) {
                                    Text(term.name)
                                    Image(systemName:"plus.circle").font(.caption2)
                                }
                                .font(.system(.caption,design:.rounded,weight:.semibold))
                                .padding(.horizontal,11).frame(minHeight:44)
                                .background(DTPalette.paper.opacity(0.75),in:Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens a short definition.")
                            .accessibilityIdentifier("dna-term-\(id)")
                        }
                    }
                }
            }
            HStack {
                Button { move(-1) } label: { Label("Back",systemImage:"arrow.left").frame(minHeight:44) }
                    .disabled(topicIndex == 0)
                    .accessibilityIdentifier("dna-previous-topic")
                Spacer()
                Button { move(1) } label: { Label("Next area",systemImage:"arrow.right").frame(minHeight:44) }
                    .disabled(topicIndex == DTTopic.allCases.count-1)
                    .accessibilityIdentifier("dna-next-topic")
            }
            .font(.system(.subheadline,design:.rounded,weight:.semibold)).buttonStyle(.plain)
        }
        .padding(20).frame(maxWidth:.infinity,alignment:.leading)
        .background(Color(dtHex:article.hex).opacity(0.62),in:RoundedRectangle(cornerRadius:28))
        .overlay(RoundedRectangle(cornerRadius:28).strokeBorder(DTPalette.ink.opacity(0.62),lineWidth:1.3))
    }

    private var stagePicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:7) {
                    ForEach(Array(article.stages.enumerated()),id:\.element.id) { index,value in
                        Button { stageIndex=index; showDetails=false; restartMotion() } label: {
                            Text(value.title)
                                .font(.system(.subheadline,design:.rounded,weight:.semibold))
                                .padding(.horizontal,14).frame(minHeight:44)
                                .foregroundStyle(index == stageIndex ? DTPalette.paper : DTPalette.ink)
                                .background(index == stageIndex ? DTPalette.ink : DTPalette.paper.opacity(0.72),in:Capsule())
                        }
                        .buttonStyle(.plain).id(value.id)
                        .accessibilityValue(index == stageIndex ? "Selected" : "")
                        .accessibilityIdentifier("dna-stage-\(value.id)")
                    }
                }.padding(.vertical,2)
            }
            .onChange(of:stageIndex) { _,_ in
                withAnimation(reduceMotion ? nil : .easeInOut(duration:0.2)) { proxy.scrollTo(stage.id,anchor:.center) }
            }
        }
        .id(topic)
    }

    private var pcrCounter: some View {
        VStack(alignment:.leading,spacing:9) {
            HStack(spacing:12) {
                Text("IDEAL AMPLIFICATION").font(.system(.caption2,design:.rounded,weight:.bold)).tracking(1)
                Spacer(minLength:0)
                NarrationSpeakerButton(cueID:"reference.pcr-counter",title:"how the PCR counter works")
            }
            Text((1 << cycles).formatted())
                .font(.system(.title,design:.rounded,weight:.bold)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
                .accessibilityIdentifier("dna-pcr-copies")
            Text("copies after \(cycles) cycles · 1 starting template")
                .font(.system(.caption,design:.rounded)).fixedSize(horizontal:false,vertical:true)
            HStack {
                Button("Reset") { cycles=0 }.frame(minWidth:44,minHeight:44)
                Spacer()
                Button { cycles=min(30,cycles+1) } label: {
                    Label("One more cycle",systemImage:"arrow.triangle.2.circlepath")
                        .frame(minHeight:44)
                }
                .disabled(cycles == 30)
                .accessibilityIdentifier("dna-pcr-add-cycle")
            }
            .font(.system(.subheadline,design:.rounded,weight:.semibold)).buttonStyle(.plain)
            Text("2ⁿ assumes perfect doubling; real yield varies.")
                .font(.system(.caption2,design:.rounded)).foregroundStyle(DTPalette.muted)
        }
        .padding(16).frame(maxWidth:.infinity,alignment:.leading)
        .background(DTPalette.paper.opacity(0.7),in:RoundedRectangle(cornerRadius:18))
    }

    private var sources: some View {
        DisclosureGroup("Sources & content notes") {
            VStack(alignment:.leading,spacing:11) {
                Text("Chapter 11 concepts, with notes on cDNA, inheritance, clinical terminology, and statistical interpretation. Diagrams are schematic.")
                    .font(.system(.caption,design:.rounded))
                ForEach(DTSource.all) { source in
                    Link(source.title,destination:source.url)
                        .font(.system(.caption,design:.rounded)).frame(minHeight:32,alignment:.leading)
                }
            }.padding(.top,10)
        }
        .font(.system(.caption,design:.rounded,weight:.semibold))
        .foregroundStyle(DTPalette.muted).tint(DTPalette.teal)
    }
    private func restartMotion() { startedAt=clock.time(at:Date()) }
    private func playOverview() {
        hasStartedOverview=true
        narration.playOverview()
    }
    private func syncNarrationMotion() {
        guard narration.isPlaying,narration.mode == .lesson,narration.currentCueID == selectedCueID else { return }
        restartMotion()
    }
    private func select(_ value: DTTopic) { topic=value; stageIndex=0; showDetails=false; restartMotion() }
    private func move(_ delta:Int) {
        let next=topicIndex+delta
        if DTTopic.allCases.indices.contains(next) { select(DTTopic.allCases[next]) }
    }
}

