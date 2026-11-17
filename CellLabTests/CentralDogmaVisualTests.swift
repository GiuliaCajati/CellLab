import SwiftUI
import UIKit
import XCTest
@testable import CellLab

@MainActor
final class CentralDogmaVisualTests: XCTestCase {
    func testTeachingSequencePairingAndStopSignals() {
        XCTAssertEqual(CentralDogmaMolecules.template.map { CentralDogmaMolecules.complement($0) },
                       CentralDogmaMolecules.preMessenger)
        XCTAssertEqual(CentralDogmaMolecules.coding.joined().replacingOccurrences(of: "T", with: "U"),
                       CentralDogmaMolecules.preMessenger.joined())
        XCTAssertEqual(CentralDogmaMolecules.exons.joined(), "AUGGCUUUCUAA")
        XCTAssertEqual(CentralDogmaMolecules.preMessenger.joined(),
                       CentralDogmaMolecules.exons[0] + CentralDogmaMolecules.intron + CentralDogmaMolecules.exons[1])
        XCTAssertEqual(CentralDogmaMolecules.codons.joined(), CentralDogmaMolecules.messenger.joined())
        XCTAssertEqual(CentralDogmaMolecules.anticodon(for: "AUG"), "UAC")
        XCTAssertEqual(CentralDogmaMolecules.anticodon(for: "GCU"), "CGA")
        XCTAssertEqual(CentralDogmaMolecules.anticodon(for: "UUC"), "AAG")
        for stop in ["UAA", "UAG", "UGA"] {
            XCTAssertNil(CentralDogmaMolecules.anticodon(for: stop))
        }
    }

    func testRenderAllProcessScenesForVisualReview() throws {
        // Capture real app drawings at all three milestones for visual review.
        // No simulator timing or animation clock affects these renders.
        for progress in [0.0, 0.5, 1.0] {
            var images: [UIImage] = []
            for step in CentralDogmaStep.allCases {
                let renderer = ImageRenderer(content: CentralDogmaScene(step: step, progress: progress)
                    .frame(width: 360, height: 420))
                renderer.scale = 2
                let image = try XCTUnwrap(renderer.uiImage, step.id)
                images.append(image)
            }
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let sheet = UIGraphicsImageRenderer(size: CGSize(width: 720, height: 2300), format: format).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 720, height: 2300))
                for (i, image) in images.enumerated() {
                    let x = CGFloat(i % 2) * 360, y = CGFloat(i / 2) * 460
                    let label = "\(i + 1). \(CentralDogmaStep.allCases[i].content.title)"
                    (label as NSString).draw(at: CGPoint(x: x + 12, y: y + 10), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 15, weight: .bold), .foregroundColor: UIColor.black
                    ])
                    image.draw(in: CGRect(x: x, y: y + 35, width: 360, height: 420))
                }
            }
            let attachment = XCTAttachment(image: sheet)
            attachment.name = "Central Dogma scenes at \(Int(progress * 100)) percent"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
