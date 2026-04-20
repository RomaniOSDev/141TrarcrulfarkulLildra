import Foundation

enum OutcomeMath {
    static func performanceScore(stars: Int, ringCompletion: Double, elapsedSeconds: Int) -> Double {
        Double(stars) * 38 + ringCompletion * 42 + min(1.0, Double(elapsedSeconds) / 150.0) * 20
    }

    static func milestoneReached(stars: Int, ringCompletion: Double) -> Bool {
        stars == 3 || ringCompletion >= 0.92
    }

    static func estimateCalories(activity: ActivityKind, elapsedSeconds: Int, reps: Int) -> Int {
        let base = Double(elapsedSeconds) * 0.12
        let bonus = Double(reps) * 0.35
        let factor: Double
        switch activity {
        case .heartRateZone: factor = 1.05
        case .cadenceRhythm: factor = 1.15
        case .swimStreamline: factor = 1.25
        }
        return max(6, Int((base + bonus) * factor))
    }
}
