import Combine
import CoreMotion
import Foundation

@MainActor
final class CadenceSessionViewModel: ObservableObject {
    @Published private(set) var targetRPM: Double
    @Published private(set) var estimatedRPM: Double = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var lockedDuration: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var lockProgress: Double = 0

    private let motionManager = CMMotionManager()
    private var ticker: AnyCancellable?
    private var hasStartedSession = false

    private var lastMagnitude: Double = 1.0
    private var lastPeakTime: TimeInterval = 0
    private var peakCountWindow: [TimeInterval] = []

    init(program: TrainingProgramDefinition, difficulty: SessionDifficulty) {
        let base = Double(program.baseCadenceTarget + difficulty.cadenceTargetOffset)
        self.targetRPM = min(120, max(55, base))
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        if !hasStartedSession {
            elapsed = 0
            lockedDuration = 0
            peakCountWindow.removeAll()
            hasStartedSession = true
        }

        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.05
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                Task { @MainActor in
                    self.handleAcceleration(data.acceleration)
                }
            }
        }

        ticker = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        motionManager.stopAccelerometerUpdates()
        isRunning = false
    }

    private func handleAcceleration(_ acceleration: CMAcceleration) {
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
        )

        let now = elapsed
        if magnitude > 1.18, lastMagnitude <= 1.08, now - lastPeakTime > 0.18 {
            peakCountWindow.append(now)
            lastPeakTime = now
        }
        lastMagnitude = magnitude

        peakCountWindow.removeAll { now - $0 > 4.0 }
        if peakCountWindow.count >= 2 {
            let rate = Double(peakCountWindow.count - 1) / 4.0 * 60.0
            estimatedRPM = min(140, max(40, rate * 1.35))
        } else {
            estimatedRPM = max(40, estimatedRPM * 0.96)
        }
    }

    private func tick() {
        elapsed += 0.2

        if abs(estimatedRPM - targetRPM) <= 10 {
            lockedDuration += 0.2
            lockProgress = min(1.0, lockProgress + 0.08)
            if lockProgress >= 1.0 {
                lockProgress = 0
                HapticFeedback.successPulse()
            }
        } else {
            lockProgress = max(0, lockProgress - 0.12)
        }
    }

    func makeOutcome(programId: String, previousBestScore: Double) -> SessionOutcome {
        let safeElapsed = max(1, Int(elapsed.rounded()))
        let lockRatio = min(1.0, lockedDuration / max(elapsed, 0.0001))
        let ring = min(1.0, max(0.0, lockRatio))

        let completed = elapsed >= 25

        var stars = 0
        if completed {
            stars += 1
        }
        if completed && lockRatio >= 0.55 {
            stars += 1
        }

        if completed && stars == 2 {
            let candidate = OutcomeMath.performanceScore(stars: 2, ringCompletion: ring, elapsedSeconds: safeElapsed)
            if previousBestScore > 0 && candidate > previousBestScore {
                stars = 3
            } else if previousBestScore == 0 && lockRatio >= 0.72 {
                stars = 3
            }
        }

        let finalScore = OutcomeMath.performanceScore(stars: stars, ringCompletion: ring, elapsedSeconds: safeElapsed)
        let reps = Int((lockedDuration * 2).rounded())
        let calories = OutcomeMath.estimateCalories(activity: .cadenceRhythm, elapsedSeconds: safeElapsed, reps: reps)

        return SessionOutcome(
            programId: programId,
            activity: .cadenceRhythm,
            starsEarned: stars,
            elapsedSeconds: safeElapsed,
            repsCompleted: reps,
            estimatedCalories: calories,
            ringCompletion: ring,
            milestoneUnlocked: OutcomeMath.milestoneReached(stars: stars, ringCompletion: ring),
            performanceScore: finalScore
        )
    }
}
