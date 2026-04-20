import SwiftUI

struct SessionResultView: View {
    @EnvironmentObject private var tabRouter: TabRouter
    @EnvironmentObject private var fitness: FitnessData

    let outcome: SessionOutcome
    let nextProgram: TrainingProgramDefinition?
    let previousSnapshot: SessionSnapshot?
    let weeklySessionsBefore: Int
    let weeklyMinutesBefore: Int
    let starsBefore: Int
    let activeDaysStreakBefore: Int
    @Binding var path: [TrainingDestination]

    @State private var animatedStars = 0
    @State private var pulseStats = false
    @State private var showBanner = false

    private var weeklySessionGoalMet: Bool {
        fitness.weeklySessionGoalJustCompleted(beforeCount: weeklySessionsBefore)
    }

    private var weeklyMinutesGoalMet: Bool {
        fitness.weeklyMinutesGoalJustCompleted(beforeMinutes: weeklyMinutesBefore)
    }

    private var fullStarsFirstTime: Bool {
        outcome.starsEarned >= 3 && starsBefore < 3
    }

    private var sevenDayTrainingBanner: Bool {
        activeDaysStreakBefore < 7 && fitness.activeDaysStreak >= 7
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                milestoneStack
                    .padding(.horizontal, 16)

                Text("Session complete")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 8)

                if let previousSnapshot {
                    comparisonCard(previous: previousSnapshot)
                        .padding(.horizontal, 16)
                }

                ZStack {
                    ringsCanvas
                        .frame(height: 200)

                    VStack(spacing: 6) {
                        Text("Stars earned")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        StarRowView(filled: animatedStars, animate: true)
                    }
                }
                .padding(20)
                .appChromePanel(style: .inset, cornerRadius: 22)

                VStack(spacing: 12) {
                    statBlock(title: "Time", value: formattedTime)
                    statBlock(title: "Reps", value: "\(outcome.repsCompleted)")
                    statBlock(title: "Estimated calories", value: "\(outcome.estimatedCalories) kcal")
                }
                .padding(.horizontal, 16)
                .animation(.spring(response: 0.55, dampingFraction: 0.78), value: pulseStats)

                VStack(spacing: 12) {
                    if let nextProgram {
                        Button {
                            path.removeAll()
                            path.append(.programDetail(nextProgram))
                        } label: {
                            Text("Next session")
                                .font(.headline)
                                .foregroundStyle(Color.appTextPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 48)
                                .appPrimaryButtonChrome()
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            path.removeAll()
                        } label: {
                            Text("Back to plans")
                                .font(.headline)
                                .foregroundStyle(Color.appTextPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 48)
                                .appPrimaryButtonChrome()
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        path.removeAll()
                        tabRouter.selection = .progress
                    } label: {
                        Text("View progress")
                            .font(.headline)
                            .foregroundStyle(Color.appPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                            .appSecondaryOutlineChrome()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color.clear)
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            pulseStats.toggle()
            animateStarsSequence()
            if outcome.milestoneUnlocked || weeklySessionGoalMet || weeklyMinutesGoalMet || fullStarsFirstTime || sevenDayTrainingBanner {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.2)) {
                    showBanner = true
                }
            }
        }
    }

    @ViewBuilder
    private var milestoneStack: some View {
        VStack(spacing: 12) {
            if showBanner && outcome.milestoneUnlocked {
                AchievementBanner(
                    title: "Milestone reached",
                    subtitle: "Outstanding control during this session. Keep the streak alive."
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            if showBanner && weeklySessionGoalMet {
                AchievementBanner(
                    title: "Weekly session goal",
                    subtitle: "You hit your session target for this week."
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            if showBanner && weeklyMinutesGoalMet {
                AchievementBanner(
                    title: "Weekly time goal",
                    subtitle: "You reached your active minutes target for the week."
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            if showBanner && fullStarsFirstTime {
                AchievementBanner(
                    title: "Full score",
                    subtitle: "Three stars on this plan. Excellent consistency and focus."
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            if showBanner && sevenDayTrainingBanner {
                AchievementBanner(
                    title: "Seven-day rhythm",
                    subtitle: "A full week of training days in a row."
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func comparisonCard(previous: SessionSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compared to last time")
                .font(.headline)
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            comparisonRow(
                label: "Time",
                delta: formatDeltaSeconds(outcome.elapsedSeconds - previous.elapsedSeconds),
                improved: outcome.elapsedSeconds >= previous.elapsedSeconds
            )
            comparisonRow(
                label: "Stars",
                delta: formatStarDelta(outcome.starsEarned - previous.starsEarned),
                improved: outcome.starsEarned >= previous.starsEarned
            )
            comparisonRow(
                label: "Ring focus",
                delta: formatRingDelta(outcome.ringCompletion - previous.ringCompletion),
                improved: outcome.ringCompletion >= previous.ringCompletion
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .elevated, cornerRadius: 18)
    }

    private func comparisonRow(label: String, delta: String, improved: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Text(delta)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(improved ? Color.appAccent : Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func formatDeltaSeconds(_ delta: Int) -> String {
        if delta == 0 { return "Same" }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(delta)s"
    }

    private func formatStarDelta(_ delta: Int) -> String {
        if delta == 0 { return "Same" }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(delta)"
    }

    private func formatRingDelta(_ delta: Double) -> String {
        if abs(delta) < 0.005 { return "Same" }
        let sign = delta > 0 ? "+" : ""
        return String(format: "%@%.0f%%", sign, delta * 100)
    }

    private var formattedTime: String {
        let m = outcome.elapsedSeconds / 60
        let s = outcome.elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private var ringsCanvas: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2 - 10
            let rings: [(CGFloat, Double)] = [
                (maxRadius, min(1.0, Double(outcome.elapsedSeconds) / 180.0)),
                (maxRadius - 22, min(1.0, Double(outcome.repsCompleted) / 200.0)),
                (maxRadius - 44, outcome.ringCompletion)
            ]

            for (radius, progress) in rings {
                let base = Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270),
                        clockwise: false
                    )
                }
                context.stroke(base, with: .color(Color.appTextSecondary.opacity(0.25)), lineWidth: 10)

                var progressPath = Path()
                progressPath.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * progress),
                    clockwise: false
                )
                context.stroke(progressPath, with: .color(Color.appAccent.opacity(0.95)), lineWidth: 10)
            }
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .appChromePanel(style: .inset, cornerRadius: 16)
    }

    private func animateStarsSequence() {
        animatedStars = 0
        for index in 0..<min(outcome.starsEarned, 3) {
            let step = index + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.12) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                    animatedStars = step
                }
            }
        }
    }
}
