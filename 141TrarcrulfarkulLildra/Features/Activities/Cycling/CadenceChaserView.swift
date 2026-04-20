import SwiftUI

struct CadenceChaserView: View {
    @EnvironmentObject private var fitness: FitnessData
    let program: TrainingProgramDefinition
    let difficulty: SessionDifficulty
    @Binding var path: [TrainingDestination]

    @StateObject private var viewModel: CadenceSessionViewModel
    @State private var showEarlyEndAlert = false

    init(program: TrainingProgramDefinition, difficulty: SessionDifficulty, path: Binding<[TrainingDestination]>) {
        self.program = program
        self.difficulty = difficulty
        _path = path
        _viewModel = StateObject(wrappedValue: CadenceSessionViewModel(program: program, difficulty: difficulty))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Match the rhythm")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Hold your device steady on the bike frame area. Peaks estimate cadence; haptics confirm a steady lock.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                AnimatedCircleView(progress: cadenceMatchProgress)
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .appChromePanel(style: .inset, cornerRadius: 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Target cadence")
                        .font(.headline)
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("\(Int(viewModel.targetRPM.rounded())) RPM")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Live estimate: \(Int(viewModel.estimatedRPM.rounded())) RPM")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                HStack {
                    statTile(title: "Elapsed", value: formattedElapsed)
                    statTile(title: "Locked", value: formattedLocked)
                }

                controls
            }
            .padding(16)
        }
        .background(Color.clear)
        .navigationTitle("Cadence focus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Finish") {
                    if viewModel.elapsed < 25 {
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
        .alert("Keep pedaling", isPresented: $showEarlyEndAlert) {
            Button("Continue", role: .cancel) {}
            Button("End anyway") {
                completeSession()
            }
        } message: {
            Text("Sessions shorter than 25 seconds earn fewer stars.")
        }
    }

    private var cadenceMatchProgress: Double {
        let delta = abs(viewModel.estimatedRPM - viewModel.targetRPM)
        let closeness = max(0, 1.0 - delta / 25.0)
        return min(1.0, closeness * 0.85 + min(1.0, viewModel.lockedDuration / max(viewModel.elapsed, 1)) * 0.15)
    }

    private var formattedElapsed: String {
        let seconds = Int(viewModel.elapsed.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private var formattedLocked: String {
        let seconds = Int(viewModel.lockedDuration.rounded())
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
