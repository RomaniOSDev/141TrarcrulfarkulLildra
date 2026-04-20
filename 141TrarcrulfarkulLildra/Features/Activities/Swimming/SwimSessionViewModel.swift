import Combine
import CoreMotion
import Foundation

@MainActor
final class SwimSessionViewModel: ObservableObject {
    enum BreathPhase: String, CaseIterable {
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale"
        case glide = "Glide"
    }

    @Published private(set) var phase: BreathPhase = .inhale
    @Published private(set) var strokesThisLap: Int = 0
    @Published private(set) var lapsCompleted: Int = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var lapEfficiencies: [Double] = []

    private let motionManager = CMMotionManager()
    private var tickTimer: AnyCancellable?
    private var breathTimer: AnyCancellable?
    private var hasStartedSession = false
    private var lastStrokeTimestamp: TimeInterval = 0

    private let lapGoal: Int
    private let strokeTarget: Int

    init(program _: TrainingProgramDefinition, difficulty: SessionDifficulty) {
        self.lapGoal = difficulty.swimLapGoal
        self.strokeTarget = difficulty.swimStrokeTarget
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        if !hasStartedSession {
            elapsed = 0
            strokesThisLap = 0
            lapsCompleted = 0
            lapEfficiencies.removeAll()
            phase = .inhale
            hasStartedSession = true
        }

        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.08
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                Task { @MainActor in
                    self.handleAcceleration(data.acceleration)
                }
            }
        }

        tickTimer = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsed += 0.25
            }

        breathTimer = Timer.publish(every: 3.8, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.advancePhase()
            }
    }

    func stop() {
        tickTimer?.cancel()
        tickTimer = nil
        breathTimer?.cancel()
        breathTimer = nil
        motionManager.stopAccelerometerUpdates()
        isRunning = false
    }

    private func advancePhase() {
        let order = BreathPhase.allCases
        if let idx = order.firstIndex(of: phase) {
            let next = order.index(after: idx)
            if next < order.endIndex {
                phase = order[next]
            } else {
                phase = order.first ?? .inhale
            }
        }
    }

    private func handleAcceleration(_ acceleration: CMAcceleration) {
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
        )
        if magnitude > 1.45, elapsed - lastStrokeTimestamp > 0.32 {
            strokesThisLap += 1
            lastStrokeTimestamp = elapsed
        }
    }

    func registerLap() {
        guard lapsCompleted < lapGoal else { return }
        let actual = max(1, strokesThisLap)
        let score = min(1.0, Double(strokeTarget) / Double(actual))
        lapEfficiencies.append(score)
        lapsCompleted += 1
        strokesThisLap = 0
        HapticFeedback.lightTap()
    }

    func makeOutcome(programId: String, previousBestScore: Double) -> SessionOutcome {
        let safeElapsed = max(1, Int(elapsed.rounded()))
        let laps = max(0, lapsCompleted)
        let ring = min(1.0, Double(laps) / Double(max(lapGoal, 1)))

        let completed = laps >= lapGoal
        let averageEfficiency = lapEfficiencies.isEmpty ? 0 : lapEfficiencies.reduce(0, +) / Double(lapEfficiencies.count)

        var stars = 0
        if completed {
            stars += 1
        }
        if completed && averageEfficiency >= 0.72 {
            stars += 1
        }

        if completed && stars == 2 {
            let candidate = OutcomeMath.performanceScore(stars: 2, ringCompletion: ring, elapsedSeconds: safeElapsed)
            if previousBestScore > 0 && candidate > previousBestScore {
                stars = 3
            } else if previousBestScore == 0 && averageEfficiency >= 0.82 {
                stars = 3
            }
        }

        let finalScore = OutcomeMath.performanceScore(stars: stars, ringCompletion: ring, elapsedSeconds: safeElapsed)
        let strokeTotal = lapEfficiencies.count * strokeTarget
        let calories = OutcomeMath.estimateCalories(activity: .swimStreamline, elapsedSeconds: safeElapsed, reps: strokeTotal)

        return SessionOutcome(
            programId: programId,
            activity: .swimStreamline,
            starsEarned: stars,
            elapsedSeconds: safeElapsed,
            repsCompleted: laps * strokeTarget,
            estimatedCalories: calories,
            ringCompletion: ring,
            milestoneUnlocked: OutcomeMath.milestoneReached(stars: stars, ringCompletion: ring),
            performanceScore: finalScore
        )
    }
}
