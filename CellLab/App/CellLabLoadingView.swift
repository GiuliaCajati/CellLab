import Foundation
import SwiftUI

/// A real, indeterminate loading screen. Its parent decides when loading ends.
/// Add CellLabLoadingMascot.imageset to the app's existing asset catalog.
struct CellLabLoadingView: View {
    let message: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .largeTitle) private var wordmarkSize: CGFloat = 44
    @State private var clockStart = Date()

    init(message: String = "Getting our cells together…") {
        self.message = message
    }

    var body: some View {
        GeometryReader { geometry in
            let maximumHeroSize: CGFloat = dynamicTypeSize.isAccessibilitySize ? 150 : 250
            let heroSize = min(
                maximumHeroSize,
                min(geometry.size.width * 0.66, geometry.size.height * 0.34)
            )

            TimelineView(.animation(
                minimumInterval: 1.0 / 30.0,
                paused: reduceMotion || scenePhase != .active
            )) { context in
                let elapsed = reduceMotion ? 0 : context.date.timeIntervalSince(clockStart)
                let floatPhase = elapsed * .pi / 2

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        Text("CellLab")
                            .font(.system(size: wordmarkSize, weight: .bold, design: .serif))
                            .tracking(-0.8)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(CellLabLoadingPalette.ink)
                            .padding(.bottom, 28)

                        ZStack(alignment: .bottom) {
                            Ellipse()
                                .fill(CellLabLoadingPalette.ink.opacity(0.045))
                                .frame(width: heroSize * 0.32, height: 6)
                                .offset(y: -heroSize * 0.07)

                            Image("CellLabLoadingMascot")
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: heroSize, height: heroSize)
                                .rotationEffect(.degrees(reduceMotion ? 0 : sin(floatPhase) * 1.3))
                                .offset(y: reduceMotion ? 0 : sin(floatPhase) * -3)
                        }
                        .frame(width: heroSize, height: heroSize)
                        .accessibilityHidden(true)
                        .padding(.bottom, 24)

                        Text(message)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(CellLabLoadingPalette.ink.opacity(0.78))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 20)

                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                let wave = sin(elapsed * .pi - Double(index) * 0.9)
                                Circle()
                                    .fill(CellLabLoadingPalette.dots[index])
                                    .frame(width: 6, height: 6)
                                    .opacity(reduceMotion ? 0.85 : 0.30 + 0.70 * (wave + 1) / 2)
                                    .offset(y: reduceMotion ? 0 : -max(0, wave) * 2)
                            }
                        }
                        .frame(height: 10)
                        .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(CellLabLoadingPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("CellLab is loading")
        .accessibilityValue(message)
    }
}

private enum CellLabLoadingPalette {
    static let background = Color(red: 252.0 / 255, green: 247.0 / 255, blue: 239.0 / 255)
    static let ink = Color(red: 20.0 / 255, green: 63.0 / 255, blue: 55.0 / 255)
    static let dots = [
        Color(red: 214.0 / 255, green: 148.0 / 255, blue: 125.0 / 255),
        Color(red: 166.0 / 255, green: 185.0 / 255, blue: 156.0 / 255),
        Color(red: 179.0 / 255, green: 154.0 / 255, blue: 187.0 / 255)
    ]
}
