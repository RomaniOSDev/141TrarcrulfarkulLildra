import SwiftUI

struct HeartRateMonitorView: View {
    @EnvironmentObject private var fitness: FitnessData
    let program: TrainingProgramDefinition
    let difficulty: SessionDifficulty
    @Binding var path: [TrainingDestination]

    @StateObject private var viewModel: HeartRateSessionViewModel
    @State private var showEarlyEndAlert = false

    init(program: TrainingProgramDefinition, difficulty: SessionDifficulty, path: Binding<[TrainingDestination]>) {
        self.program = program
        self.difficulty = difficulty
        _path = path
        _viewModel = StateObject(wrappedValue: HeartRateSessionViewModel(program: program, difficulty: difficulty))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Hold your zone")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Adjust the target band, stay steady, and keep the simulated pace inside the tolerance ring.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ZStack {
                    Circle()
                        .strokeBorder(Color.appTextSecondary.opacity(0.25), lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: CGFloat(zoneProgress))
                        .stroke(
                            AngularGradient(
                                colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: zoneProgress)

                    VStack(spacing: 6) {
                        Text("\(Int(viewModel.currentBPM.rounded()))")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("BPM")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .padding(20)
                .appChromePanel(style: .inset, cornerRadius: 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Target BPM")
                        .font(.headline)
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Slider(
                        value: Binding(
                            get: { viewModel.targetBPM },
                            set: { viewModel.updateTargetFromSlider($0) }
                        ),
                        in: 90...190,
                        step: 1
                    )
                    .tint(Color.appAccent)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.targetBPM)
                    Text("Goal: \(Int(viewModel.targetBPM)) BPM")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                HStack {
                    statTile(title: "Elapsed", value: formattedElapsed)
                    statTile(title: "In zone", value: formattedZone)
                }

                controls
            }
            .padding(16)
        }
        .background(Color.clear)
        .navigationTitle("Heart focus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Finish") {
                    if viewModel.elapsed < 20 {
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
        .alert("Keep going a bit longer", isPresented: $showEarlyEndAlert) {
            Button("Continue", role: .cancel) {}
            Button("End anyway") {
                completeSession()
            }
        } message: {
            Text("Sessions shorter than 20 seconds earn fewer stars.")
        }
    }

    private var zoneProgress: Double {
        guard viewModel.elapsed > 0 else { return 0 }
        return min(1.0, viewModel.timeInZone / viewModel.elapsed)
    }

    private var formattedElapsed: String {
        let seconds = Int(viewModel.elapsed.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private var formattedZone: String {
        let seconds = Int(viewModel.timeInZone.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
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
