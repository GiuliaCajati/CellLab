import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers
@main struct Render {
 @MainActor static func main() {
  let r=ImageRenderer(content:MitosisAxolotl(isSpeaking:true,fittedToArtwork:true).frame(width:640,height:544))
  r.scale=2
  guard let image=r.cgImage else { fatalError("Axolotl render failed") }
  let url=URL(fileURLWithPath:CommandLine.arguments[1])
  let d=CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil)!
  CGImageDestinationAddImage(d,image,nil); precondition(CGImageDestinationFinalize(d))
  print("Rendered existing CellLab vector axolotl",image.width,image.height)
 }
}
