import Foundation
import SwiftUI

/// An indeterminate loading screen; RootView owns the actual preparation work.
struct CellLabLoadingView: View {
    let message: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .largeTitle) private var wordmarkSize: CGFloat = 50
    @State private var clockStart = Date()

    init(message: String = "Getting our cells together…") {
        self.message = message
    }

    var body: some View {
        GeometryReader { geometry in
            let heroSize = min(dynamicTypeSize.isAccessibilitySize ? 170 : 280,
                               min(geometry.size.width * 0.74, geometry.size.height * 0.38))
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Sparkles().scaleEffect(0.7).frame(width: 22)
                        Text("CellLab")
                            .font(.system(size: wordmarkSize, weight: .bold, design: .serif))
                            .tracking(-1)
                            .lineLimit(1).minimumScaleFactor(0.65)
                        Sparkles(mirrored: true).scaleEffect(0.7).frame(width: 22)
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 20 : 7)

                    if !dynamicTypeSize.isAccessibilitySize {
                        Text("Big discoveries start small.")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(Theme.ink.opacity(0.67))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 30)
                    }

                    TimelineView(.animation(minimumInterval: 1.0 / 24,
                                            paused: reduceMotion || scenePhase != .active)) { context in
                        let elapsed = reduceMotion ? 0 : max(0, context.date.timeIntervalSince(clockStart))
                        CellLabLoadingHero(elapsed: elapsed, reducedMotion: reduceMotion)
                            .frame(width: heroSize, height: heroSize)
                    }
                    .accessibilityHidden(true)
                    .padding(.bottom, 27)

                    Text(message)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(Theme.background.opacity(0.95), in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.ink.opacity(0.1)))
                }
                .padding(.horizontal, 26).padding(.vertical, 32)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .background {
            ZStack {
                Theme.background.ignoresSafeArea()
                CellLabLoadingBackdrop().ignoresSafeArea()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("CellLab is loading")
        .accessibilityValue(message)
        .accessibilityIdentifier("celllab-loading")
    }
}

private struct CellLabLoadingHero: View {
    let elapsed: TimeInterval
    let reducedMotion: Bool
    private let colors = [Theme.structures, Theme.cycle, Theme.meiosis]

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width
            ZStack {
                halo(side: side)
                dna(side: side)
                orbit(side: side)
                companion(side: side)
            }.frame(width: side, height: side)
        }
    }

    private func halo(side: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.dna.opacity(0.5), Theme.cycle.opacity(0.2), Color.clear],
                                     center: .center, startRadius: side * 0.1, endRadius: side * 0.51))
                .frame(width: side * 1.12, height: side * 1.12)
            Circle().strokeBorder(Theme.teal.opacity(0.1), lineWidth: 1)
                .frame(width: side * 0.93, height: side * 0.93)
            Circle().trim(from: 0.04, to: 0.25)
                .stroke(Theme.teal.opacity(0.65), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: side * 0.93, height: side * 0.93)
                .rotationEffect(.degrees(elapsed * 44 - 70))
        }
    }

    private func dna(side: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Theme.ink.opacity(0.055))
                .frame(width: side * 0.55, height: side * 0.07)
                .offset(y: side * 0.36)
            Image("CellLabLoadingMascot")
                .resizable().scaledToFit()
                .frame(width: side * 1.06, height: side * 1.06)
                .offset(y: reducedMotion ? 0 : CGFloat(sin(elapsed * 1.8)) * -3)
                .rotationEffect(.degrees(reducedMotion ? 0 : sin(elapsed * 1.4) * 1.2))
        }
    }

    private func orbit(side: CGFloat) -> some View {
        ForEach(0..<3, id: \.self) { index in
            let angle = Double(index) * Double.pi * 2 / 3 + elapsed * 0.22 - Double.pi / 3
            let x = side * (0.5 + CGFloat(cos(angle)) * 0.465)
            let y = side * (0.5 + CGFloat(sin(angle)) * 0.465)
            let diameter: CGFloat = index == 1 ? 13 : 10
            ZStack {
                Circle().fill(colors[index])
                Circle().strokeBorder(Theme.ink.opacity(0.15), lineWidth: 1)
                Circle().fill(Color.white.opacity(0.75)).frame(width: 3, height: 3).offset(x: -2, y: -2)
            }
            .frame(width: diameter, height: diameter)
            .position(x: x, y: y)
        }
    }

    private func companion(side: CGFloat) -> some View {
        ZStack {
            Circle().fill(Theme.background)
            Circle().strokeBorder(Theme.ink.opacity(0.1), lineWidth: 1)
            MitosisAxolotl(fittedToArtwork: true).padding(6)
        }
        .frame(width: side * 0.3, height: side * 0.3)
        .rotationEffect(.degrees(reducedMotion ? -8 : -8 + sin(elapsed * 1.7) * 3))
        .position(x: side * 0.85, y: side * 0.78)
    }
}

private struct CellLabLoadingBackdrop: View {
    var body: some View {
        Canvas { context, size in
            for (center, radius) in [
                (CGPoint(x: -size.width * 0.12, y: size.height * 0.18), CGFloat(90)),
                (CGPoint(x: size.width * 1.08, y: size.height * 0.84), CGFloat(112))
            ] {
                let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                context.stroke(Path(ellipseIn: rect), with: .color(Theme.teal.opacity(0.07)), lineWidth: 1.5)
                context.stroke(Path(ellipseIn: rect.insetBy(dx: 9, dy: 9)), with: .color(Theme.teal.opacity(0.045)), lineWidth: 1)
                let nucleus = CGRect(x: center.x - radius * 0.25, y: center.y - radius * 0.25, width: radius * 0.5, height: radius * 0.5)
                context.fill(Path(ellipseIn: nucleus), with: .color(Theme.meiosis.opacity(0.16)))
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

#Preview("Loading · small phone") {
    CellLabLoadingView().frame(width: 375, height: 647)
}

#Preview("Loading · larger text") {
    CellLabLoadingView().environment(\.dynamicTypeSize, .accessibility3)
}
