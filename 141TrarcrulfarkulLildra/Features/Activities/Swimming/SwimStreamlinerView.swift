import SwiftUI

struct SwimStreamlinerView: View {
    @EnvironmentObject private var fitness: FitnessData
    let program: TrainingProgramDefinition
    let difficulty: SessionDifficulty
    @Binding var path: [TrainingDestination]

    @StateObject private var viewModel: SwimSessionViewModel
    @State private var showEarlyEndAlert = false

    init(program: TrainingProgramDefinition, difficulty: SessionDifficulty, path: Binding<[TrainingDestination]>) {
        self.program = program
        self.difficulty = difficulty
        _path = path
        _viewModel = StateObject(wrappedValue: SwimSessionViewModel(program: program, difficulty: difficulty))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Rhythm and glide")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Follow the breathing ladder, keep strokes smooth, and mark each lap when you finish the length.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                breathingCard

                efficiencyPie

                HStack {
                    statTile(title: "Laps", value: "\(viewModel.lapsCompleted)/\(difficulty.swimLapGoal)")
                    statTile(title: "Strokes (lap)", value: "\(viewModel.strokesThisLap)")
                }

                Button {
                    viewModel.registerLap()
                } label: {
                    Text("Mark lap complete")
                        .font(.headline)
                        .foregroundStyle(Color.appTextOnPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .appPrimaryButtonChrome(enabled: viewModel.lapsCompleted < difficulty.swimLapGoal)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.lapsCompleted >= difficulty.swimLapGoal)

                controls
            }
            .padding(16)
        }
        .background(Color.clear)
        .navigationTitle("Swim focus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Finish") {
                    if viewModel.lapsCompleted < difficulty.swimLapGoal {
                        showEarlyEndAlert = true
                    } else {
                        completeSession()
                    }
                }
                .frame(minHeight: 44)
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .alert("Finish early?", isPresented: $showEarlyEndAlert) {
            Button("Keep swimming", role: .cancel) {}
            Button("End session") {
                completeSession()
            }
        } message: {
            Text("Ending before the lap goal reduces stars.")
        }
    }

    private var breathingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Breathing phase")
                .font(.headline)
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(viewModel.phase.rawValue)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Intervals shift every few seconds to keep exchanges calm and steady.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appChromePanel(style: .elevated, cornerRadius: 20)
    }

    private var efficiencyPie: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Efficiency snapshot")
                .font(.headline)
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 12
                let base = Path { path in
                    path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                }
                context.fill(base, with: .color(Color.appTextSecondary.opacity(0.15)))

                let slice = min(1.0, max(0.0, efficiencyValue))
                var pie = Path()
                pie.move(to: center)
                pie.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + slice * 360),
                    clockwise: false
                )
                pie.closeSubpath()
                context.fill(
                    pie,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.appAccent.opacity(0.95),
                            Color.appPrimary.opacity(0.75),
                        ]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )
            }
            .frame(height: 200)

            Text("Target strokes per lap: \(difficulty.swimStrokeTarget)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .appChromePanel(style: .inset, cornerRadius: 20)
    }

    private var efficiencyValue: Double {
        guard !viewModel.lapEfficiencies.isEmpty else { return 0 }
        return viewModel.lapEfficiencies.reduce(0, +) / Double(viewModel.lapEfficiencies.count)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(viewModel.isRunning ? "Pause" : "Resume") {
                if viewModel.isRunning {
                    viewModel.stop()
                } else {
                    viewModel.start()
                }
            }
            .font(.headline)
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .appSecondaryOutlineChrome()
        }
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appChromePanel(style: .inset, cornerRadius: 16)
    }

    private func completeSession() {
        viewModel.stop()
        let previous = fitness.bestTimes[program.id] ?? 0
        let outcome = viewModel.makeOutcome(programId: program.id, previousBestScore: previous)
        let pre = fitness.capturePreSessionMetrics(for: program.id)
        fitness.recordSessionOutcome(outcome)
        if !path.isEmpty {
            path.removeLast()
        }
        let next = fitness.nextProgram(after: program.id)
        path.append(
            .sessionResult(
                outcome,
                nextProgram: next,
                previousSnapshot: pre.snapshot,
                weeklySessionsBefore: pre.weeklySessionsCompleted,
                weeklyMinutesBefore: pre.weeklyActiveMinutes,
                starsBefore: pre.stars,
                activeDaysStreakBefore: pre.activeDaysStreak
            )
        )
    }
}
