import Combine
import Foundation

@MainActor
final class HeartRateSessionViewModel: ObservableObject {
    @Published var targetBPM: Double
    @Published private(set) var currentBPM: Double
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var timeInZone: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var steadyIntervals: Int = 0

    private let difficulty: SessionDifficulty
    private var ticker: AnyCancellable?
    private var hasStartedSession = false

    init(program: TrainingProgramDefinition, difficulty: SessionDifficulty) {
        self.difficulty = difficulty
        self.targetBPM = Double(program.baseHeartRateTarget)
        self.currentBPM = Double(program.baseHeartRateTarget - 18)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        if !hasStartedSession {
            elapsed = 0
            timeInZone = 0
            steadyIntervals = 0
            hasStartedSession = true
        }

        ticker = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        isRunning = false
    }

    func updateTargetFromSlider(_ value: Double) {
        targetBPM = min(190, max(90, value))
    }

    private func tick() {
        elapsed += 0.25

        let error = targetBPM - currentBPM
        currentBPM += error * 0.12 + Double.random(in: -2.8 ... 2.8)
        currentBPM = min(198, max(55, currentBPM))

        let tolerance = difficulty.heartRateTolerance
        if abs(currentBPM - targetBPM) <= tolerance {
            timeInZone += 0.25
            steadyIntervals += 1
        }
    }

    func makeOutcome(programId: String, previousBestScore: Double) -> SessionOutcome {
        let safeElapsed = max(1, Int(elapsed.rounded()))
        let zoneRatio = min(1.0, timeInZone / elapsed)
        let ring = min(1.0, max(0.0, zoneRatio))

        let completed = elapsed >= 20

        var stars = 0
        if completed {
            stars += 1
        }
        if completed && zoneRatio >= 0.68 {
            stars += 1
        }

        if completed && stars == 2 {
            let candidate = OutcomeMath.performanceScore(stars: 2, ringCompletion: ring, elapsedSeconds: safeElapsed)
            if previousBestScore > 0 && candidate > previousBestScore {
                stars = 3
            } else if previousBestScore == 0 && zoneRatio >= 0.85 {
                stars = 3
            }
        }

        let finalScore = OutcomeMath.performanceScore(stars: stars, ringCompletion: ring, elapsedSeconds: safeElapsed)
        let calories = OutcomeMath.estimateCalories(activity: .heartRateZone, elapsedSeconds: safeElapsed, reps: steadyIntervals / 4)

        return SessionOutcome(
            programId: programId,
            activity: .heartRateZone,
            starsEarned: stars,
            elapsedSeconds: safeElapsed,
            repsCompleted: steadyIntervals / 4,
            estimatedCalories: calories,
            ringCompletion: ring,
            milestoneUnlocked: OutcomeMath.milestoneReached(stars: stars, ringCompletion: ring),
            performanceScore: finalScore
        )
    }
}
