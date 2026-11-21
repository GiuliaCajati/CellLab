import AppKit
import ImageIO
import UniformTypeIdentifiers

// Deterministic layouts using original, verified Simulator captures only.
// Compile on macOS, then run from Marketing/AppStore/en-US.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fm = FileManager.default
func color(_ h: UInt32) -> NSColor { NSColor(srgbRed: CGFloat((h>>16)&255)/255, green: CGFloat((h>>8)&255)/255, blue: CGFloat(h&255)/255, alpha: 1) }
let ink=color(0x184C46), cream=color(0xFCF5EC), teal=color(0x118782), gold=color(0xF7E49C), pink=color(0xCF7595), blue=color(0xC8E7EF)
func rounded(_ size: CGFloat, _ weight: NSFont.Weight = .heavy) -> NSFont {
    let font=NSFont.systemFont(ofSize:size,weight:weight)
    return NSFont(descriptor:font.fontDescriptor.withDesign(.rounded)!,size:size)!
}
func text(_ s: String,_ x: CGFloat,_ y: CGFloat,_ size: CGFloat,_ c: NSColor=cream,_ weight: NSFont.Weight = .heavy,_ tracking: CGFloat = -3) {
    (s as NSString).draw(at:CGPoint(x:x,y:y),withAttributes:[.font:rounded(size,weight),.foregroundColor:c,.kern:tracking])
}
func fill(_ rect: CGRect,_ c: NSColor,_ r: CGFloat=0) { c.setFill(); NSBezierPath(roundedRect:rect,xRadius:r,yRadius:r).fill() }
func circle(_ rect: CGRect,_ c: NSColor) { c.setFill(); NSBezierPath(ovalIn:rect).fill() }
func image(_ path: String) -> CGImage {
    let s=CGImageSourceCreateWithURL(root.appendingPathComponent(path) as CFURL,nil)!
    return CGImageSourceCreateImageAtIndex(s,0,nil)!
}
var trace: [[String:Any]]=[]
var currentOutput=""
func insert(_ path: String,_ crop: CGRect,_ dest: CGRect,_ radius: CGFloat=0) {
    let original=image("Captures/"+path)
    precondition(CGRect(x:0,y:0,width:original.width,height:original.height).contains(crop),path)
    let cut=original.cropping(to:crop)!
    precondition(abs(dest.width/dest.height-crop.width/crop.height)<0.015,"Preserve capture proportions")
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect:dest,xRadius:radius,yRadius:radius).addClip()
    NSImage(cgImage:cut,size:NSSize(width:cut.width,height:cut.height)).draw(in:dest,from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:[.interpolation:NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()
    trace.append(["output":currentOutput,"capture":path,"sourcePixels":[crop.minX,crop.minY,crop.width,crop.height],"destinationPixels":[dest.minX,dest.minY,dest.width,dest.height]])
}
func axolotl(_ rect: CGRect) {
    let art=image("Artwork/CellLab-Axolotl-Speaking.png")
    NSImage(cgImage:art,size:NSSize(width:art.width,height:art.height)).draw(in:rect,from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:[.interpolation:NSImageInterpolation.high])
}
@discardableResult func render(_ path: String,_ w: Int,_ h: Int,_ body:()->Void) -> CGImage {
    currentOutput=path
    let context=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue)!
    context.translateBy(x:0,y:CGFloat(h)); context.scaleBy(x:1,y:-1)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current=NSGraphicsContext(cgContext:context,flipped:true)
    body(); NSGraphicsContext.restoreGraphicsState()
    let result=context.makeImage()!
    let url=root.appendingPathComponent(path)
    try! fm.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
    let d=CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil)!
    CGImageDestinationAddImage(d,result,[kCGImagePropertyDPIWidth:72,kCGImagePropertyDPIHeight:72] as CFDictionary)
    precondition(CGImageDestinationFinalize(d)); print(path,w,h)
    return result
}
func header(_ first: String,_ second: String,_ pad: Bool=false) {
    let w:CGFloat=pad ? 2064:1206, h:CGFloat=pad ? 2752:2622
    fill(CGRect(x:0,y:0,width:w,height:h),ink)
    circle(CGRect(x:w-186,y:-115,width:330,height:330),teal)
    circle(CGRect(x:-90,y:pad ? 450:345,width:200,height:200),pink)
    circle(CGRect(x:w-106,y:pad ? 600:430,width:165,height:165),blue)
    let font=NSFont(name:"Georgia-Bold",size:pad ? 72:46)!
    ("CellLab" as NSString).draw(at:CGPoint(x:pad ? 110:64,y:pad ? 60:54),withAttributes:[.font:font,.foregroundColor:cream])
    text("PLAY YOUR WAY INTO BIOLOGY",pad ? 1030:405,pad ? 89:75,pad ? 33:23,cream,.semibold,1.1)
    text(first,pad ? 105:62,pad ? 180:167,pad ? 235:147,cream,.heavy,-5)
    text(second,pad ? 105:62,pad ? 430:325,pad ? 235:147,gold,.heavy,-5)
}
let names=["01-Build-DNA","02-Explore-an-Animal-Cell","03-See-Cells-Divide","04-Meet-Your-Axolotl-Guide","05-Daily-Biology-Widget"]
var phones:[CGImage]=[], pads:[CGImage]=[]
// Preserve the selected B first image byte-for-byte.
let selected=root.appendingPathComponent("Concepts/01-B-Colorful-Poster-iPhone.png")
let firstOut=root.appendingPathComponent("iPhone/"+names[0]+".png")
try fm.createDirectory(at:firstOut.deletingLastPathComponent(),withIntermediateDirectories:true)
if fm.fileExists(atPath:firstOut.path) { try fm.removeItem(at:firstOut) }
try fm.copyItem(at:selected,to:firstOut); phones.append(image("iPhone/"+names[0]+".png"))
trace.append(["output":"iPhone/"+names[0]+".png","copiedFrom":"Concepts/01-B-Colorful-Poster-iPhone.png","capture":"iPhone-17-Pro-DNA-four-bases.png","sourcePixels":[0,450,1206,2050]])
phones.append(render("iPhone/"+names[1]+".png",1206,2622) {
    header("Explore an","animal cell.")
    insert("iPhone-animal-cell-mitochondria.png",CGRect(x:0,y:580,width:1206,height:1760),CGRect(x:0,y:598,width:1206,height:1760),64)
    text("Tap an organelle. Follow its job.",66,2460,47,cream,.semibold,0)
})
phones.append(render("iPhone/"+names[2]+".png",1206,2622) {
    header("See cells","divide.")
    for (phase,y) in [("metaphase",CGFloat(600)),("anaphase",CGFloat(1460))] {
        insert("iPhone-mitosis-"+phase+".png",CGRect(x:48,y:730,width:1110,height:880),CGRect(x:54,y:y,width:1098,height:870.486),48)
    }
    insert("iPhone-mitosis-anaphase.png",CGRect(x:45,y:1790,width:1116,height:115),CGRect(x:54,y:2370,width:1098,height:113.145),15)
    text("Swipe through mitosis.",68,2520,43,cream,.semibold,0)
})
phones.append(render("iPhone/"+names[3]+".png",1206,2622) {
    header("Big ideas.","Friendly guide.")
    insert("iPhone-axolotl-central-dogma-speaking.png",CGRect(x:0,y:535,width:1206,height:1710),CGRect(x:0,y:544,width:1206,height:1710),64)
    text("Tap. Listen.",66,2360,58,cream,.semibold,0)
    text("Keep exploring.",66,2435,58,cream,.semibold,0)
    axolotl(CGRect(x:760,y:2240,width:405,height:344.25))
})
// iPad art comes from separate iPad Simulator captures, including its actual wider layouts.
pads.append(render("iPad/"+names[0]+".png",2064,2752) {
    header("Build DNA,","base by base.",true)
    insert("iPad-DNA-replication-four-bases-next-selected.png",CGRect(x:520,y:690,width:1030,height:1290),CGRect(x:397,y:738,width:1270,height:1590.583),64)
    insert("iPad-DNA-replication-four-bases-next-selected.png",CGRect(x:770,y:2310,width:525,height:40),CGRect(x:632,y:2340,width:800,height:60.952),0)
    insert("iPad-DNA-replication-four-bases-next-selected.png",CGRect(x:490,y:2375,width:1080,height:180),CGRect(x:167,y:2425,width:1730,height:288.333),25)
})
pads.append(render("iPad/"+names[1]+".png",2064,2752) {
    header("Explore an","animal cell.",true)
    insert("iPad-animal-cell-mitochondria.png",CGRect(x:448,y:466,width:1168,height:1202),CGRect(x:97,y:730,width:1870,height:1924.435),80)
})
pads.append(render("iPad/"+names[2]+".png",2064,2752) {
    header("See cells","divide.",true)
    for (phase,y) in [("metaphase",CGFloat(760)),("anaphase",CGFloat(1645))] {
        insert("iPad-mitosis-"+phase+".png",CGRect(x:384,y:430,width:1296,height:590),CGRect(x:112,y:y,width:1840,height:837.654),65)
    }
    insert("iPad-mitosis-anaphase.png",CGRect(x:380,y:1134,width:1304,height:50),CGRect(x:112,y:2550,width:1840,height:70.552),16)
})
pads.append(render("iPad/"+names[3]+".png",2064,2752) {
    header("Big ideas.","Friendly guide.",true)
    insert("iPad-axolotl-central-dogma-speaking.png",CGRect(x:380,y:298,width:1304,height:1132),CGRect(x:146,y:745,width:1772,height:1538.282),65)
    text("Tap. Listen.",140,2410,95,cream,.semibold,0)
    text("Keep exploring.",140,2525,95,cream,.semibold,0)
    axolotl(CGRect(x:1320,y:2220,width:600,height:510))
})
// Widget crops are exact bounds of the two real Home Screen widgets, without test-runner icons.
if fm.fileExists(atPath:root.appendingPathComponent("Captures/iPhone-daily-fact-small-home-screen.png").path) {
 phones.append(render("iPhone/"+names[4]+".png",1206,2622) {
    header("One tiny fact.","Every day.")
    insert("iPhone-daily-fact-home-screen.png",CGRect(x:79,y:270,width:1049,height:493),CGRect(x:53,y:760,width:1100,height:516.969),97)
    insert("iPhone-daily-fact-small-home-screen.png",CGRect(x:635,y:270,width:493,height:493),CGRect(x:64,y:1480,width:640,height:640),122)
    text("Small or",765,1580,54,cream,.semibold,0)
    text("medium.",765,1650,54,cream,.semibold,0)
    text("Your daily",765,1830,43,gold,.semibold,0)
    text("science break.",765,1890,43,gold,.semibold,0)
    text("Biology on your Home Screen.",65,2420,47,cream,.semibold,0)
 })
}
// iPad widget rectangles are supplied after checking its real SpringBoard captures.
if fm.fileExists(atPath:root.appendingPathComponent("Captures/iPad-Widget-Bounds.json").path) {
 let bounds=try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("Captures/iPad-Widget-Bounds.json"))) as! [String:[Double]]
 let m=bounds["medium"]!,s=bounds["small"]!
 pads.append(render("iPad/"+names[4]+".png",2064,2752) {
    header("One tiny fact.","Every day.",true)
    insert("iPad-daily-fact-home-screen.png",CGRect(x:m[0],y:m[1],width:m[2],height:m[3]),CGRect(x:112,y:800,width:1840,height:1840*m[3]/m[2]),150)
    insert("iPad-daily-fact-small-home-screen.png",CGRect(x:s[0],y:s[1],width:s[2],height:s[3]),CGRect(x:145,y:1750,width:780,height:780*s[3]/s[2]),150)
    text("Small or",1110,1860,90,cream,.semibold,0)
    text("medium.",1110,1970,90,cream,.semibold,0)
    text("Your daily",1110,2190,70,gold,.semibold,0)
    text("science break.",1110,2280,70,gold,.semibold,0)
    text("Biology on your Home Screen.",112,2620,60,cream,.semibold,0)
 })
}
func contact(_ images:[CGImage],_ path:String,_ label:String) {
 let tile:CGFloat=310, gap:CGFloat=22, margin:CGFloat=28
 let ratio=CGFloat(images[0].height)/CGFloat(images[0].width)
 let height=Int(160+tile*ratio)
 render(path,Int(margin*2+CGFloat(images.count)*tile+CGFloat(images.count-1)*gap),height) {
    fill(CGRect(x:0,y:0,width:2200,height:CGFloat(height)),color(0xE7E7E2))
    text(label,28,22,28,ink,.bold,0)
    for (idx,i) in images.enumerated() {
      NSImage(cgImage:i,size:NSSize(width:i.width,height:i.height)).draw(in:CGRect(x:margin+CGFloat(idx)*(tile+gap),y:80,width:tile,height:tile*ratio),from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:[.interpolation:NSImageInterpolation.high])
      text(String(format:"%02d",idx+1),margin+CGFloat(idx)*(tile+gap),100+tile*ratio,22,ink,.bold,0)
    }
 }
}
contact(phones,"Previews/iPhone-Upload-Order.png","CellLab · iPhone · upload order")
contact(pads,"Previews/iPad-Upload-Order.png","CellLab · iPad · upload order")
try JSONSerialization.data(withJSONObject:trace,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("Previews/Capture-Crops.json"))
