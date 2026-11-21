import AppKit
import ImageIO
import UniformTypeIdentifiers
import Vision
import CryptoKit

// Run from Marketing/AppStore/en-US. This uses CellLab's existing vector axolotl.
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let safe=CGRect(x:1921,y:660,width:1402,height:962)
func color(_ n:UInt32)->NSColor { NSColor(srgbRed:CGFloat((n>>16)&255)/255,green:CGFloat((n>>8)&255)/255,blue:CGFloat(n&255)/255,alpha:1) }
let ink=color(0x184C46),cream=color(0xFCF5EC),teal=color(0x118782),gold=color(0xF7E49C),pink=color(0xCF7595),blue=color(0xC8E7EF)
func rounded(_ s:CGFloat,_ w:NSFont.Weight = .bold)->NSFont {
 let f=NSFont.systemFont(ofSize:s,weight:w)
 return NSFont(descriptor:f.fontDescriptor.withDesign(.rounded)!,size:s)!
}
func text(_ t:String,_ rect:CGRect,_ font:NSFont,_ c:NSColor) {
 let p=NSMutableParagraphStyle();p.alignment = .center
 (t as NSString).draw(in:rect,withAttributes:[.font:font,.foregroundColor:c,.paragraphStyle:p])
}
func ellipse(_ rect:CGRect,_ color:NSColor) { color.setFill();NSBezierPath(ovalIn:rect).fill() }
func fill(_ rect:CGRect,_ color:NSColor) { color.setFill();NSBezierPath(rect:rect).fill() }
func draw(_ cg:CGImage,_ rect:CGRect) {
 NSImage(cgImage:cg,size:NSSize(width:cg.width,height:cg.height)).draw(in:rect,from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:[.interpolation:NSImageInterpolation.high])
}
@discardableResult func render(_ path:String,_ w:Int,_ h:Int,_ body:()->Void)->CGImage {
 let c=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue)!
 c.translateBy(x:0,y:CGFloat(h));c.scaleBy(x:1,y:-1)
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:c,flipped:true)
 body();NSGraphicsContext.restoreGraphicsState()
 let im=c.makeImage()!,u=root.appendingPathComponent(path)
 let d=CGImageDestinationCreateWithURL(u as CFURL,UTType.png.identifier as CFString,1,nil)!
 CGImageDestinationAddImage(d,im,nil);precondition(CGImageDestinationFinalize(d));print(path,w,h)
 return im
}
let a=CGImageSourceCreateWithURL(root.appendingPathComponent("Artwork/CellLab-Axolotl-Speaking.png") as CFURL,nil)!
let axolotl=CGImageSourceCreateImageAtIndex(a,0,nil)!
let titleRect=CGRect(x:2010,y:702,width:1224,height:241)
let tagRect=CGRect(x:2010,y:966,width:1224,height:92)
let artRect=CGRect(x:2342,y:1103,width:560,height:476)
for r in [titleRect,tagRect,artRect] { precondition(safe.contains(r)) }
let output="CreativeAssets/CellLab-Universal-Creative-5244x2950.png"
let full=render(output,5244,2950) {
 fill(CGRect(x:0,y:0,width:5244,height:2950),ink)
 // Extend the selected B palette through auxiliary art. Only the central lockup is critical.
 ellipse(CGRect(x:-950,y:-980,width:2600,height:2600),teal)
 ellipse(CGRect(x:3890,y:-810,width:2360,height:2360),color(0x236C66))
 ellipse(CGRect(x:-690,y:1770,width:2100,height:2100),color(0x21635C))
 ellipse(CGRect(x:3950,y:1960,width:1550,height:1550),teal)
 ellipse(CGRect(x:1070,y:1250,width:330,height:330),pink)
 ellipse(CGRect(x:3700,y:795,width:300,height:300),blue)
 ellipse(CGRect(x:3430,y:2070,width:180,height:180),gold)
 ellipse(CGRect(x:1580,y:2050,width:100,height:100),blue)
 let orbit=NSBezierPath(ovalIn:CGRect(x:910,y:370,width:3424,height:2100))
 color(0x2B635D).setStroke();orbit.lineWidth=8;orbit.stroke()
 text("CellLab",titleRect,NSFont(name:"Georgia-Bold",size:210)!,cream)
 text("Biology you can play.",tagRect,rounded(76,.semibold),gold)
 draw(axolotl,artRect)
}
let crop=full.cropping(to:safe)!
render("CreativeAssets/Preview-Safe-Area.png",1402,962) { draw(crop,CGRect(x:0,y:0,width:1402,height:962)) }
render("CreativeAssets/Preview-Placement-Guide.png",1600,1000) {
 fill(CGRect(x:0,y:0,width:1600,height:1000),color(0xE7E7E2))
 text("Universal creative asset · safe-area check",CGRect(x:30,y:25,width:1540,height:50),rounded(30),ink)
 let r=CGRect(x:30,y:100,width:1000,height:1000*2950/5244)
 draw(full,r)
 let scale=r.width/5244
 let marker=CGRect(x:r.minX+safe.minX*scale,y:r.minY+safe.minY*scale,width:safe.width*scale,height:safe.height*scale)
 let p=NSBezierPath(rect:marker);gold.setStroke();p.lineWidth=3;p.stroke()
 draw(crop,CGRect(x:1070,y:190,width:500,height:500*962/1402))
 text("5244 × 2950 · opaque RGB PNG",CGRect(x:30,y:710,width:1000,height:48),rounded(27,.semibold),ink)
 text("Highlighted box: Apple’s art safe area",CGRect(x:30,y:775,width:1000,height:48),rounded(25,.medium),ink)
 text("Critical content enlarged",CGRect(x:1070,y:570,width:500,height:50),rounded(25,.semibold),ink)
 text("Final device/orientation previews are available in App Store Connect.",CGRect(x:30,y:900,width:1540,height:45),rounded(25,.medium),ink)
}
let src=CGImageSourceCreateWithURL(root.appendingPathComponent(output) as CFURL,nil)!
let props=CGImageSourceCopyPropertiesAtIndex(src,0,nil)! as NSDictionary
precondition((props[kCGImagePropertyHasAlpha] as? Bool) != true)
let request=VNRecognizeTextRequest();request.recognitionLevel = .accurate;request.recognitionLanguages=["en-US"]
try VNImageRequestHandler(cgImage:crop).perform([request])
let lines=request.results!.compactMap{$0.topCandidates(1).first?.string}
precondition(lines.contains("CellLab") && lines.contains("Biology you can play."))
let report:[String:Any] = ["file":output,"width":5244,"height":2950,"hasAlpha":false,"colorModel":props[kCGImagePropertyColorModel]!,"appleArtSafeArea":[1921,660,1402,962],"criticalElementsContained":true,"safeAreaOCR":lines,"sha256":SHA256.hash(data:try Data(contentsOf:root.appendingPathComponent(output))).map{String(format:"%02x",$0)}.joined()]
try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("CreativeAssets/Validation.json"))
print("Validated: dimensions, no alpha, contained text/art, legible safe-area text")
