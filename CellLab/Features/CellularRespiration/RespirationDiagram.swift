import SwiftUI

/// Crisp, offline molecular drawings shared by the lesson and its close-up.
@MainActor struct RespirationScene: View, Equatable {
    static let overviewSize = CGSize(width: 360, height: 440)
    let step: RespirationStep
    let progress: Double
    var background: Color = RespirationTheme.paper
    var illustrationID: String? = nil

    var body: some View {
        Canvas { context, size in
            let height: CGFloat = illustrationID == nil ? (step == .overview ? Self.overviewSize.height : 330) : 260
            let scale = min(size.width / 360, size.height / height)
            context.translateBy(x: (size.width - 360 * scale) / 2,
                                y: (size.height - height * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            RespirationProcessPainter(context: context,
                                      p: CGFloat(min(max(progress.isFinite ? progress : 1, 0), 1)))
                .draw(step: step, player: illustrationID)
        }
        .background(background)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(illustrationID.flatMap { id in
            RespirationPlayer.all.first { $0.id == id }.map { $0.title + ". " + $0.caption }
        } ?? step.content.accessibility)
        .accessibilityIdentifier("respiration-diagram")
    }
}

extension RespirationStep {
    var location: String {
        switch self {
        case .overview: "Cytosol → mitochondrion"
        case .glycolysis: "In the cytosol"
        case .transition, .krebs: "Inside the mitochondrial matrix"
        case .transport, .chemiosmosis: "At the inner membrane"
        case .accounting, .efficiency: "Per glucose molecule"
        case .anaerobic: "At the cell membrane · many microbes"
        case .fermentation: "In the cytosol"
        }
    }
}
