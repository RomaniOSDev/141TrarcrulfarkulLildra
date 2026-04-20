import SwiftUI

struct TrainingDestinationHost: View {
    let destination: TrainingDestination
    @Binding var path: [TrainingDestination]

    var body: some View {
        switch destination {
        case .programDetail(let program):
            ProgramDetailView(program: program, path: $path)
        case .heartSession(let program, let difficulty):
            HeartRateMonitorView(program: program, difficulty: difficulty, path: $path)
        case .cadenceSession(let program, let difficulty):
            CadenceChaserView(program: program, difficulty: difficulty, path: $path)
        case .swimSession(let program, let difficulty):
            SwimStreamlinerView(program: program, difficulty: difficulty, path: $path)
        case .sessionResult(let outcome, let next, let prev, let wSess, let wMin, let starsB, let streakB):
            SessionResultView(
                outcome: outcome,
                nextProgram: next,
                previousSnapshot: prev,
                weeklySessionsBefore: wSess,
                weeklyMinutesBefore: wMin,
                starsBefore: starsB,
                activeDaysStreakBefore: streakB,
                path: $path
            )
        }
    }
}
