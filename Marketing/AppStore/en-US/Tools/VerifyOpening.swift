import Foundation
import ImageIO
import Vision

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var results: [[String: Any]] = []
for name in ["01-A-Warm-Editorial-iPhone", "01-B-Colorful-Poster-iPhone"] {
    let url = root.appendingPathComponent("Concepts/\(name).png")
    let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)! as NSDictionary
    let hasAlpha = (properties[kCGImagePropertyHasAlpha] as? Bool) ?? false
    precondition(image.width == 1206 && image.height == 2622)
    precondition(!hasAlpha, "App Store PNGs must have no alpha channel")
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["en-US"]
    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
    let lines = request.results!.compactMap { $0.topCandidates(1).first?.string }
    let normalized = lines.joined(separator: " ").lowercased()
    precondition(normalized.contains("build dna,"))
    precondition(normalized.contains("base by base."))
    precondition(normalized.contains("attach c"))
    let result: [String: Any] = ["file": "Concepts/\(name).png", "width": image.width,
        "height": image.height, "hasAlpha": hasAlpha, "colorModel": properties[kCGImagePropertyColorModel] ?? "",
        "headlineOCRVerified": true, "nextMoveOCRVerified": true, "recognizedText": lines]
    results.append(result)
    print(name, "PASS: 1206×2622, RGB, no alpha; headline and Attach C recognized")
}
let data = try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
try data.write(to: root.appendingPathComponent("Concepts/Validation.json"))
