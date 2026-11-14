// DNATechnologyArtwork.swift — shared styling and painted sprite atlas.
import SwiftUI
import UIKit

extension Color {
    init(dtHex value: UInt32) {
        self.init(.sRGB,red:Double((value >> 16) & 255)/255,
                  green:Double((value >> 8) & 255)/255,blue:Double(value & 255)/255,opacity:1)
    }
}
enum DTPalette {
    static let cream=Color(dtHex:0xFBF4EA)
    static let paper=Color(dtHex:0xFFFDF8)
    static let ink=Color(dtHex:0x184C46)
    static let teal=Color(dtHex:0x118782)
    static let muted=Color(dtHex:0x4D6C62)
}

enum DTAtlas {
    static let frames: [String:CGRect] = [
        "recombinant": CGRect(x:44,y:36,width:293,height:285),
        "sequencing": CGRect(x:417,y:30,width:305,height:290),
        "pcr": CGRect(x:789,y:24,width:330,height:299),
        "editing": CGRect(x:1166,y:40,width:356,height:269),
        "profiling": CGRect(x:9,y:375,width:357,height:271),
        "stemCells": CGRect(x:405,y:383,width:335,height:262),
        "cloning": CGRect(x:789,y:371,width:353,height:282),
        "medicine": CGRect(x:1226,y:362,width:270,height:295),
        "ecology": CGRect(x:7,y:695,width:365,height:305),
        "reverseTranscriptase": CGRect(x:395,y:722,width:358,height:238),
        "probe": CGRect(x:784,y:723,width:343,height:218),
        "hero": CGRect(x:1170,y:684,width:342,height:314)
    ]
}
struct DTAssetArt: View {
    let name: String
    var body: some View {
        Canvas { context,size in
            guard let frame=DTAtlas.frames[name], UIImage(named:"DTTechnologyAtlas") != nil else {
                context.draw(context.resolve(Image(systemName:"dna")),in:CGRect(x:size.width*0.25,y:size.height*0.2,width:size.width*0.5,height:size.height*0.6))
                return
            }
            let scale=min(size.width/frame.width,size.height/frame.height)
            let fitted=CGRect(x:(size.width-frame.width*scale)/2,y:(size.height-frame.height*scale)/2,
                              width:frame.width*scale,height:frame.height*scale)
            context.clip(to:Path(fitted))
            let destination=CGRect(x:fitted.minX-frame.minX*scale,y:fitted.minY-frame.minY*scale,
                                   width:1536*scale,height:1024*scale)
            context.draw(context.resolve(Image("DTTechnologyAtlas").interpolation(.high)),in:destination)
        }
        .accessibilityHidden(true)
    }
}

struct DTBulletList: View {
    let items: [String]
    var body: some View {
        VStack(alignment:.leading,spacing:11) {
            ForEach(Array(items.enumerated()),id:\.offset) { _,value in
                HStack(alignment:.firstTextBaseline,spacing:9) {
                    Text("•").fontWeight(.bold).accessibilityHidden(true)
                    Text(value).fixedSize(horizontal:false,vertical:true)
                }
            }
        }
        .font(.system(.subheadline,design:.rounded)).lineSpacing(3)
    }
}

struct DTSource: Identifiable, Sendable {
    let title:String
    let url:URL
    var id:String { url.absoluteString }
    static let all: [DTSource] = [
        .init(title:"NHGRI — PCR",url:URL(string:"https://www.genome.gov/about-genomics/fact-sheets/Polymerase-Chain-Reaction-Fact-Sheet")!),
        .init(title:"NHGRI — Cloning",url:URL(string:"https://www.genome.gov/about-genomics/fact-sheets/Cloning-Fact-Sheet")!),
        .init(title:"FBI — CODIS core STR loci",url:URL(string:"https://www.fbi.gov/how-we-can-help-you/dna-fingerprint-act-of-2005-expungement-policy/codis-and-ndis-fact-sheet")!),
        .init(title:"ASRM — Preimplantation genetic testing",url:URL(string:"https://www.asrm.org/practice-guidance/practice-committee-documents/the-use-of-preimplantation-genetic-testing-for-aneuploidy-a-committee-opinion-2024/")!),
        .init(title:"Wang et al. — EPSPS and weedy-rice fitness",url:URL(string:"https://pubmed.ncbi.nlm.nih.gov/23905647/")!),
        .init(title:"National Academies — Nuclear transfer and cloning",url:URL(string:"https://www.ncbi.nlm.nih.gov/books/NBK223960/")!),
        .init(title:"Genome research — Transposable-element DNA",url:URL(string:"https://pmc.ncbi.nlm.nih.gov/articles/PMC2884099/")!),
        .init(title:"iPSC immunogenicity — primary study",url:URL(string:"https://www.nature.com/articles/nature10135")!),
        .init(title:"NHGRI — cDNA",url:URL(string:"https://www.genome.gov/genetics-glossary/copy-DNA-cDNA")!),
        .init(title:"NCI — BRCA variants and risk",url:URL(string:"https://www.cancer.gov/about-cancer/causes-prevention/genetics/brca-fact-sheet")!),
        .init(title:"HRSA — PKU screening",url:URL(string:"https://newbornscreening.hrsa.gov/conditions/classic-phenylketonuria")!),
        .init(title:"Anzalone et al. — Prime editing",url:URL(string:"https://www.nature.com/articles/s41586-019-1711-4")!),
    ]
}
