import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var fitness: FitnessData
    @State private var currentPage = 0

    private let stepFootnotes = [
        "Consistency beats intensity when the days add up.",
        "Train the engine, not only the highlight reel.",
        "Smooth breathing wins noisy effort — you are ready to begin.",
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(OnboardingStep.allCases) { step in
                    OnboardingStepPage(
                        step: step,
                        onStart: {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                fitness.completeOnboarding()
                            }
                        }
                    )
                    .tag(step.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(
                .page(backgroundDisplayMode: .always)
            )
            .tint(Color.appAccent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            footnoteStrip
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 20)
        }
        .background { AppMeshBackground() }
    }

    private var footnoteStrip: some View {
        Text(stepFootnotes[min(currentPage, stepFootnotes.count - 1)])
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.appPrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            .appChromePanel(style: .outlined, cornerRadius: 18)
    }
}

// MARK: - Steps

private enum OnboardingStep: Int, CaseIterable, Identifiable {
    case run = 0
    case cycle = 1
    case swim = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .run: return "Run with rhythm"
        case .cycle: return "Cycle with control"
        case .swim: return "Swim with precision"
        }
    }

    var subtitle: String {
        switch self {
        case .run: return "Build aerobic power that lasts — steady zones, calm breath, repeatable sessions."
        case .cycle: return "Cadence keeps joints calm and speed honest. Lock the rhythm, own the road."
        case .swim: return "Calm patterns create efficient laps. Glide, breathe, repeat."
        }
    }

    var sportLabel: String {
        switch self {
        case .run: return "Running"
        case .cycle: return "Cycling"
        case .swim: return "Swimming"
        }
    }

    var iconName: String {
        switch self {
        case .run: return "figure.run"
        case .cycle: return "bicycle"
        case .swim: return "figure.pool.swim"
        }
    }
}

// MARK: - Page

private struct OnboardingStepPage: View {
    let step: OnboardingStep
    let onStart: () -> Void

    @State private var pulseCTA = false

    private var isLast: Bool { step == .swim }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                stepHeader

                illustrationStage

                copyCard

                if isLast {
                    startButton
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 36)
        }
        .background(Color.clear)
    }

    private var stepHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: step.iconName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary.opacity(0.18), Color.appAccent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.28), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(step.sportLabel.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(Color.appTextSecondary)
                Text("Step \(step.rawValue + 1) of 3")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
            }
            Spacer(minLength: 0)
        }
    }

    private var illustrationStage: some View {
        Group {
            switch step {
            case .run:
                RunnerIllustration()
            case .cycle:
                CyclistIllustration()
            case .swim:
                SwimmerIllustration()
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface.opacity(0.95),
                                Color.appPrimary.opacity(0.06),
                                Color.appAccent.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.35), Color.appPrimary.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.appTextSecondary.opacity(0.12), radius: 18, x: 0, y: 10)
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    private var copyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(step.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(step.subtitle)
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .appChromePanel(style: .elevated, cornerRadius: 22)
    }

    private var startButton: some View {
        Button(action: onStart) {
            Text("Get Started")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .appPrimaryButtonChrome()
                .scaleEffect(pulseCTA ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true), value: pulseCTA)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
        .onAppear { pulseCTA = true }
    }
}

// MARK: - Illustrations

private struct RunnerIllustration: View {
    var body: some View {
        Canvas { context, size in
            let stridePath = Path { path in
                path.move(to: CGPoint(x: 20, y: size.height - 20))
                path.addQuadCurve(
                    to: CGPoint(x: size.width - 20, y: 40),
                    control: CGPoint(x: size.width * 0.45, y: size.height * 0.85)
                )
            }
            context.stroke(
                stridePath,
                with: .linearGradient(
                    Gradient(colors: [Color.appAccent, Color.appPrimary.opacity(0.85)]),
                    startPoint: CGPoint(x: 0, y: size.height),
                    endPoint: CGPoint(x: size.width, y: 0)
                ),
                lineWidth: 6
            )

            let torso = Path(ellipseIn: CGRect(x: size.width * 0.42, y: 40, width: 26, height: 70))
            context.fill(torso, with: .color(Color.appPrimary))

            let head = Path(ellipseIn: CGRect(x: size.width * 0.44, y: 18, width: 34, height: 34))
            context.fill(head, with: .color(Color.appAccent.opacity(0.85)))

            let leg = Path { path in
                path.move(to: CGPoint(x: size.width * 0.52, y: 110))
                path.addLine(to: CGPoint(x: size.width * 0.62, y: size.height - 30))
            }
            context.stroke(leg, with: .color(Color.appPrimary.opacity(0.8)), lineWidth: 8)
        }
    }
}

private struct CyclistIllustration: View {
    var body: some View {
        Canvas { context, size in
            let wheel1 = Path(ellipseIn: CGRect(x: 30, y: size.height - 90, width: 80, height: 80))
            let wheel2 = Path(ellipseIn: CGRect(x: size.width - 110, y: size.height - 90, width: 80, height: 80))
            context.stroke(wheel1, with: .color(Color.appPrimary), lineWidth: 5)
            context.stroke(wheel2, with: .color(Color.appPrimary), lineWidth: 5)

            let frame = Path { path in
                path.move(to: CGPoint(x: 70, y: size.height - 50))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: 70))
                path.addLine(to: CGPoint(x: size.width - 70, y: size.height - 50))
            }
            context.stroke(
                frame,
                with: .linearGradient(
                    Gradient(colors: [Color.appAccent, Color.appPrimary.opacity(0.9)]),
                    startPoint: CGPoint(x: 0, y: size.height),
                    endPoint: CGPoint(x: size.width, y: 0)
                ),
                lineWidth: 6
            )

            let body = Path(roundedRect: CGRect(x: size.width * 0.46, y: 40, width: 22, height: 60), cornerRadius: 10)
            context.fill(body, with: .color(Color.appPrimary.opacity(0.9)))
        }
    }
}

private struct SwimmerIllustration: View {
    var body: some View {
        Canvas { context, size in
            let wave = Path { path in
                path.move(to: CGPoint(x: 0, y: size.height * 0.55))
                for x in stride(from: 0, through: size.width, by: 26) {
                    path.addQuadCurve(
                        to: CGPoint(x: x + 13, y: size.height * 0.55),
                        control: CGPoint(x: x + 6, y: size.height * 0.45)
                    )
                }
            }
            context.stroke(
                wave,
                with: .linearGradient(
                    Gradient(colors: [Color.appAccent.opacity(0.9), Color.appPrimary.opacity(0.7)]),
                    startPoint: CGPoint(x: 0, y: size.height * 0.55),
                    endPoint: CGPoint(x: size.width, y: size.height * 0.55)
                ),
                lineWidth: 4
            )

            let arm = Path { path in
                path.move(to: CGPoint(x: size.width * 0.3, y: size.height * 0.42))
                path.addQuadCurve(
                    to: CGPoint(x: size.width * 0.72, y: size.height * 0.38),
                    control: CGPoint(x: size.width * 0.52, y: size.height * 0.2)
                )
            }
            context.stroke(arm, with: .color(Color.appPrimary), lineWidth: 7)

            let capsule = Path(roundedRect: CGRect(x: size.width * 0.4, y: size.height * 0.36, width: 90, height: 28), cornerRadius: 14)
            context.fill(capsule, with: .color(Color.appPrimary.opacity(0.85)))
        }
    }
}
