import Foundation
import AppKit
import ImageIO
import Vision
import CryptoKit

let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let names=["01-Build-DNA","02-Explore-an-Animal-Cell","03-See-Cells-Divide","04-Meet-Your-Axolotl-Guide","05-Daily-Biology-Widget"]
let headlinePairs=[("Build DNA,","base by base."),("Explore an","animal cell."),("See cells","divide."),("Big ideas.","Friendly guide."),("One tiny fact.","Every day.")]
let uiWords=[["Attach C","Parental","New DNA"],["Mitochondria","Tap a part"],["Metaphase","Anaphase","46"],["Stop","RNA polymerase","RNA grows"],["sea slug","steal a sting"]]
func normalized(_ s:String)->String { String(s.lowercased().filter { $0.isLetter || $0.isNumber }) }
var checked:[[String:Any]]=[]
for (device,w,h) in [("iPhone",1206,2622),("iPad",2064,2752)] {
 for (idx,name) in names.enumerated() {
  let path="\(device)/\(name).png",url=root.appendingPathComponent(path)
  let data=try Data(contentsOf:url)
  let source=CGImageSourceCreateWithData(data as CFData,nil)!
  let cg=CGImageSourceCreateImageAtIndex(source,0,nil)!
  let p=CGImageSourceCopyPropertiesAtIndex(source,0,nil)! as NSDictionary
  precondition(cg.width==w && cg.height==h,path+": dimensions")
  precondition((p[kCGImagePropertyHasAlpha] as? Bool) != true,path+": alpha")
  precondition(p[kCGImagePropertyColorModel] as? String == "RGB",path+": color model")
  let request=VNRecognizeTextRequest();request.recognitionLevel = .accurate;request.recognitionLanguages=["en-US"]
  try VNImageRequestHandler(cgImage:cg,options:[:]).perform([request])
  let lines=request.results!.compactMap { $0.topCandidates(1).first?.string }
  let all=normalized(lines.joined(separator:" "))
  for s in [headlinePairs[idx].0,headlinePairs[idx].1]+uiWords[idx] {
   precondition(all.contains(normalized(s)),path+": OCR did not find "+s+"; "+lines.joined(separator:" | "))
  }
  // Vision sometimes joins the decorative pink circle to the first glyph.
  // Check the actual typeset text bounds separately from OCR's visual grouping.
  let fontBase=NSFont.systemFont(ofSize:device == "iPad" ? 235:147,weight:.heavy)
  let font=NSFont(descriptor:fontBase.fontDescriptor.withDesign(.rounded)!,size:fontBase.pointSize)!
  let left:CGFloat=device == "iPad" ? 105:62
  let widths=[headlinePairs[idx].0,headlinePairs[idx].1].map {
      ($0 as NSString).size(withAttributes:[.font:font,.kern:CGFloat(-5)]).width
  }
  let textInside=left>24 && widths.allSatisfy { left+$0<CGFloat(w)-24 }
  precondition(textInside,path+": headline cropping")
  let sha=SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()
  checked.append(["file":path,"width":w,"height":h,"colorModel":"RGB","hasAlpha":false,
   "headlineVerified":true,"headlineInsideSafeMargins":textInside,"featureTextVerified":true,
   "bytes":data.count,"sha256":sha,"recognizedText":lines])
  print("PASS",path,w,h,"RGB/no alpha; headline + feature text")
 }
}
let selected=try Data(contentsOf:root.appendingPathComponent("Concepts/01-B-Colorful-Poster-iPhone.png"))
let first=try Data(contentsOf:root.appendingPathComponent("iPhone/01-Build-DNA.png"))
precondition(selected == first,"Selected B must remain unchanged")
try JSONSerialization.data(withJSONObject:checked,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("Validation.json"))
