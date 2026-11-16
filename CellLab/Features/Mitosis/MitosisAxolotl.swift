import SwiftUI

/// A small vector companion, drawn locally so it stays crisp at any display size.
struct MitosisAxolotl: View {
    var isSpeaking = false
    var fittedToArtwork = false

    var body: some View {
        Canvas { context, size in
            var context = context
            let drawingWidth: CGFloat = fittedToArtwork ? 160 : 180
            let drawingHeight: CGFloat = fittedToArtwork ? 136 : 156
            let scale = min(size.width / drawingWidth, size.height / drawingHeight)
            context.scaleBy(x: scale, y: scale)
            if fittedToArtwork { context.translateBy(x: -10, y: -12) }
            let ink = Color(red: 0.23, green: 0.31, blue: 0.29)
            let pink = Color(red: 1.0, green: 0.78, blue: 0.79)
            let pale = Color(red: 1.0, green: 0.87, blue: 0.85)
            let gill = Color(red: 0.91, green: 0.43, blue: 0.53)

            func draw(_ path: Path, fill: Color, width: CGFloat = 2.8) {
                context.fill(path, with: .color(fill))
                context.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
            func oval(_ rect: CGRect, fill: Color, outline: Bool = true) {
                let path = Path(ellipseIn: rect)
                context.fill(path, with: .color(fill))
                if outline { context.stroke(path, with: .color(ink), lineWidth: 2.8) }
            }

            // A curled tail, tiny feet, and the belly tuck behind the head.
            draw(Path { path in
                path.move(to: CGPoint(x: 103, y: 120))
                path.addCurve(to: CGPoint(x: 156, y: 100), control1: CGPoint(x: 139, y: 145), control2: CGPoint(x: 164, y: 125))
                path.addQuadCurve(to: CGPoint(x: 139, y: 120), control: CGPoint(x: 140, y: 102))
                path.addQuadCurve(to: CGPoint(x: 107, y: 107), control: CGPoint(x: 129, y: 129))
                path.closeSubpath()
            }, fill: pink)
            oval(CGRect(x: 58, y: 128, width: 26, height: 14), fill: pink)
            oval(CGRect(x: 98, y: 128, width: 26, height: 14), fill: pink)
            draw(Path(roundedRect: CGRect(x: 60, y: 83, width: 62, height: 56), cornerRadius: 28), fill: pink)
            oval(CGRect(x: 74, y: 103, width: 33, height: 27), fill: pale, outline: false)
            oval(CGRect(x: 49, y: 101, width: 25, height: 14), fill: pink)
            oval(CGRect(x: 109, y: 101, width: 25, height: 14), fill: pink)

            // Three feathery gills on each side are the axolotl's signature.
            for rightSide in [false, true] {
                func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                    CGPoint(x: rightSide ? 180 - x : x, y: y)
                }
                for (tipX, tipY, rootY) in [(CGFloat(27), CGFloat(19), CGFloat(50)), (17, 44, 61), (23, 75, 75)] {
                    var stem = Path()
                    stem.move(to: point(49, rootY))
                    stem.addQuadCurve(to: point(tipX, tipY), control: point(tipX - 3, rootY - 4))
                    context.stroke(stem, with: .color(ink), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    context.stroke(stem, with: .color(gill), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    for fraction in [CGFloat(0.4), 0.65, 0.85] {
                        let x = 49 + (tipX - 49) * fraction
                        let y = rootY + (tipY - rootY) * fraction
                        var feather = Path()
                        feather.move(to: point(x - 6, y + 1))
                        feather.addLine(to: point(x + 1, y - 5))
                        context.stroke(feather, with: .color(gill), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                    }
                }
            }

            draw(Path(roundedRect: CGRect(x: 39, y: 32, width: 102, height: 68), cornerRadius: 32), fill: pale)
            oval(CGRect(x: 49, y: 72, width: 20, height: 10), fill: pink, outline: false)
            oval(CGRect(x: 111, y: 72, width: 20, height: 10), fill: pink, outline: false)
            for eyeX in [CGFloat(65), 108] {
                oval(CGRect(x: eyeX, y: 57, width: 9, height: 12), fill: ink, outline: false)
                oval(CGRect(x: eyeX + 1.5, y: 58.5, width: 3, height: 3), fill: .white, outline: false)
            }
            if isSpeaking {
                draw(Path(ellipseIn: CGRect(x: 82, y: 72, width: 17, height: 13)), fill: ink, width: 1)
                oval(CGRect(x: 85, y: 79, width: 11, height: 5), fill: pink, outline: false)
            } else {
                var smile = Path()
                smile.move(to: CGPoint(x: 80, y: 74))
                smile.addQuadCurve(to: CGPoint(x: 100, y: 74), control: CGPoint(x: 90, y: 86))
                context.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
            }
            for spot in [CGPoint(x: 82, y: 46), CGPoint(x: 89, y: 43), CGPoint(x: 96, y: 46)] {
                oval(CGRect(x: spot.x, y: spot.y, width: 3, height: 2), fill: pink, outline: false)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Axolotl") {
    MitosisAxolotl().frame(width: 220, height: 190).padding(32)
}
